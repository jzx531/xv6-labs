// 控制台输入输出模块：通过UART与用户交互
// 读取操作按行进行。实现特殊输入控制字符：
//   换行 -- 行结束
//   Ctrl-H -- 退格
//   Ctrl-U -- 删除整行
//   Ctrl-D -- 文件结束
//   Ctrl-P -- 打印进程列表

#include <stdarg.h>

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "proc.h"

#define BACKSPACE 0x100
#define C(x)  ((x)-'@')  // Control-x

// 向UART发送一个字符，用于printf和输入回显
// 该函数不直接用于write()系统调用
void
consputc(int c)
{
  if(c == BACKSPACE){
    // 用户输入退格时，用空格覆盖并回退光标
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
  }
}

struct {
  struct spinlock lock;
  
  // 控制台输入缓冲区
#define INPUT_BUF 128
  char buf[INPUT_BUF];
  uint r;  // 读取索引
  uint w;  // 写入完成索引
  uint e;  // 编辑索引
} cons;

// 来自用户的写请求都会通过此函数发送到控制台
int
consolewrite(int user_src, uint64 src, int n)
{
  int i;

  acquire(&cons.lock);
  for(i = 0; i < n; i++){
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
      break;
    uartputc(c);
  }
  release(&cons.lock);

  return i;
}

// 控制台读取入口。一次最多读取一整行数据到dst。
// user_dst指示目标地址是用户地址还是内核地址。
int
consoleread(int user_dst, uint64 dst, int n)
{
  uint target;
  int c;
  char cbuf;

  target = n;
  acquire(&cons.lock);
  while(n > 0){
    // 等待中断处理程序将输入放入缓冲区
    while(cons.r == cons.w){
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      // 如果用户还没有键入整行，任何读取进程都将在sleep系统调用中等待
      sleep(&cons.r, &cons.lock);
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // 文件结束标志
      if(n < target){
        // 保存^D，以便下次调用返回0字节结果
        cons.r--;
      }
      break;
    }

    // 将输入字节复制到用户空间缓冲区
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
      break;

    dst++;
    --n;

    if(c == '\n'){
      // 一整行输入已到达，返回用户级读取
      break;
    }
  }
  release(&cons.lock);

  return target - n;
}

// 控制台输入中断处理函数
// uartintr()收到字符后会调用此函数
// 执行退格/删除操作，将字符追加到缓冲区，
// 并在行结束时唤醒consoleread()
void
consoleintr(int c)
{
  acquire(&cons.lock);

  switch(c){
  case C('P'):  // 打印进程列表
    procdump();
    break;
  case C('U'):  // 删除当前输入行
    while(cons.e != cons.w &&
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;
  case C('H'): // 退格
  case '\x7f':
    if(cons.e != cons.w){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;
  default:
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
      c = (c == '\r') ? '\n' : c;

      // 回显输入字符
      consputc(c);

      // 保存到缓冲区，供consoleread()读取
      cons.buf[cons.e++ % INPUT_BUF] = c;

      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
        // 如果一整行到达、遇到EOF或缓冲区满，唤醒等待的读取
        cons.w = cons.e;
        wakeup(&cons.r);
      }
    }
    break;
  }
  
  release(&cons.lock);
}

// 初始化控制台设备，连接UART和控制台读写接口
void
consoleinit(void)
{
  initlock(&cons.lock, "cons");

  uartinit();

  // 将设备读取和写入方法绑定到控制台驱动
  devsw[CONSOLE].read = consoleread;
  devsw[CONSOLE].write = consolewrite;
}
