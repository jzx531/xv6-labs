// 物理内存分配器，用于用户进程、内核栈、页表页和管道缓冲区。
// 以整个4096字节页面为单位分配。

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // 内核结束后的第一个地址。
                   // 在kernel.ld中定义。

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
kinit()
{
  // 初始化kmem锁并将内核可用物理内存入口加入空闲链表。
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  // 将起始地址向上对齐到页面边界。
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// 释放由kalloc分配的物理页面，或在初始化时将页面加入空闲链表。
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // 用垃圾数据填充页面，便于发现悬空引用。
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// 分配一个4096字节的物理页面。
// 返回内核可使用的指针；如果没有可用内存则返回0。
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
    memset((char*)r, 5, PGSIZE); // 用垃圾数据填充分配页面
  return (void*)r;
}

// 统计空闲物理内存字节数（可扩展函数）。
void GetFreeBytes(uint64 * freebytes)
{
  *freebytes = 0;
  
}

void GetFreeBytes(uint64 * freebytes)
{
  *freebytes = 0;

}