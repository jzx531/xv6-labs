#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "e1000_dev.h"
#include "net.h"

#define TX_RING_SIZE 16  // 发送环大小
static struct tx_desc tx_ring[TX_RING_SIZE] __attribute__((aligned(16)));  // 发送描述符环
static struct mbuf *tx_mbufs[TX_RING_SIZE];  // 发送mbuf缓冲区

#define RX_RING_SIZE 16  // 接收环大小
static struct rx_desc rx_ring[RX_RING_SIZE] __attribute__((aligned(16)));  // 接收描述符环
static struct mbuf *rx_mbufs[RX_RING_SIZE];  // 接收mbuf缓冲区

// remember where the e1000's registers live.  // 记住e1000寄存器的位置
static volatile uint32 *regs;

struct spinlock e1000_lock;  // e1000锁

// called by pci_init().  // 由pci_init()调用
// xregs is the memory address at which the  // xregs是e1000寄存器映射的内存地址
// e1000's registers are mapped.  // e1000的寄存器映射位置
void
e1000_init(uint32 *xregs)
{
  int i;

  initlock(&e1000_lock, "e1000");

  regs = xregs;

  // Reset the device
  regs[E1000_IMS] = 0; // disable interrupts
  regs[E1000_CTL] |= E1000_CTL_RST;
  regs[E1000_IMS] = 0; // redisable interrupts
  __sync_synchronize();

  // [E1000 14.5] Transmit initialization
  memset(tx_ring, 0, sizeof(tx_ring));
  for (i = 0; i < TX_RING_SIZE; i++) {
    tx_ring[i].status = E1000_TXD_STAT_DD;
    tx_mbufs[i] = 0;
  }
  regs[E1000_TDBAL] = (uint64) tx_ring;
  if(sizeof(tx_ring) % 128 != 0)
    panic("e1000");
  regs[E1000_TDLEN] = sizeof(tx_ring);
  regs[E1000_TDH] = regs[E1000_TDT] = 0;
  
  // [E1000 14.4] Receive initialization
  memset(rx_ring, 0, sizeof(rx_ring));
  for (i = 0; i < RX_RING_SIZE; i++) {
    rx_mbufs[i] = mbufalloc(0);
    if (!rx_mbufs[i])
      panic("e1000");
    rx_ring[i].addr = (uint64) rx_mbufs[i]->head;
  }
  regs[E1000_RDBAL] = (uint64) rx_ring;
  if(sizeof(rx_ring) % 128 != 0)
    panic("e1000");
  regs[E1000_RDH] = 0;
  regs[E1000_RDT] = RX_RING_SIZE - 1;
  regs[E1000_RDLEN] = sizeof(rx_ring);

  // filter by qemu's MAC address, 52:54:00:12:34:56
  regs[E1000_RA] = 0x12005452;
  regs[E1000_RA+1] = 0x5634 | (1<<31);
  // multicast table
  for (int i = 0; i < 4096/32; i++)
    regs[E1000_MTA + i] = 0;

  // transmitter control bits.
  regs[E1000_TCTL] = E1000_TCTL_EN |  // enable
    E1000_TCTL_PSP |                  // pad short packets
    (0x10 << E1000_TCTL_CT_SHIFT) |   // collision stuff
    (0x40 << E1000_TCTL_COLD_SHIFT);
  regs[E1000_TIPG] = 10 | (8<<10) | (6<<20); // inter-pkt gap

  // receiver control bits.
  regs[E1000_RCTL] = E1000_RCTL_EN | // enable receiver
    E1000_RCTL_BAM |                 // enable broadcast
    E1000_RCTL_SZ_2048 |             // 2048-byte rx buffers
    E1000_RCTL_SECRC;                // strip CRC
  
  // ask e1000 for receive interrupts.
  regs[E1000_RDTR] = 0; // interrupt after every received packet (no timer)
  regs[E1000_RADV] = 0; // interrupt after every packet (no timer)
  regs[E1000_IMS] = (1 << 7); // RXDW -- Receiver Descriptor Write Back
}

int
e1000_transmit(struct mbuf *m)
{
  //
  // Your code here.  // 你的代码在这里
  //
  // the mbuf contains an ethernet frame; program it into  // mbuf包含一个以太网帧；将其编程到
  // the TX descriptor ring so that the e1000 sends it. Stash  // TX描述符环中，以便e1000发送它。存储
  // a pointer so that it can be freed after sending.  // 一个指针，以便发送后可以释放
  //
  acquire(&e1000_lock);
  //通过读取E1000_TDT控制寄存器，向E1000询问等待下一个数据包的TX环索引。
  int idx =regs[E1000_TDT];

  struct tx_desc *desc = &tx_ring[idx];
  uint8 status = tx_ring[idx].status;
  // 检查环是否溢出。如果E1000_TXD_STAT_DD未在E1000_TDT索引的描述符中设置，则E1000尚未完成先前相应的传输请求，因此返回错误。
  if ((status & E1000_TXD_STAT_DD)==0)
  {
    release(&e1000_lock);
    return -1;
  }

  // 否则，使用mbuffree()释放从该描述符传输的最后一个mbuf（如果有）。
  if(tx_mbufs[idx])
  {
    mbuffree(tx_mbufs[idx]);
    tx_mbufs[idx] = 0;
  }

  // 填写描述符。m->head指向内存中数据包的内容，m->len是数据包的长度。
  // 设置必要的cmd标志（请参阅E1000手册的第3.3节），
  // 并保存指向mbuf的指针，以便稍后释放。
  desc->addr = (uint64) m->head;
  desc->length = m->len;
  desc->cmd = E1000_TXD_CMD_EOP | E1000_TXD_CMD_RS; // EOP: End of Packet, RS: Report Status

  tx_mbufs[idx] = m;

  // 通过将一加到E1000_TDT再对TX_RING_SIZE取模来更新环位置。
  regs[E1000_TDT] = (idx + 1) % TX_RING_SIZE;
  release(&e1000_lock);

  return 0;
}

static void
e1000_recv(void)
{
  //
  // Your code here.  // 你的代码在这里
  //
  // Check for packets that have arrived from the e1000  // 检查从e1000到达的数据包
  // Create and deliver an mbuf for each packet (using net_rx()).  // 为每个数据包创建并传递mbuf（使用net_rx()）
  //
  // acquire(&e1000_lock);
  int idx;
  while(1)
  {
    // 1. 计算下一个要处理的描述符索引 (RDT指向已处理的，所以+1)
    idx = (regs[E1000_RDT]+1)%RX_RING_SIZE;
    //2 .检查该描述符是否有新数据
    struct rx_desc *desc = &rx_ring[idx];
    if((desc->status & E1000_RXD_STAT_DD)==0)
    {
      return;
    }
    // 否则，将mbuf的m->len更新为描述符中报告的长度。使用net_rx()将mbuf传送到网络栈。
    struct mbuf *m = rx_mbufs[idx];
    m->len = desc->length;

    net_rx(m);

    // 然后使用mbufalloc()分配一个新的mbuf，以替换刚刚给net_rx()的mbuf。将其数据指针（m->head）编程到描述符中。将描述符的状态位清除为零。
    if ((rx_mbufs[idx]=mbufalloc(0)) == 0)
    {
       panic("e1000_recv: mbufalloc failed");
    }
    desc->addr = (uint64) rx_mbufs[idx]->head;
    desc->status = 0;

    regs[E1000_RDT] = idx;
  }
} 

void
e1000_intr(void)
{
  // tell the e1000 we've seen this interrupt;  // 告诉e1000我们已经看到了这个中断；
  // without this the e1000 won't raise any  // 没有这个，e1000不会引发任何
  // further interrupts.  // 进一步的中断
  regs[E1000_ICR] = 0xffffffff;

  e1000_recv();
}
