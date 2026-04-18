下面我把这段 `kernelvec.S` 按模块拆开解释。它其实包含两部分：

1. `kernelvec`：**内核态发生 trap 时的入口**
2. `timervec`：**机器态定时器中断入口**

核心区别是：

* `uservec` / `userret` 处理 **用户态 <-> 内核态**
* `kernelvec` 处理 **内核态里自己发生的中断/异常**
* `timervec` 处理 **机器态定时器中断**

---

# 一、`kernelvec` 是干什么的

注释已经说得很直白：

```asm
# interrupts and exceptions while in supervisor
# mode come here.
```

也就是：

**如果 CPU 当前已经在 S-mode（内核态），这时又发生中断或异常，就进入 `kernelvec`。**

比如：

* 内核执行时来了时钟中断
* 内核访问非法地址
* 内核里设备中断来了

这时不会走 `uservec`，而是走 `kernelvec`。

---

# 二、为什么 `kernelvec` 比 `uservec` 简单

因为进入 `kernelvec` 时，CPU 已经在内核态了，所以：

* 已经是内核页表
* 已经在内核栈上
* 不需要切换页表
* 不需要借助 `TRAPFRAME`

所以 `kernelvec` 的工作就很直接：

1. 在当前内核栈上保存寄存器
2. 调用 `kerneltrap()`
3. 恢复寄存器
4. `sret` 返回

---

# 三、`kernelvec` 逐行解析

---

## 1）入口

```asm
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
```

* `kernelvec` 是 trap 向量入口地址
* `trap.c` 里会把 `stvec` 设成这个地址
* `.align 4` 是按 16 字节对齐

---

## 2）给保存寄存器腾空间

```asm
addi sp, sp, -256
```

意思是：

**在当前内核栈上开辟 256 字节空间，作为 trap 保存区。**

为什么是 256？

因为这里要保存 32 个寄存器槽位附近的数据，每个 8 字节，实际保存了 31 个寄存器左右，总共留了 256 字节方便对齐。

---

## 3）保存寄存器

```asm
sd ra, 0(sp)
sd sp, 8(sp)
sd gp, 16(sp)
sd tp, 24(sp)
sd t0, 32(sp)
...
sd t6, 240(sp)
```

这一步就是：

**把当前内核态寄存器值压到当前内核栈里。**

因为接下来要调用 C 函数 `kerneltrap()`：

```asm
call kerneltrap
```

而 C 函数会改很多寄存器，所以必须先保存。

---

## 4）为什么连 `sp` 也保存

```asm
sd sp, 8(sp)
```

注意这时候的 `sp` 已经是：

```text
旧sp - 256
```

也就是“开完栈帧后的当前 sp”。

保存它是为了后面恢复现场时能把 trap 前的栈布局完整还原。

---

## 5）调用 `kerneltrap`

```asm
call kerneltrap
```

这会跳到 `trap.c` 里的 C 函数：

```c
void kerneltrap(void)
```

它负责：

* 读 `scause`
* 判断是异常还是中断
* 处理时钟中断 / 设备中断
* 必要时让出 CPU

---

# 四、恢复寄存器

```asm
ld ra, 0(sp)
ld sp, 8(sp)
ld gp, 16(sp)
...
ld t6, 240(sp)
```

这里把刚才保存在栈上的寄存器全部恢复。

---

## 一个很关键的细节：为什么不恢复 `tp`

你会看到这里故意注释掉了：

```asm
# not this, in case we moved CPUs: ld tp, 24(sp)
```

意思是：

**不要恢复 `tp`。**

为什么？

因为 xv6 里 `tp` 用来表示当前 hart / CPU 本地信息。
如果在 `kerneltrap()` 里发生了调度，进程可能切到另一个 CPU 上运行。
这时老的 `tp` 就不一定对了。

所以不能简单把 trap 前保存的 `tp` 恢复回来。

这句注释非常重要。

---

## 恢复栈指针空间

```asm
addi sp, sp, 256
```

把栈顶移回去，相当于弹出整个 trap 保存区。

---

## 返回到内核原来的执行点

```asm
sret
```

这会根据：

* `sepc`
* `sstatus`

回到 trap 发生前的那个内核执行位置。

因为这是 **S-mode trap**，所以也用 `sret`。

---

# 五、`kernelvec` 的整体流程总结

可以概括成：

```text
内核态发生 trap
-> kernelvec
-> 在当前内核栈上保存寄存器
-> 调 kerneltrap()
-> 恢复寄存器
-> sret 回到内核原来代码
```

---

# 六、`timervec` 是干什么的

下面这一段不是 S 态 trap 入口，而是：

```asm
# machine-mode timer interrupt.
```

也就是：

**机器态（M-mode）时钟中断入口。**

在 xv6/riscv 里，时钟中断最初是进 M-mode 的，不是直接进 S-mode。
所以需要一个 M-mode 的中转入口 `timervec`。

它的任务不是直接处理全部时钟逻辑，而是：

1. 设置下一次时钟中断
2. 给 S-mode 触发一个 software interrupt
3. 返回

这样 xv6 就能在 S-mode 统一处理中断逻辑。

---

# 七、`timervec` 逐行解析

---

## 1）先交换 `a0` 和 `mscratch`

```asm
csrrw a0, mscratch, a0
```

和 `uservec` 里 `sscratch` 的用法很像。

这里 `mscratch` 里事先放好了一个 per-hart 的 scratch 区地址。
交换后：

* `a0 = scratch 区地址`
* `mscratch = 原来 a0`

这样就能用 `a0` 访问这块 scratch 内存。

---

## 2）保存少量寄存器

```asm
sd a1, 0(a0)
sd a2, 8(a0)
sd a3, 16(a0)
```

这里只保存了 `a1/a2/a3`，因为后面代码只会改这几个寄存器，不需要像 `kernelvec` 那样保存一大堆。

这是一个“最小保存”。

---

## 3）注释里给了 scratch 的布局

```asm
# scratch[0,8,16] : register save area.
# scratch[32] : address of CLINT's MTIMECMP register.
# scratch[40] : desired interval between interrupts.
```

说明 `mscratch` 指向的内存布局是：

* `0`：保存 a1
* `8`：保存 a2
* `16`：保存 a3
* `32`：当前 hart 的 `mtimecmp` 地址
* `40`：定时器间隔

这块内存在 `start.c` 里提前设置好了。

---

## 4）设置下一次时钟中断

```asm
ld a1, 32(a0) # CLINT_MTIMECMP(hart)
ld a2, 40(a0) # interval
ld a3, 0(a1)
add a3, a3, a2
sd a3, 0(a1)
```

逻辑是：

* `a1` = 当前 hart 的 `mtimecmp` 地址
* `a2` = 定时间隔
* 读当前 `mtimecmp`
* 加上 interval
* 再写回去

效果：

**安排下一次 timer interrupt 发生的时间。**

否则这次中断处理完后，就不会再有下一次时钟中断了。

---

## 5）触发 supervisor software interrupt

```asm
li a1, 2
csrw sip, a1
```

这一步很关键。

`sip` 是 supervisor interrupt pending。
写入 `2`（也就是 SSIP 位）表示：

**伪造/触发一个 S-mode software interrupt。**

也就是说：

* M-mode timer interrupt 先到 `timervec`
* `timervec` 不直接做完整调度处理
* 而是转化成 S-mode 软件中断
* 后续由 S-mode 的 trap 机制统一处理

这是 xv6 的一种设计：把复杂逻辑尽量留在 S-mode。

---

## 6）恢复寄存器

```asm
ld a3, 16(a0)
ld a2, 8(a0)
ld a1, 0(a0)
csrrw a0, mscratch, a0
```

恢复先前保存的 `a1/a2/a3`，最后再把原来的 `a0` 从 `mscratch` 交换回来。

---

## 7）从 M-mode 返回

```asm
mret
```

注意这里不是 `sret`，而是 `mret`。

因为 `timervec` 是在 **M-mode** 里执行的，所以必须用 `mret` 返回。

---

# 八、`kernelvec` 和 `timervec` 的区别

| 项目      | kernelvec      | timervec                  |
| ------- | -------------- | ------------------------- |
| 进入模式    | S-mode trap    | M-mode timer interrupt    |
| 保存位置    | 当前内核栈          | `mscratch` 指向的小 scratch 区 |
| 保存寄存器数量 | 很多             | 很少                        |
| 调用 C 函数 | `kerneltrap()` | 不调用                       |
| 返回指令    | `sret`         | `mret`                    |
| 主要任务    | 处理内核态 trap     | 安排下次时钟并转发为 S 态软件中断        |

---

# 九、为什么 timer interrupt 不直接在 M-mode 全部处理

因为 xv6 希望大部分 OS 逻辑运行在 S-mode，不希望内核主体放在 M-mode。
M-mode 尽量只做最底层工作：

* 接一下机器态时钟中断
* 重装定时器
* 通知 S-mode 来处理

所以 `timervec` 很短，只做“中转”。

---

# 十、整段代码的角色总结

## `kernelvec`

是 **内核态 trap 的保存/恢复壳子**：

* 保存现场
* 调 `kerneltrap()`
* 恢复现场
* 返回

## `timervec`

是 **机器态时钟中断的中转站**：

* 保存少量寄存器
* 设置下次定时器
* 触发 S 态软件中断
* 返回

---

# 十一、一句最简总结

这份 `kernelvec.S` 做了两件事：

1. `kernelvec`：让内核态中断/异常能安全进入 `kerneltrap()` 再返回
2. `timervec`：把 M 态时钟中断转发成 S 态可处理的中断

---

如果你愿意，我下一条可以继续把 **`kernelvec -> kerneltrap()`** 和 **`timervec -> devintr()`** 在 `trap.c` 里的对应关系一起串起来讲。
