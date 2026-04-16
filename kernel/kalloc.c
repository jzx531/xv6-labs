// 物理内存分配器，用于用户进程、内核栈、页表页和管道缓冲区。
// 分配整个 4096 字节的页面。

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

// 释放一段物理内存范围，将其添加到空闲链表。
void freerange(void *pa_start, void *pa_end);

extern char end[]; // 内核后的第一个地址，由 kernel.ld 定义。

// 空闲内存块的链表节点结构。
struct run {
  struct run *next;
};

// 内核内存管理器结构体，包含自旋锁和空闲链表。
struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

/*
 * 初始化内核内存分配器。
 * 设置自旋锁并将从内核结束地址到物理内存顶部的内存标记为空闲。
 */
void
kinit()
{
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

/*
 * 将一段物理内存范围添加到空闲链表。
 * 从 pa_start 到 pa_end 的内存会被按页对齐并释放。
 */
/*
kinit调用freerange将内存添加到空闲列表中，在freerange中每页都会调用kfree。
PTE只能引用在4096字节边界上对齐的物理地址（是4096的倍数），
所以freerange使用PGROUNDUP来确保它只释放对齐的物理地址
*/
void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

/*
 * 释放由 pa 指向的物理内存页面。
 * 该页面通常应该是由 kalloc() 返回的。
 * （初始化分配器时的例外情况见 kinit() 以上。）
 */
/*
函数kfree首先将内存中的每一个字节设置为1。
这将导致使用释放后的内存的代码（使用“悬空引用”）读取到垃圾信息而不是旧的有效内容，从而希望这样的代码更快崩溃。
然后kfree将页面前置（头插法）到空闲列表中：
它将pa转换为一个指向struct run的指针r，
在r->next中记录空闲列表的旧开始，并将空闲列表设置为等于r。
*/
void
kfree(void *pa)
{
  struct run *r;

  // 检查地址是否有效：必须页对齐、在内核范围内、不超过物理内存顶部。
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // 用垃圾数据填充以捕获悬空引用。
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

/*
 * 分配一个 4096 字节的物理内存页面。
 * 返回内核可以使用的指针。
 * 如果无法分配内存，则返回 0。
 */
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // 用垃圾数据填充
  return (void*)r;
}
