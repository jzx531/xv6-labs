# Lock
```c
struct element {
    int data;
    struct element *next;
}; 

struct element *list = 0;
struct lock listlock;

void 
push(int data)
{
    struct element *l;

    l = malloc(sizeof *l);
    l->data = data;
    acquire(&listlock);
    l->next = list;
    list = l; 
    release(&listlock);
}
```
您可以将锁视为串行化（serializing）并发的临界区域，以便同时只有一个进程在运行这部分代码，从而维护不变量（假设临界区域设定了正确的隔离性）。您还可以将由同一锁保护的临界区域视为彼此之间的原子，即彼此之间只能看到之前临界区域的完整更改集，而永远看不到部分完成的更新。

自旋锁逻辑代码
```c
void
acquire(struct spinlock* lk) // does not work!
{
  for(;;) {
    if(lk->locked == 0) {
      lk->locked = 1;
      break;
    }
  }
}
```

多核处理器通常提供实现第5行和第6行的原子版本的指令。在RISC-V上，这条指令是amoswap r, a。amoswap读取内存地址a处的值，将寄存器r的内容写入该地址，并将其读取的值放入r中。也就是说，它交换寄存器和指定内存地址的内容。它原子地执行这个指令序列，使用特殊的硬件来防止任何其他CPU在读取和写入之间使用内存地址。

Xv6的acquire(kernel/spinlock.c:22)使用可移植的C库调用归结为amoswap的指令__sync_lock_test_and_set；返回值是lk->locked的旧（交换了的）内容。acquire函数将swap包装在一个循环中，直到它获得了锁前一直重试（自旋）。每次迭代将1与lk->locked进行swap操作，并检查lk->locked之前的值。如果之前为0，swap已经把lk->locked设置为1，那么我们就获得了锁；如果前一个值是1，那么另一个CPU持有锁，我们原子地将1与lk->locked进行swap的事实并没有改变它的值。

函数release(kernel/spinlock.c:47) 与acquire相反：它清除lk->cpu字段，然后释放锁。从概念上讲，release只需要将0分配给lk->locked。C标准允许编译器用多个存储指令实现赋值，因此对于并发代码，C赋值可能是非原子的。因此release使用执行原子赋值的C库函数__sync_lock_release。该函数也可以归结为RISC-V的amoswap指令。

## 使用锁

作为粗粒度锁的一个例子，xv6的kalloc.c分配器有一个由单个锁保护的空闲列表。如果不同CPU上的多个进程试图同时分配页面，每个进程在获得锁之前将必须在acquire中自旋等待。自旋会降低性能，因为它只是无用的等待。如果对锁的争夺浪费了很大一部分CPU时间，也许可以通过改变分配器的设计来提高性能，使其拥有多个空闲列表，每个列表都有自己的锁，以允许真正的并行分配。

作为细粒度锁定的一个例子，xv6对每个文件都有一个单独的锁，这样操作不同文件的进程通常可以不需等待彼此的锁而继续进行。文件锁的粒度可以进一步细化，以允许进程同时写入同一个文件的不同区域。最终的锁粒度决策需要由性能测试和复杂性考量来驱动。

| 锁                     | 描述                                                                 |
|------------------------|----------------------------------------------------------------------|
| bcache.lock            | 保护块缓冲区缓存项（block buffer cache entries）的分配              |
| cons.lock              | 串行化对控制台硬件的访问，避免混合输出                              |
| ftable.lock            | 串行化文件表中文件结构体的分配                                      |
| icache.lock            | 保护索引结点缓存项（inode cache entries）的分配                      |
| vdisk_lock             | 串行化对磁盘硬件和DMA描述符队列的访问                               |
| kmem.lock              | 串行化内存分配                                                      |
| log.lock               | 串行化事务日志操作                                                  |
| 管道的 pi->lock        | 串行化每个管道的操作                                                |
| pid_lock               | 串行化 next_pid 的增量                                              |
| 进程的 p->lock         | 串行化进程状态的改变                                                |
| tickslock              | 串行化时钟计数操作                                                  |
| 索引结点的 ip->lock    | 串行化索引结点及其内容的操作                                        |
| 缓冲区的 b->lock       | 串行化每个块缓冲区的操作                                            |


## 锁和中断处理函数

自旋锁和中断存在潜在危险: 假设sys_sleep持有tickslock,并且它的CPU被计时器中断中断,clockintr会尝试获取tickslock,意识到它被持有后等待释放,但是tickslock永远不会被释放：只有sys_sleep可以释放它，但是sys_sleep直到clockintr返回前不能继续运行。所以CPU会死锁，任何需要锁的代码也会冻结。

为了避免这种情况,如果一个自选锁被中断处理程序所使用,CPU必须保证在启用中断的情况下永远不能持有该锁

XV6使用保守解决方法:当CPU获取任何锁时,xv6总是会禁用该CPU上的中断,中断仍然会发生在其他CPU上,此时中断的acquire可以等待线程释放自旋锁;由于不在同一CPU上,不会造成死锁

当cpu未持有自旋锁，xv6重新启用中断,它必须做一些记录来处理嵌套的临界区域
acquire调用push off并且release调用pop off来耿总当前cpu上锁的嵌套级别
如果计数器达到零,pop off恢复最外层临界区域开始时存在的中断使能状态
intr_off和intr_on函数执行RISC-V指令分别用来禁用和启用中断。

严格的设置lk->locked之前让acquire调用push off如果两者颠倒会存在一个既持有锁又启用了中断的短暂窗口期，不幸的话定时器中断会使系统死锁。同样，只有在释放锁之后，release才调用pop_off也是很重要的

## 睡眠锁

有时xv6需要长时间保持锁。例如，文件系统（第8章）在磁盘上读写文件内容时保持文件锁定，这些磁盘操作可能需要几十毫秒。如果另一个进程想要获取自旋锁，那么长时间保持自旋锁会导致获取进程在自旋时浪费很长时间的CPU。自旋锁的另一个缺点是，一个进程在持有自旋锁的同时不能让出（yield）CPU，然而我们希望持有锁的进程等待磁盘I/O的时候其他进程可以使用CPU。持有自旋锁时让步是非法的，因为如果第二个线程试图获取自旋锁，就可能导致死锁：因为acquire不会让出CPU，第二个线程的自旋可能会阻止第一个线程运行并释放锁。在持有锁时让步也违反了在持有自旋锁时中断必须关闭的要求。因此，我们想要一种锁，它在等待获取锁时让出CPU，并允许在持有锁时让步（以及中断）。

Xv6以睡眠锁（sleep-locks）的形式提供了这种锁。acquiresleep (kernel/sleeplock.c:22) 在等待时让步CPU，使用的技术将在第7章中解释。在更高层次上，睡眠锁有一个被自旋锁保护的锁定字段，acquiresleep对sleep的调用原子地让出CPU并释放自旋锁。结果是其他线程可以在acquiresleep等待时执行。

因为睡眠锁保持中断使能，所以它们不能用在中断处理程序中。因为acquiresleep可能会让出CPU，所以睡眠锁不能在自旋锁临界区域中使用（尽管自旋锁可以在睡眠锁临界区域中使用）。

因为等待会浪费CPU时间，所以自旋锁最适合短的临界区域；睡眠锁对于冗长的操作效果很好。

