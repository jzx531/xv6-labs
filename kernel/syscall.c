// 系统调用模块：处理用户程序发起的系统调用请求
// 在xv6中，用户程序通过ecall指令进入内核，内核根据系统调用号
// 调用相应的处理函数，并返回结果给用户程序

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "defs.h"

// 从当前进程的用户空间获取addr地址处的uint64值
// 返回0表示成功，-1表示失败
int
fetchaddr(uint64 addr, uint64 *ip)
{
  struct proc *p = myproc();
  // 检查地址是否在进程的地址空间内
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    return -1;
  // 从用户页表复制数据到内核空间
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    return -1;
  return 0;
}

// 从当前进程的用户空间获取addr地址处的以null结尾的字符串
// 返回字符串长度（不包括null），或-1表示错误
int
fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  // 从用户页表复制字符串到内核缓冲区
  int err = copyinstr(p->pagetable, buf, addr, max);
  if(err < 0)
    return err;
  // 返回字符串长度
  return strlen(buf);
}

// 获取第n个原始系统调用参数（64位值）
// 参数n从0开始，对应RISC-V的a0-a5寄存器
static uint64
argraw(int n)
{
  struct proc *p = myproc();
  // 根据参数索引返回对应的寄存器值
  switch (n) {
  case 0:
    return p->trapframe->a0;
  case 1:
    return p->trapframe->a1;
  case 2:
    return p->trapframe->a2;
  case 3:
    return p->trapframe->a3;
  case 4:
    return p->trapframe->a4;
  case 5:
    return p->trapframe->a5;
  }
  // 无效的参数索引
  panic("argraw");
  return -1;
}

// 获取第n个32位系统调用参数
// 将参数存储到ip指向的整数中
int
argint(int n, int *ip)
{
  *ip = argraw(n);
  return 0;
}

// 获取第n个指针类型的系统调用参数
// 不检查合法性，因为copyin/copyout会进行检查
int
argaddr(int n, uint64 *ip)
{
  *ip = argraw(n);
  return 0;
}

// 获取第n个字符串类型的系统调用参数
// 将字符串复制到buf中，最多max个字符
// 返回字符串长度（包括null）或-1表示错误
int
argstr(int n, char *buf, int max)
{
  uint64 addr;
  // 先获取字符串地址
  if(argaddr(n, &addr) < 0)
    return -1;
  // 然后获取字符串内容
  return fetchstr(addr, buf, max);
}

// 系统调用函数的外部声明
// 这些函数在其他文件中实现，处理具体的系统调用逻辑
extern uint64 sys_chdir(void);
extern uint64 sys_close(void);
extern uint64 sys_dup(void);
extern uint64 sys_exec(void);
extern uint64 sys_exit(void);
extern uint64 sys_fork(void);
extern uint64 sys_fstat(void);
extern uint64 sys_getpid(void);
extern uint64 sys_kill(void);
extern uint64 sys_link(void);
extern uint64 sys_mkdir(void);
extern uint64 sys_mknod(void);
extern uint64 sys_open(void);
extern uint64 sys_pipe(void);
extern uint64 sys_read(void);
extern uint64 sys_sbrk(void);
extern uint64 sys_sleep(void);
extern uint64 sys_unlink(void);
extern uint64 sys_wait(void);
extern uint64 sys_write(void);
extern uint64 sys_uptime(void);

// 系统调用表：根据系统调用号索引到对应的处理函数
// 数组索引对应SYS_*常量定义的系统调用号
static uint64 (*syscalls[])(void) = {
[SYS_fork]    sys_fork,    // 创建新进程
[SYS_exit]    sys_exit,    // 退出进程
[SYS_wait]    sys_wait,    // 等待子进程结束
[SYS_pipe]    sys_pipe,    // 创建管道
[SYS_read]    sys_read,    // 从文件读取数据
[SYS_kill]    sys_kill,    // 发送信号给进程
[SYS_exec]    sys_exec,    // 执行新程序
[SYS_fstat]   sys_fstat,   // 获取文件状态
[SYS_chdir]   sys_chdir,   // 改变当前工作目录
[SYS_dup]     sys_dup,     // 复制文件描述符
[SYS_getpid]  sys_getpid,  // 获取进程ID
[SYS_sbrk]    sys_sbrk,    // 改变进程内存大小
[SYS_sleep]   sys_sleep,   // 让进程睡眠
[SYS_uptime]  sys_uptime,  // 获取系统运行时间
[SYS_open]    sys_open,    // 打开文件
[SYS_write]   sys_write,   // 向文件写入数据
[SYS_mknod]   sys_mknod,   // 创建特殊文件
[SYS_unlink]  sys_unlink,  // 删除文件
[SYS_link]    sys_link,    // 创建文件硬链接
[SYS_mkdir]   sys_mkdir,   // 创建目录
[SYS_close]   sys_close,   // 关闭文件描述符
};

// 主系统调用处理函数
// 由trap.c中的usertrap()调用，当用户程序执行ecall指令时触发
// 系统调用号存储在a7寄存器中，参数在a0-a5中，结果返回到a0
void
syscall(void)
{
  int num;
  struct proc *p = myproc();

  // 从a7寄存器获取系统调用号
  num = p->trapframe->a7;
  // 检查系统调用号是否有效且对应的处理函数存在
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    // 调用对应的系统调用处理函数，并将返回值存储到a0寄存器
    p->trapframe->a0 = syscalls[num]();
  } else {
    // 未知的系统调用号，打印错误信息并返回-1
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}
