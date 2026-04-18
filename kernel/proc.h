// Saved registers for kernel context switches.
struct context {
  uint64 ra;
  uint64 sp;

  // callee-saved
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};

// Per-CPU state.
struct cpu {
  struct proc *proc;          // The process running on this cpu, or null.
  struct context context;     // swtch() here to enter scheduler().
  int noff;                   // Depth of push_off() nesting.
  int intena;                 // Were interrupts enabled before push_off()?
};

extern struct cpu cpus[NCPU];

// per-process data for the trap handling code in trampoline.S.
// sits in a page by itself just under the trampoline page in the
// user page table. not specially mapped in the kernel page table.
// the sscratch register points here.
// uservec in trampoline.S saves user registers in the trapframe,
// then initializes registers from the trapframe's
// kernel_sp, kernel_hartid, kernel_satp, and jumps to kernel_trap.
// usertrapret() and userret in trampoline.S set up
// the trapframe's kernel_*, restore user registers from the
// trapframe, switch to the user page table, and enter user space.
// the trapframe includes callee-saved user registers like s0-s11 because the
// return-to-user path via usertrapret() doesn't return through
// the entire kernel call stack.
// 保存用户态上下文（寄存器）以及部分内核信息的数据结构
// 当从 user mode 陷入 kernel 时，这些信息会被保存到这里
struct trapframe {

  /*   0 */ uint64 kernel_satp;   
  // 内核页表（satp寄存器值）
  // 用于从用户态切换到内核态时恢复正确的页表

  /*   8 */ uint64 kernel_sp;     
  // 当前进程的内核栈顶指针（kernel stack pointer）
  // 进入内核后切换到这个栈执行

  /*  16 */ uint64 kernel_trap;   
  // 内核trap处理函数地址（usertrap函数地址）
  // 在 trampoline 中会跳转到这里

  /*  24 */ uint64 epc;           
  // 用户程序的PC（程序计数器）
  // trap 返回时会恢复到这里继续执行（sepc）

  /*  32 */ uint64 kernel_hartid; 
  // 当前CPU核心ID（tp寄存器在内核中的值）
  // 用于多核调度

  // ============================
  // 以下是用户寄存器保存区
  // ============================

  /*  40 */ uint64 ra;  
  // 返回地址寄存器（return address）

  /*  48 */ uint64 sp;  
  // 用户栈指针（stack pointer）

  /*  56 */ uint64 gp;  
  // 全局指针（global pointer）

  /*  64 */ uint64 tp;  
  // 线程指针（thread pointer）

  /*  72 */ uint64 t0;  
  /*  80 */ uint64 t1;  
  /*  88 */ uint64 t2;  
  // 临时寄存器（caller-saved）

  /*  96 */ uint64 s0;  
  // 保存寄存器（callee-saved），也是 frame pointer（fp）

  /* 104 */ uint64 s1;  

  /* 112 */ uint64 a0;  
  // 函数参数 / 返回值寄存器（syscall返回值就在这里）

  /* 120 */ uint64 a1;  
  /* 128 */ uint64 a2;  
  /* 136 */ uint64 a3;  
  /* 144 */ uint64 a4;  
  /* 152 */ uint64 a5;  
  /* 160 */ uint64 a6;  
  /* 168 */ uint64 a7;  
  // a0-a7：函数参数寄存器
  // a7：系统调用号

  /* 176 */ uint64 s2;  
  /* 184 */ uint64 s3;  
  /* 192 */ uint64 s4;  
  /* 200 */ uint64 s5;  
  /* 208 */ uint64 s6;  
  /* 216 */ uint64 s7;  
  /* 224 */ uint64 s8;  
  /* 232 */ uint64 s9;  
  /* 240 */ uint64 s10; 
  /* 248 */ uint64 s11; 
  // 保存寄存器（callee-saved）

  /* 256 */ uint64 t3;  
  /* 264 */ uint64 t4;  
  /* 272 */ uint64 t5;  
  /* 280 */ uint64 t6;  
  // 临时寄存器（caller-saved）
};

enum procstate { UNUSED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

// Per-process state
struct proc {
  struct spinlock lock;

  // p->lock must be held when using these:
  enum procstate state;        // Process state
  struct proc *parent;         // Parent process
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  int xstate;                  // Exit status to be returned to parent's wait
  int pid;                     // Process ID

  // these are private to the process, so p->lock need not be held.
  uint64 kstack;               // Virtual address of kernel stack
  uint64 sz;                   // Size of process memory (bytes)
  pagetable_t pagetable;       // User page table
  struct trapframe *trapframe; // data page for trampoline.S
  struct context context;      // swtch() here to run process
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)
};
