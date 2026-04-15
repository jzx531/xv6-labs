# Syscalls

调用系统调用

用户代码将exec需要的参数放在寄存器a0和a7 ,系统调用号在a7中

系统调用号与syscalls数组中的条目相匹配，syscalls数组是一个函数指针表

ecall指令陷入(trap)到内核中，执行<mark>uservec</mark>、<mark>usertrap</mark>和<mark>syscall</mark>

syscall（kernel/syscall.c:133）从陷阱帧（trapframe）中保存的a7中检索系统调用号（p->trapframe->a7），并用它索引到syscalls中，对于第一次系统调用，a7中的内容是SYS_exec（kernel/syscall. h:8），导致了对系统调用接口函数sys_exec的调用。

当系统调用接口函数返回时，syscall将其返回值记录在p->trapframe->a0中。这将导致原始用户空间对exec()的调用返回该值，因为RISC-V上的C调用约定将返回值放在a0中。系统调用通常返回负数表示错误，返回零或正数表示成功。如果系统调用号无效，syscall打印错误并返回-1

内核中的系统调用接口需要找到用户代码传递的参数。因为用户代码调用了系统调用封装函数，所以参数最初被放置在RISC-V C调用所约定的地方：寄存器。内核陷阱代码将用户寄存器保存到当前进程的陷阱框架中，内核代码可以在那里找到它们。函数artint、artaddr和artfd从陷阱框架中检索第n个系统调用参数并以整数、指针或文件描述符的形式保存。他们都调用argraw来检索相应的保存的用户寄存器（kernel/syscall.c:35）。

有些系统调用传递指针作为参数，内核必须使用这些指针来读取或写入用户内存。例如：exec系统调用传递给内核一个指向用户空间中字符串参数的指针数组。这些指针带来了两个挑战。首先，用户程序可能有缺陷或恶意，可能会传递给内核一个无效的指针，或者一个旨在欺骗内核访问内核内存而不是用户内存的指针。其次，xv6内核页表映射与用户页表映射不同，因此内核不能使用普通指令从用户提供的地址加载或存储。

内核实现了安全地将数据传输到用户提供的地址和从用户提供的地址传输数据的功能。fetchstr是一个例子（kernel/syscall.c:25）。文件系统调用，如exec，使用fetchstr从用户空间检索字符串文件名参数。fetchstr调用copyinstr来完成这项困难的工作。

copyinstr（kernel/vm.c:406）从用户页表页表中的虚拟地址srcva复制max字节到dst。它使用walkaddr（它又调用walk）在软件中遍历页表，以确定srcva的物理地址pa0。由于内核将所有物理RAM地址映射到同一个内核虚拟地址，copyinstr可以直接将字符串字节从pa0复制到dst。walkaddr（kernel/vm.c:95）检查用户提供的虚拟地址是否为进程用户地址空间的一部分，因此程序不能欺骗内核读取其他内存。一个类似的函数copyout，将数据从内核复制到用户提供的地址。