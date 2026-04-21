// 缓冲区缓存 (Buffer Cache)
//
// 缓冲区缓存是一个由 buf 结构体组成的链表,用于保存磁盘块内容的缓存副本.
// 将磁盘块缓存在内存中可以减少磁盘读取次数,同时也为多个进程共享的磁盘块
// 提供同步点.
//
// 接口说明:
// * 要获取特定磁盘块的缓冲区,请调用 bread.
// * 修改缓冲区数据后,调用 bwrite 将其写入磁盘.
// * 使用完缓冲区后,调用 brelse 释放.
// * 调用 brelse 后请勿继续使用该缓冲区.
// * 同一时间只能有一个进程使用缓冲区,因此不要长时间保留缓冲区.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

struct {
  struct spinlock lock;        // 保护缓冲区缓存的自旋锁
  struct buf buf[NBUF];        // 缓冲区数组

  // 通过 prev/next 指针链接所有缓冲区形成的链表
  // 按最近使用时间排序: head.next 是最近使用的, head.prev 是最久未使用的
  struct buf head;             // 链表头节点(哨兵节点)
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
  struct buf *b;

  // 初始化 bcache 自旋锁
  initlock(&bcache.lock, "bcache");

  // 创建缓冲区链表(双向循环链表)
  // 初始化哨兵节点,使其指向自身
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  
  // 将所有缓冲区插入链表头部之后的位置
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    b->next = bcache.head.next;    // 新节点指向原第一个节点
    b->prev = &bcache.head;        // 新节点前驱指向哨兵节点
    initsleeplock(&b->lock, "buffer");  // 初始化每个缓冲区的睡眠锁
    bcache.head.next->prev = b;    // 原首节点的前驱指向新节点
    bcache.head.next = b;          // 哨兵节点的后继指向新节点
  }
}

// 在缓冲区缓存中查找指定设备上的指定块
// 如果未找到,则分配一个缓冲区
// 无论哪种情况,都返回已加锁的缓冲区
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  // 先获取 bcache 锁,保护缓存数据结构
  acquire(&bcache.lock);

  // 检查目标块是否已被缓存
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      // 找到目标缓冲区,增加引用计数
      b->refcnt++;
      release(&bcache.lock);
      // 获取该缓冲区的睡眠锁后返回
      acquiresleep(&b->lock);
      return b;
    }
  }

  // 未找到缓存
  // 回收最近最少使用(LRU)且未被使用的缓冲区
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    if(b->refcnt == 0) {
      // 重置缓冲区内容,标记为无效
      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  // 没有可用的缓冲区,系统异常
  panic("bget: no buffers");
}

// 返回包含指定块内容的已加锁缓冲区
// 如果缓冲区数据无效,则从磁盘读取数据
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  // 如果缓冲区数据无效,从磁盘读取
  if(!b->valid) {
    virtio_disk_rw(b, 0);  // 0 表示读取操作
    b->valid = 1;
  }
  return b;
}

// 将缓冲区内容写入磁盘,缓冲区必须已加锁
void
bwrite(struct buf *b)
{
  // 检查是否持有该缓冲区的睡眠锁
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  // 1 表示写入操作
  virtio_disk_rw(b, 1);
}

// 释放已加锁的缓冲区
// 将该缓冲区移动到最近使用列表的头部
void
brelse(struct buf *b)
{
  // 检查是否持有该缓冲区的睡眠锁
  if(!holdingsleep(&b->lock))
    panic("brelse");

  // 释放睡眠锁
  releasesleep(&b->lock);

  // 获取 bcache 锁以修改引用计数和链表
  acquire(&bcache.lock);
  b->refcnt--;
  
  // 如果没有进程在使用该缓冲区,则将其移到链表头部(MRU 位置)
  if (b->refcnt == 0) {
    // 从原位置移除
    b->next->prev = b->prev;
    b->prev->next = b->next;
    // 插入到链表头部(最近使用位置)
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
  
  release(&bcache.lock);
}

// 固定缓冲区,增加引用计数,防止被回收
// 用于内核需要长期持有缓冲区的情况(如日志子系统)
void
bpin(struct buf *b) {
  acquire(&bcache.lock);
  b->refcnt++;
  release(&bcache.lock);
}

// 解除固定缓冲区,减少引用计数
// 允许缓冲区在被回收时重新使用
void
bunpin(struct buf *b) {
  acquire(&bcache.lock);
  b->refcnt--;
  release(&bcache.lock);
}


