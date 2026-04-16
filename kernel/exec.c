#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"

// 加载程序段到页表中的静态函数声明。
static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);



/*
 * 执行一个新的程序。
 * 替换当前进程的内存映像和上下文。
 * path 是可执行文件的路径，argv 是命令行参数。
 * 返回参数数量（argc），失败时返回 -1。
 */
int
exec(char *path, char **argv)
{
  char *s, *last;
  int i, off;
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();

  begin_op();

  // 查找并锁定可执行文件。
  if((ip = namei(path)) == 0){
    end_op();
    return -1;
  }
  ilock(ip);

  // 检查 ELF 头部。
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    goto bad;
  if(elf.magic != ELF_MAGIC)
    goto bad;

  // 创建新的页表。
  if((pagetable = proc_pagetable(p)) == 0)
    goto bad;

  // 将程序加载到内存中。
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
    if(ph.vaddr + ph.memsz < ph.vaddr)
      goto bad;
    uint64 sz1;
    // 为程序段分配内存。
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    sz = sz1;
    if(ph.vaddr % PGSIZE != 0)
      goto bad;
    // 加载程序段。
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
  end_op();
  ip = 0;

  p = myproc();
  uint64 oldsz = p->sz;

  // 在下一个页边界分配两个页面，使用第二个作为用户栈。
  sz = PGROUNDUP(sz);
  uint64 sz1;
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
  sz = sz1;
  // 清除栈保护页的用户访问权限。
  uvmclear(pagetable, sz-2*PGSIZE);
  sp = sz;
  stackbase = sp - PGSIZE;

  // 推送参数字符串，准备 ustack 中的其余栈。
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp -= sp % 16; // riscv sp 必须 16 字节对齐
    if(sp < stackbase)
      goto bad;
    // 将参数字符串复制到用户栈。
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[argc] = sp;
  }
  ustack[argc] = 0;

  // 推送 argv[] 指针数组。
  sp -= (argc+1) * sizeof(uint64);
  sp -= sp % 16;
  if(sp < stackbase)
    goto bad;
  // 将指针数组复制到用户栈。
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    goto bad;

  // 用户 main(argc, argv) 的参数
  // argc 通过系统调用返回值返回，在 a0 中。
  p->trapframe->a1 = sp;

  // 保存程序名用于调试。
  for(last=s=path; *s; s++)
    if(*s == '/')
      last = s+1;
  safestrcpy(p->name, last, sizeof(p->name));
    
  // 提交到用户映像。
  /*
  只有当新的程序映像（包括代码、数据、栈等）被完全构建并验证无误后，内核才会执行 proc_freepagetable(oldpagetable, oldsz)。
  这个操作将旧的内存映像彻底清除，标志着“替换”动作的最终完成。在此之前，旧的映像一直完好无损地保留着。
  */
  oldpagetable = p->pagetable;
  p->pagetable = pagetable;
  p->sz = sz;
  p->trapframe->epc = elf.entry;  // 初始程序计数器 = main
  p->trapframe->sp = sp; // 初始栈指针
  proc_freepagetable(oldpagetable, oldsz);

  if(p->pid==1) vmprint(p->pagetable); // 打印进程地址空间布局

  return argc; // 这最终在 a0 中，作为 main(argc, argv) 的第一个参数

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    end_op();
  }
  return -1;
}

/*
 * 将程序段加载到页表中的虚拟地址 va。
 * va 必须是页对齐的，并且从 va 到 va+sz 的页面必须已经映射。
 * 成功返回 0，失败返回 -1。
 */
static int
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    // 从文件中读取数据到物理内存。
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
      return -1;
  }
  
  return 0;
}
