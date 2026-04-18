# Interrupt and Device Drivers

控制台驱动程序（console.c）是驱动程序结构的简单说明。控制台驱动程序通过连接到RISC-V的UART串口硬件接受人们键入的字符。控制台驱动程序一次累积一行输入，处理如backspace和Ctrl-u的特殊输入字符。用户进程，如Shell，使用read系统调用从控制台获取输入行。当您在QEMU中通过键盘输入到xv6时，您的按键将通过QEMU模拟的UART硬件传递到xv6。

驱动程序管理的UART硬件是由QEMU仿真的16550芯片。在真正的计算机上，16550将管理连接到终端或其他计算机的RS232串行链路。运行QEMU时，它连接到键盘和显示器。

UART硬件在软件中看起来是一组内存映射的控制寄存器。也就是说，存在一些RISC-V硬件连接到UART的物理地址，以便载入(load)和存储(store)操作与设备硬件而不是内存交互。UART的内存映射地址起始于0x10000000或UART0 (kernel/memlayout.h:21)。有几个宽度为一字节的UART控制寄存器，它们关于UART0的偏移量在(kernel/uart.c:22)中定义。例如，LSR寄存器包含指示输入字符是否正在等待软件读取的位。这些字符（如果有的话）可用于从RHR寄存器读取。每次读取一个字符，UART硬件都会从等待字符的内部FIFO寄存器中删除它，并在FIFO为空时清除LSR中的“就绪”位。UART传输硬件在很大程度上独立于接收硬件；如果软件向THR写入一个字节，则UART传输该字节。

Xv6的main函数调用consoleinit（kernel/console.c:184）来初始化UART硬件。该代码配置UART：UART对接收到的每个字节的输入生成一个接收中断，对发送完的每个字节的输出生成一个发送完成中断（kernel/uart.c:53）。

xv6的shell通过init.c (user/init.c:19)中打开的文件描述符从控制台读取输入。对read的调用实现了从内核流向consoleread (kernel/console.c:82)的数据通路。consoleread等待输入到达（通过中断）并在cons.buf中缓冲，将输入复制到用户空间，然后（在整行到达后）返回给用户进程。如果用户还没有键入整行，任何读取进程都将在sleep系统调用中等待（kernel/console.c:98）（第7章解释了sleep的细节）。

当用户输入一个字符时，UART硬件要求RISC-V发出一个中断，从而激活xv6的陷阱处理程序。陷阱处理程序调用devintr（kernel/trap.c:177），它查看RISC-V的scause寄存器，发现中断来自外部设备。然后它要求一个称为PLIC的硬件单元告诉它哪个设备中断了（kernel/trap.c:186）。如果是UART，devintr调用uartintr。

uartintr（kernel/uart.c:180）从UART硬件读取所有等待输入的字符，并将它们交给consoleintr（kernel/console.c:138）；它不会等待字符，因为未来的输入将引发一个新的中断。consoleintr的工作是在cons.buf中积累输入字符，直到一整行到达。consoleintr对backspace和其他少量字符进行特殊处理。当换行符到达时，consoleintr唤醒一个等待的consoleread（如果有的话）。

一旦被唤醒，consoleread将监视cons.buf中的一整行，将其复制到用户空间，并返回（通过系统调用机制）到用户空间。

在连接到控制台的文件描述符上执行write系统调用，最终将到达uartputc(kernel/uart.c:87) 。设备驱动程序维护一个输出缓冲区（uart_tx_buf），这样写进程就不必等待UART完成发送；相反，uartputc将每个字符附加到缓冲区，调用uartstart来启动设备传输（如果还未启动），然后返回。导致uartputc等待的唯一情况是缓冲区已满。

每当UART发送完一个字节，它就会产生一个中断。uartintr调用uartstart，检查设备是否真的完成了发送，并将下一个缓冲的输出字符交给设备。因此，如果一个进程向控制台写入多个字节，通常第一个字节将由uartputc调用uartstart发送，而剩余的缓冲字节将由uartintr调用uartstart发送，直到传输完成中断到来。

需要注意，这里的一般模式是通过缓冲区和中断机制将设备活动与进程活动解耦。即使没有进程等待读取输入，控制台驱动程序仍然可以处理输入，而后续的读取将看到这些输入。类似地，进程无需等待设备就可以发送输出。这种解耦可以通过允许进程与设备I/O并发执行来提高性能，当设备很慢（如UART）或需要立即关注（如回声型字符(echoing typed characters)）时，这种解耦尤为重要。这种想法有时被称为I/O并发

常见的三种并发风险:
1. 运行在不同CPU上的两个进程可能同时调用consoleread;
2. 硬件或许在consoleread正在执行时要求CPU传递控制台中断
3. 硬件在当前cpu执行consoleread时向其他CPU传递控制台中断

在驱动程序中需要注意并发的另一种场景是，一个进程可能正在等待来自设备的输入，但是输入的中断信号可能是在另一个进程（或者根本没有进程）正在运行时到达的。因此中断处理程序不允许考虑他们已经中断的进程或代码。例如，中断处理程序不能安全地使用当前进程的页表调用copyout（注：因为你不知道是否发生了进程切换，当前进程可能并不是原先的进程）。中断处理程序通常做相对较少的工作（例如，只需将输入数据复制到缓冲区），并唤醒上半部分代码来完成其余工作。

Xv6使用定时器中断来维持其时钟，并使其能够在受计算量限制的进程（compute-bound processes）之间切换；usertrap和kerneltrap中的yield调用会导致这种切换。定时器中断来自附加到每个RISC-V CPU上的时钟硬件。Xv6对该时钟硬件进行编程，以定期中断每个CPU。

RISC-V要求定时器中断在机器模式而不是管理模式下进行,RISC-V机器模式无需分页即可执行,并且由一组单独的控制寄存器
在机器模式下无法运行普通的xv6内核代码因此，xv6处理定时器中断完全不同于上面列出的陷阱机制。

机器模式下执行的代码位于main之前的start.c中，它设置了接收定时器中断（kernel/start.c:57）。工作的一部分是对CLINT（core-local interruptor）硬件编程，以在特定延迟后生成中断。另一部分是设置一个scratch区域，类似于trapframe，以帮助定时器中断处理程序保存寄存器和CLINT寄存器的地址。最后，start将mtvec设置为timervec，并使能定时器中断。

计时器中断可能发生在用户或内核代码正在执行的任何时候;内核无法在临界区操作期间禁用计时器中断
计时器中断处理程序必须保证不干扰中断的内核代码，基本策略是处理程序要求RISC-V发出软件中断并立即返回

RISC-V用普通陷阱机制将软件中断传递给内核，并允许内核禁用它们

机器模式定时器中断向量是timervec

它在start准备的scratch区域中保存一些寄存器，以告诉CLINT何时生成下一个定时器中断，要求RISC-V引发软件中断，恢复寄存器，并且返回。定时器中断处理程序中没有C代码。