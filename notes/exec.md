# exec

exec(kernel/exec.c:13)
1. 使用namei (kernel/exec.c:26)打开指定的二进制path
2. 读取elf文件头部信息 (kernel/exec.c:30)
3. exec使用proc_pagetable (kernel/exec.c:38)分配一个没有用户映射的新页表，使用uvmalloc (kernel/exec.c:52)为每个ELF段分配内存，并使用loadseg (kernel/exec.c:10)将每个段加载到内存中。
4. loadseg使用walkaddr找到分配内存的物理地址，在该地址写入ELF段的每一页，并使用readi从文件中读取。
5. 在准备新内存映像的过程中，如果exec检测到像无效程序段这样的错误，它会跳到标签bad，释放新映像，并返回-1。
6. exec必须等待系统调用会成功后再释放旧映像：因为如果旧映像消失了，系统调用将无法返回-1。exec中唯一的错误情况发生在映像的创建过程中。一旦映像完成，exec就可以提交到新的页表(kernel/exec.c:113)并释放旧的页表(kernel/exec.c:117)。

ELF二进制文件由ELF头、struct elfhdr(kernel/elf.h:6)，后面一系列的程序节头（section headers）、struct proghdr(kernel/elf.h:25)组成。每个proghdr描述程序中必须加载到内存中的一节（section）；xv6程序只有一个程序节头，但是其他系统对于指令和数据部分可能各有单独的节。



ELF文件格式：在计算机科学中，是一种用于二进制文件、可执行文件、目标代码、共享库和核心转储格式文件。ELF是UNIX系统实验室（USL）作为应用程序二进制接口（Application Binary Interface，ABI）而开发和发布的，也是Linux的主要可执行文件格式。ELF文件由4部分组成，分别是ELF头（ELF header）、程序头表（Program header table）、节（Section）和节头表（Section header table）。实际上，一个文件中不一定包含全部内容，而且它们的位置也未必如同所示这样安排，只有ELF头的位置是固定的，其余各部分的位置、大小等信息由ELF头中的各项值来决定。

程序节头的filesz可能小于memsz，这表明它们之间的间隙应该用零来填充（对于C全局变量），而不是从文件中读取。对于/init，filesz是2112字节，memsz是2136字节，因此uvmalloc分配了足够的物理内存来保存2136字节，但只从文件/init中读取2112字节。

### exec 安全

exec将ELF文件中的字节加载到ELF文件指定地址的内存中。用户或进程可以将他们想要的任何地址放入ELF文件中。因此exec是有风险的，因为ELF文件中的地址可能会意外或故意的引用内核。对一个设计拙劣的内核来说，后果可能是一次崩溃，甚至是内核的隔离机制被恶意破坏（即安全漏洞）。xv6执行许多检查来避免这些风险。例如，if(ph.vaddr + ph.memsz < ph.vaddr)检查总和是否溢出64位整数，危险在于用户可能会构造一个ELF二进制文件，其中的ph.vaddr指向用户选择的地址，而ph.memsz足够大，使总和溢出到0x1000，这看起来像是一个有效的值。在xv6的旧版本中，用户地址空间也包含内核（但在用户模式下不可读写），用户可以选择一个与内核内存相对应的地址，从而将ELF二进制文件中的数据复制到内核中。在xv6的RISC-V版本中，这是不可能的，因为内核有自己独立的页表；loadseg加载到进程的页表中，而不是内核的页表中。