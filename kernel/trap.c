// 陷阱处理模块：处理中断、异常和系统调用
// 在xv6中，陷阱是在CPU执行指令时发生的意外事件，需要内核处理
// 包括：设备中断、异常和系统调用

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

// 时钟中断的自旋锁和计数器
struct spinlock tickslock;
uint ticks;

// trampoline代码的起始和用户异常向量的位置（在kernelvec.S中定义）
extern char trampoline[], uservec[], userret[];

// 在kernelvec.S中定义，用于调用kerneltrap()
void kernelvec();

extern int devintr();

// 初始化陷阱处理系统
// 初始化时钟中断的锁
void
trapinit(void)
{
  // 初始化时钟锁
  initlock(&tickslock, "time");
}

// 为内核中的异常和陷阱设置处理程序
// 为每个硬件线程初始化陷阱处理
void
trapinithart(void)
{
  // 设置stvec寄存器，指向内核异常处理程序kernelvec
  // stvec用于存储异常处理程序的起始地址
  w_stvec((uint64)kernelvec);
}

// 处理来自用户空间的中断、异常或系统调用
// 该函数由trampoline.S调用
// 参数：无
// 返回值：无
void
usertrap(void)
{
  int which_dev = 0;

  // 检查陷阱是否来自用户模式
  if((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // 将中断和异常转发到kerneltrap()，因为现在在内核模式
  w_stvec((uint64)kernelvec);

  // 获取当前进程
  struct proc *p = myproc();
  
  // 保存用户程序计数器
  p->trapframe->epc = r_sepc();
  
  // 处理不同类型的陷阱
  if(r_scause() == 8){
    // 系统调用：scause值为8表示ecall指令

    // 检查进程是否被标记为killed
    if(p->killed)
      exit(-1);

    // sepc指向ecall指令，但我们要返回下一条指令
    // 将epc加4跳过ecall指令（RISC-V中指令长度为4字节）
    p->trapframe->epc += 4;

    // 中断会改变sstatus等寄存器，完成寄存器操作后再启用中断
    intr_on();

    // 处理系统调用
    syscall();
  } else if((which_dev = devintr()) != 0){
    // 处理设备中断
  } else {
    // 未知的陷阱类型
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    // 标记进程为已杀死状态
    p->killed = 1;
  }

  // 再次检查进程是否被杀死
  if(p->killed)
    exit(-1);

  // 如果是定时器中断（which_dev == 2），放弃CPU以允许其他进程运行
  if(which_dev == 2)
    yield();

  // 返回到用户空间
  usertrapret();
}

// 返回到用户空间
// 此函数恢复用户进程的执行状态并返回用户模式
void
usertrapret(void)
{
  struct proc *p = myproc();

  // 在从kerneltrap()切换陷阱目的地到usertrap()之前，禁用中断
  // 直到回到用户空间，usertrap()才能正确处理陷阱
  intr_off();

  // 将系统调用、中断和异常转发到trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));

  // 设置trapframe中的值，uservec在进程重新进入内核时需要这些值
  p->trapframe->kernel_satp = r_satp();         // 内核页表
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
  p->trapframe->kernel_trap = (uint64)usertrap; // 内核异常处理程序
  p->trapframe->kernel_hartid = r_tp();         // 硬件线程ID

  // 设置trampoline.S中sret指令使用的寄存器以进入用户空间
  
  // 设置S特权级模式为用户模式
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 清除SPP位为0表示用户模式
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
  w_sstatus(x);

  // 设置S异常程序计数器为保存的用户PC
  w_sepc(p->trapframe->epc);

  // 告诉trampoline.S要切换到的用户页表
  uint64 satp = MAKE_SATP(p->pagetable);

  // 跳转到内存顶部的trampoline.S代码
  // trampoline.S会：
  // 1. 切换到用户页表
  // 2. 恢复用户寄存器
  // 3. 使用sret指令切换到用户模式
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
}

// 处理来自内核代码的中断和异常
// 通过kernelvec调用此函数，在当前内核栈上执行
// 用于处理内核模式下发生的陷阱
void 
kerneltrap()
{
  int which_dev = 0;
  // 保存陷阱时的寄存器状态，以便后续恢复
  uint64 sepc = r_sepc();     // 保存异常程序计数器
  uint64 sstatus = r_sstatus(); // 保存状态寄存器
  uint64 scause = r_scause();   // 保存陷阱原因
  
  // 验证陷阱确实来自内核（supervisor mode）
  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  // 检查中断是否已启用，应该在内核陷阱时禁用
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  // 处理设备中断
  if((which_dev = devintr()) == 0){
    // 如果不是设备中断，则是未预期的异常
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // 如果是定时器中断（which_dev == 2），给其他进程运行的机会
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();

  // yield()可能导致其他陷阱发生，因此恢复陷阱寄存器
  // 这些值将由kernelvec.S中的sret指令使用
  w_sepc(sepc);
  w_sstatus(sstatus);
}

// 处理时钟中断
// 定时器中断会调用此函数来递增时钟计数器
void
clockintr()
{
  // 获取时钟锁以确保原子性
  acquire(&tickslock);
  // 递增系统时滴数
  ticks++;
  // 唤醒在ticks上睡眠的所有进程
  wakeup(&ticks);
  // 释放时钟锁
  release(&tickslock);
}

// 检查是否是外部中断或软件中断，并进行处理
// 返回值: 2 = 定时器中断
//        1 = 其他设备中断  
//        0 = 未识别的中断
int
devintr()
{
  // 读取陷阱原因寄存器
  uint64 scause = r_scause();

  // 检查是否是外部中断（最高位为1表示中断，而非异常）
  // scause & 0xff == 9 表示来自PLIC的supervisor外部中断
  if((scause & 0x8000000000000000L) &&
     (scause & 0xff) == 9){
    // 这是来自PLIC的supervisor外部中断

    // irq标示被中断的设备
    int irq = plic_claim();

    // 根据中断号调用相应的设备中断处理程序
    if(irq == UART0_IRQ){
      // 处理UART中断（串口通信）
      uartintr();
    } else if(irq == VIRTIO0_IRQ){
      // 处理VIRTIO磁盘中断
      virtio_disk_intr();
    } else if(irq){
      // 未知中断
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // PLIC一次只允许每个设备产生一个中断
    // 告诉PLIC该设备现在可以再次中断
    if(irq)
      plic_complete(irq);

    // 返回1表示处理了其他设备中断
    return 1;
  } else if(scause == 0x8000000000000001L){
    // 软件中断来自machine-mode定时器中断
    // 由kernelvec.S中的timervec转发

    // 只在CPU 0上处理时钟中断
    if(cpuid() == 0){
      clockintr();
    }
    
    // 通过清除sip寄存器中的SSIP位来确认软件中断
    w_sip(r_sip() & ~2);

    // 返回2表示处理了定时器中断
    return 2;
  } else {
    // 返回0表示未识别的中断类型
    return 0;
  }
}

