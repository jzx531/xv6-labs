#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"

#include "spinlock.h" 
#include "proc.h"
/*
 * 内核的页表。
 * 页表是虚拟内存管理的核心结构，
 * 它将虚拟地址映射到物理地址。
 */
/*pagetable_t，它实际上是指向RISC-V根页表页的指针；
一个pagetable_t可以是内核页表，也可以是一个进程页表*/
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld 设置的内核代码结束地址。

extern char trampoline[]; // trampoline.S 定义的陷阱跳板代码。

//向进程内核页表添加映射
void uvmmap(pagetable_t pagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(pagetable, va, sz, pa, perm) != 0)
      panic("uvmmap");
}

pagetable_t proc_kpt_init()
{
  pagetable_t kernelpt = uvmcreate();
  if(kernelpt == 0) return 0;
  // kernelpt = (pagetable_t) kalloc();
  // memset(kernelpt, 0, PGSIZE);
  // 映射 UART 寄存器，便于内核通过串口输出日志。
  uvmmap(kernelpt,UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // 映射 virtio 磁盘设备的 MMIO 寄存器。
  uvmmap(kernelpt,VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // 映射 CLINT（Core Local Interruptor）寄存器。
  uvmmap(kernelpt,CLINT, CLINT, 0x10000, PTE_R | PTE_W);

  // 映射 PLIC（Platform-Level Interrupt Controller）寄存器。
  uvmmap(kernelpt,PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // 将内核代码段映射为可执行且只读，避免内核代码被意外写入。
  uvmmap(kernelpt,KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // 将内核数据段和剩余物理 RAM 映射为可读写。
  uvmmap(kernelpt,(uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // 将陷阱跳板代码映射到最高内核虚拟地址，方便在异常/中断时切换到内核态。
  uvmmap(kernelpt,TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
  return kernelpt;
}

/*
 * 创建内核的直接映射页表。
 * 内核页表将一部分关键硬件地址和内核内存直接映射到物理地址，
 * 这在引导阶段构建并用于启动后切换到分页模式。
 */
void
kvminit()
{
  // 调用 kalloc() 申请一块物理内存（4KB），用来存放根页表（Root Page Table）本身。
  kernel_pagetable = (pagetable_t) kalloc();
  memset(kernel_pagetable, 0, PGSIZE);

  // 映射 UART 寄存器，便于内核通过串口输出日志。
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // 映射 virtio 磁盘设备的 MMIO 寄存器。
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // 映射 CLINT（Core Local Interruptor）寄存器。
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);

  // 映射 PLIC（Platform-Level Interrupt Controller）寄存器。
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // 将内核代码段映射为可执行且只读，避免内核代码被意外写入。
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // 将内核数据段和剩余物理 RAM 映射为可读写。
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // 将陷阱跳板代码映射到最高内核虚拟地址，方便在异常/中断时切换到内核态。
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
}

// 切换硬件 SATP 寄存器到内核页表并刷新 TLB。
// kvminithart (kernel/vm.c:53)来安装内核页表。
// 它将根页表页的物理地址写入寄存器satp。
// 之后，CPU将使用内核页表转换地址。由于内核使用标识映射，下一条指令的当前虚拟地址将映射到正确的物理内存地址。
void
kvminithart()
{
  w_satp(MAKE_SATP(kernel_pagetable));
  sfence_vma();
}

// Store kernel page table to SATP register
void
proc_inithart(pagetable_t kpt){
  w_satp(MAKE_SATP(kpt));
  sfence_vma();
}

/*
 * 返回页表中与虚拟地址 va 对应的页表项地址。
 * 如果 alloc != 0，会在需要时为页表的中间层分配页面。
 *
 * RISC-V Sv39 的地址翻译使用三级页表，每个页表页包含 512 个 PTE。
 * 虚拟地址格式：
 *   39..63 位：必须为 0。
 *   30..38 位：第 2 级索引。
 *   21..29 位：第 1 级索引。
 *   12..20 位：第 0 级索引。
 *    0..11 位：页内偏移。
 */
/* walk 遍历三级页表 为虚拟地址找到PTE*/
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  if(va >= MAXVA)
    panic("walk");

  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      // 情况 2：这一级目录还不存在
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
}

/*
 * 查找用户页表中虚拟地址 va 对应的物理地址。
 * 如果地址未映射、页表项无效或不允许用户访问，则返回 0。
 */
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

/*
 * 向内核页表添加一段映射，仅在内核引导阶段使用。
 * 这不会刷新 TLB，也不会立即启用分页。
 */
void
kvmmap(uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

/*
 * 将已映射的内核虚拟地址 va 转换为物理地址。
 * 仅用于栈等需要直接访问物理页的内核地址。
 * va 必须是页对齐的。
 */
uint64
kvmpa(uint64 va)
{
  uint64 off = va % PGSIZE;
  pte_t *pte;
  uint64 pa;

  // pte = walk(kernel_pagetable, va, 0);
  //使用进程内核页表
  pte = walk(myproc()->kernelpt, va, 0);

  if(pte == 0)
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    panic("kvmpa");
  pa = PTE2PA(*pte);
  return pa+off;
}

/*
 * 创建从虚拟地址 va 开始的映射，映射到物理地址 pa 开始的内存。
 * size 和 va 都可以不是页对齐的。
 * 返回 0 表示成功，-1 表示分配页表页失败。
 */
/*为新映射装载pte*/
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  // 1. 地址对齐处理
  // 内存映射必须以“页”为单位进行。
  // PGROUNDDOWN 宏的作用是将地址向下取整到页的起始地址。
  // 例如：如果 va 是 0x1005，PGROUNDDOWN 后会变成 0x1000（假设页大小 4096）。
  a = PGROUNDDOWN(va);
  
  // 计算需要映射的最后一个页面的起始地址。
  // (va + size - 1) 指向映射区域的最后一个字节。
  // 对其向下取整，就得到了最后一个字节的所在页的起始地址。
  last = PGROUNDDOWN(va + size - 1);

  // 2. 循环建立映射
  // 这是一个无限循环，直到处理完所有页面（a == last）才 break。
  for(;;){
    // 调用 walk 函数，找到虚拟地址 'a' 对应的页表项（PTE）的地址。
    // 参数 '1' 表示：如果中间的页表页不存在，walk 函数应该自动分配新页（alloc=1）。
    // 如果返回 0，说明内存耗尽，无法分配新的页表页，映射失败。
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;

    // 检查该页表项是否已经有效（PTE_V 标志位已置位）。
    // 如果已经有效，说明这块虚拟地址已经被映射过了。
    // 在 xv6 中，重复映射通常被视为错误（除非使用专门的 remap 函数），因此 panic。
    if(*pte & PTE_V)
      panic("remap");

    // 3. 填写页表项
    // 这是建立映射的核心步骤。
    // PA2PTE(pa): 将物理地址 'pa' 转换为页表项所需的格式（主要是提取物理页号 PPN）。
    // perm:       传入的权限位（如可读、可写、可执行）。
    // PTE_V:      有效位，置 1 表示这个映射是合法的。
    //wolk的过程中完成了对前两页的映射，现在需要对最后一页进行映射。
    *pte = PA2PTE(pa) | perm | PTE_V;

    // 4. 循环终止与步进
    // 如果当前处理的页面就是最后一个页面，跳出循环，任务完成。
    if(a == last)
      break;

    // 否则，处理下一页。
    // 虚拟地址加一个页大小
    a += PGSIZE;
    // 物理地址也加一个页大小（保证虚拟和物理内存的连续性）。
    pa += PGSIZE;
  }
  return 0;
}

/*
 * 删除从 va 开始的 npages 个映射，va 必须页对齐。
 * 如果 do_free 为 1，则释放对应的物理页面。
 */
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}

/*
 * 创建一个空的用户页表。
 * 返回 0 表示内存不足。
 */
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if(pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

/*
 * 将用户 initcode 加载到虚拟地址 0。
 * 仅用于第一个进程的初始化。
 */
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
  memmove(mem, src, sz);
}

/*
 * 为进程分配内存，将进程大小从 oldsz 增长到 newsz。
 * oldsz 和 newsz 可以不是页对齐。
 * 返回新的进程大小，失败时返回 0。
 */
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
  }
  return newsz;
}

/*
 * 释放用户页表中的页面，将进程大小从 oldsz 缩减到 newsz。
 * oldsz 和 newsz 可以不是页对齐。
 */
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

uint64
kvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    //与uvmdealloc不同的是，这里不释放物理页面
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);
  }

  return newsz;
}

/*
 * 递归释放页表页。
 * 所有叶子映射必须先被删除。
 */
void
freewalk(pagetable_t pagetable)
{
  // 一个页表页中有 512 个 PTE。
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // 该 PTE 指向下一级页表。
      uint64 child = PTE2PA(pte);
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
      panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
}

/*
 * 释放用户内存页面，然后释放页表页。
 */
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if(sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
}

/*
 * 复制父进程的页表内容到子进程。
 * 同时复制物理内存数据，适用于 fork 操作。
 */
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
      kfree(mem);
      goto err;
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

/*
 * 将用户访问权限从某个虚拟地址页清除，避免用户程序访问该页。
 * exec 用于保护用户栈的 guard page。
 */
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}

/*
实现将用户空间的映射添加到每个进程的内核页表，将进程的页表复制一份到进程的内核页表就好。
*/
int u2kvmcopy(pagetable_t pagetable, pagetable_t kernelpt,uint64 oldsz, uint64 newsz)
{
  pte_t *pte_from,*pte_to;
  oldsz = PGROUNDUP(oldsz); // 页对齐
  for(uint64 a = oldsz; a < newsz; a += PGSIZE){
    if((pte_from = walk(pagetable, a, 0)) == 0)
      panic("u2kvmcopy: pte should exist");
    if(!(*pte_from & PTE_V)) //该条件在walk0中已经检查过了
      panic("u2kvmcopy: page not present");
    if((pte_to = walk(kernelpt, a, 1))==0)
      panic("u2kvmcopy: pte walk failed");
    uint64 pa = PTE2PA(*pte_from);
    // 在内核模式下，无法访问设置了PTE_U的页面，所以我们要将其移除
    uint flags = (PTE_FLAGS(*pte_from)) & (~PTE_U);
    //不使用mappages是因为当重新将pagetable映射到kernelpt时，kernelpt已经被设置了PTE_V标志时会触发panic
    // if(mappages(kernelpt, a, PGSIZE, pa, flags) != 0)
    // {
    //   uvmunmap(kernelpt, oldsz, (a-oldsz)/PGSIZE, 0);
    //   return -1;
    // }
    *pte_to = PA2PTE(pa) | flags;
  }
  return 0;
}
/*
 * 将内核缓冲区内容复制到用户虚拟地址空间。
 * dstva 是用户虚拟地址，len 是复制长度。
 */
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

/*
 * 将用户虚拟地址空间的数据复制到内核缓冲区。
 */
/*
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);

    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;
}
*/
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  return copyin_new(pagetable, dst, srcva, len);
}


/*
 * 从用户虚拟地址空间复制一个以 '\0' 结尾的字符串到内核缓冲区。
 * 如果在 max 以内没有发现 '\0'，则返回 -1。
 */
/*
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
        got_null = 1;
        break;
      } else {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    return 0;
  } else {
    return -1;
  }
}*/
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  return copyinstr_new(pagetable, dst, srcva, max);
}


void vmprint_level(pagetable_t pagetable,int level)
{
  // 一个页表页中有 512 个 PTE。
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    //(pte & (PTE_R|PTE_W|PTE_X) 代表直接映射到物理内存
    // 而 (pte & PTE_V) 代表该页表项有效
    if(pte & PTE_V) {
      for(int j = 0; j < level; j++)
      {
        printf("..");
        if(j!= level-1) printf(" ");
      }
      // printf("%d: pte ", i);
      uint64 child = PTE2PA(pte);
      // printf("%p, pa  %p\n", pte,child);
      printf("%d: pte %p pa %p\n", i, pte, child);
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0) // 该 PTE 指向下一级页表
      {
        vmprint_level((pagetable_t)child, level+1);
      }
    }
  }
}

void vmprint(pagetable_t pagetable)
{
    printf("page table %p\n", pagetable);
    vmprint_level(pagetable, 1);
}


// /**
//  * @param pagetable 所要打印的页表
//  * @param level 页表的层级
//  */
// void
// _vmprint(pagetable_t pagetable, int level){
//   // there are 2^9 = 512 PTEs in a page table.
//   for(int i = 0; i < 512; i++){
//     pte_t pte = pagetable[i];
//     // PTE_V is a flag for whether the page table is valid
//     if(pte & PTE_V){
//       for (int j = 0; j < level; j++){
//         if (j) printf(" ");
//         printf("..");
//       }
//       uint64 child = PTE2PA(pte);
//       printf("%d: pte %p pa %p\n", i, pte, child);
//       if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
//         // this PTE points to a lower-level page table.
//         _vmprint((pagetable_t)child, level + 1);
//       }
//     }
//   }
// }

// /**
//  * @brief vmprint 打印页表
//  * @param pagetable 所要打印的页表
//  */
// void
// vmprint(pagetable_t pagetable){
//   printf("page table %p\n", pagetable);
//   _vmprint(pagetable, 1);
// }