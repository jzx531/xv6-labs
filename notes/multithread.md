# Multithreading in xv6

## 多路复用

Xv6通过在两种情况下将每个CPU从一个进程切换到另一个进程来实现多路复用Multiplexing
1. 当进程等待设备或者管道IO完成,或等待子进程退出，或在sleep系统调用中等待时,xv6使用睡眠和唤醒机制切换
2. xv6周期性的强制切换以处理长时间计算而不睡眠的进程

Xv6通过标准技术，通过定时器中断驱动上下文切换
许多CPU可能同时在进程之间切换,使用锁方案来避免争用

多核机器的每个核心必须记住它正在执行哪个进程,以便系统调用正确影响对应进程的内核状态
sleep允许一个进程放弃cpu,另一个进程唤醒第一个进程


## 上下文切换

![alt text](switch.png)

从一个线程切换到另一个线程需要保存旧线程的CPU寄存器，并恢复新线程先前保存的寄存器；栈指针和程序计数器被保存和恢复的事实意味着CPU将切换栈和执行中的代码。

函数swtch为内核线程切换执行保存和恢复操作。swtch对线程没有直接的了解；它只是保存和恢复寄存器集，称为上下文（contexts）。当某个进程要放弃CPU时，该进程的内核线程调用swtch来保存自己的上下文并返回到调度程序的上下文。每个上下文都包含在一个struct context（kernel/proc.h:2）中，这个结构体本身包含在一个进程的struct proc或一个CPU的struct cpu中。Swtch接受两个参数：struct context *old和struct context *new。它将当前寄存器保存在old中，从new中加载寄存器，然后返回。

让我们跟随一个进程通过swtch进入调度程序。我们在第4章中看到，中断结束时的一种可能性是usertrap调用了yield。依次地：Yield调用sched，sched调用swtch将当前上下文保存在p->context中，并切换到先前保存在cpu->scheduler（kernel/proc.c:517）中的调度程序上下文。

Swtch只保存被调用方保存到寄存器,调用方保存的寄存器保存在栈上
swtch保存每个context中寄存器字段偏移,它不保存程序计数器而是swtch的返回地址
swtch从新进程的上下文中恢复寄存器,该上下文保存前一个swtch保存的寄存器值

当swtch返回时,它返回由ra寄存器指定的指令,即新线程以前调用的指令。并且它在新线程的栈上返回

## sched调度

进程 -> sched() -> swtch -> 调度器 -> (选择新进程) -> swtch -> 新进程。
想要放弃cpu的进程必须先获得自己的进程锁p->lock，并释放它持有的任何其他锁,更新自己的状态然后调用sched

sched会对上述条件再次进行检查,并且检查条件对应的隐含条件:由于锁被持有,中断应该被禁止

sched调用swtch将当前上下文保存在p->context中,并切换到cpu->scheduler的调度上下文
Swtch在调度程序的栈上返回,就像scheduler的swtch返回
scheduler继续for循环，找到要运行的进程，切换到该进程，重复循环。

xv6在对swtch的调用中持有p->lock：swtch的调用者必须已经持有了锁，并且锁的控制权传递给切换到的代码。这种约定在锁上是不寻常的；通常，获取锁的线程还负责释放锁，这使得对正确性进行推理更加容易。对于上下文切换，有必要打破这个惯例，因为p->lock保护进程state和context字段上的不变量，而这些不变量在swtch中执行时不成立。如果在swtch期间没有保持p->lock，可能会出现一个问题：在yield将其状态设置为RUNNABLE之后，但在swtch使其停止使用自己的内核栈之前，另一个CPU可能会决定运行该进程。结果将是两个CPU在同一栈上运行，这不可能是正确的。

(持锁是为了防止多CPU间调度不同步导致运行和调度发生竞争)

存在一种情况使得调度程序对swtch的调用没有以sched结束。一个新进程第一次被调度时，它从forkret（kernel/proc.c:527）开始。Forkret存在以释放p->lock；否则，新进程可以从usertrapret开始。

scheduler（kernel/proc.c:457）运行一个简单的循环：找到要运行的进程，运行它直到它让步，然后重复循环。scheduler在进程表上循环查找可运行的进程，该进程具有p->state == RUNNABLE。一旦找到一个进程，它将设置CPU当前进程变量c->proc，将该进程标记为RUNINING，然后调用swtch开始运行它

调度代码为每个进程强制维持一个不变量的集合
并在这些不变量不成立时持有p->lock,其中一个不变量是:
如果一个进程是RUNNABLE状态,空闲CPU的调度程序必须安全地运行它
p->context必须保存进程的寄存器,没有CPU在进程 的内核栈上执行,并且没有CPU 的c->proc引用进程

维护上述不变量是xv6经常在一个线程中获取p->lock并在另一个线程中释放它的原因，例如在yield中获取并在scheduler中释放。一旦yield开始修改一个RUNNING进程的状态为RUNNABLE，锁必须保持被持有状态，直到不变量恢复：最早的正确释放点是scheduler（在其自身栈上运行）清除c->proc之后。类似地，一旦scheduler开始将RUNNABLE进程转换为RUNNING，在内核线程完全运行之前（在swtch之后，例如在yield中）绝不能释放锁。

p->lock还保护其他东西,exit和wait之间的相互竞争,避免丢失wakeup的机制,以及避免一个进程退出和其他进程读写其状态之间的竞争

## mycpu和myproc

Xv6需要指向当前进程的proc结构体的指针
在单处理器系统上,可以有一个指向当前的proc的全局变量
但对于多核系统,每个核执行的进程不同,解决方法是：基于每个核心创建自己的寄存器值，从而使用其中一个寄存器来帮助查找每个核心的信息

Xv6为每个CPU维护一个struct cpu，它记录当前在该CPU上运行的进程（如果有的话），为CPU的调度线程保存寄存器，以及管理中断禁用所需的嵌套自旋锁的计数。函数mycpu (kernel/proc.c:60)返回一个指向当前CPU的struct cpu的指针。RISC-V给它的CPU编号，给每个CPU一个hartid。Xv6确保每个CPU的hartid在内核中存储在该CPU的tp寄存器中。这允许mycpu使用tp对一个cpu结构体数组（即cpus数组，kernel/proc.c:9）进行索引，以找到正确的那个。

Xv6为每个cpu维护一个struct cpu,它记录当前在该cpu上运行的进程,为CPU的调度线程保存寄存器，以及管理中断禁用所需的嵌套自旋锁的计数。函数mycpu (kernel/proc.c:60)返回一个指向当前CPU的struct cpu的指针。RISC-V给它的CPU编号，给每个CPU一个hartid。Xv6确保每个CPU的hartid在内核中存储在该CPU的tp寄存器中。这允许mycpu使用tp对一个cpu结构体数组（即cpus数组，kernel/proc.c:9）进行索引，以找到正确的那个。
确保CPU的tp始终保存CPU的hartid有点麻烦。mstart在CPU启动次序的早期设置tp寄存器，此时仍处于机器模式（kernel/start.c:46）。因为用户进程可能会修改tp，usertrapret在蹦床页面（trampoline page）中保存tp。最后，uservec在从用户空间（kernel/trampoline.S:70）进入内核时恢复保存的tp。编译器保证永远不会使用tp寄存器。如果RISC-V允许xv6直接读取当前hartid会更方便，但这只允许在机器模式下，而不允许在管理模式下。

cpuid和mycpu的返回值很脆弱：如果定时器中断并导致线程让步（yield），然后移动到另一个CPU，以前返回的值将不再正确。为了避免这个问题，xv6要求调用者禁用中断，并且只有在使用完返回的struct cpu后才重新启用。

函数myproc (kernel/proc.c:68)返回当前CPU上运行进程struct proc的指针。myproc禁用中断，调用mycpu，从struct cpu中取出当前进程指针（c->proc），然后启用中断。即使启用中断，myproc的返回值也可以安全使用：如果计时器中断将调用进程移动到另一个CPU，其struct proc指针不会改变。

