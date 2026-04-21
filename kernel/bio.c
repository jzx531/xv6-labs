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

#define NBUCKET 13
#define HASH(id) ((id) % NBUCKET)

struct hashbuf{
  struct spinlock lock;
  struct buf head;
};

struct {
  struct buf buf[NBUF];        // 缓冲区数组
  struct hashbuf buckets[NBUCKET];
} bcache;

// 初始化缓冲区缓存
void
binit(void)
{
  struct buf *b;

  //初始化每个bucket
  char lockname[16];
  for(int i = 0; i < NBUCKET; i++)
  {
    snprintf(lockname, sizeof(lockname), "bcache%d", i);
    initlock(&bcache.buckets[i].lock, lockname);
    bcache.buckets[i].head.next = &bcache.buckets[i].head;
    bcache.buckets[i].head.prev = &bcache.buckets[i].head;
  }
  
  // 将所有缓冲区插入第一个桶的链表头部之后的位置
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    b->next = bcache.buckets[0].head.next;
    b->prev = &bcache.buckets[0].head;
    initsleeplock(&b->lock, "buffer");
    bcache.buckets[0].head.next->prev = b;
    bcache.buckets[0].head.next = b;
  }
}

// 在缓冲区缓存中查找指定设备上的指定块
// 如果未找到,则分配一个缓冲区
// 无论哪种情况,都返回已加锁的缓冲区
// static struct buf*
// bget(uint dev, uint blockno)
// {
//   struct buf *b;

//   int bid = HASH(blockno);
//   // 先获取 bcache 锁,保护缓存数据结构
//   acquire(&bcache.buckets[bid].lock);

//   // 检查目标块是否已被缓存
//   for(b = bcache.buckets[bid].head.next; b != &bcache.buckets[bid].head; b = b->next){
//     if(b->dev == dev && b->blockno == blockno){
//       // 找到目标缓冲区,增加引用计数
//       b->refcnt++;

//        //更新使用时间戳
//       acquire(&tickslock);
//       b->timestamp = ticks;
//       release(&tickslock);

//       release(&bcache.buckets[bid].lock);
//       // 获取该缓冲区的睡眠锁后返回
//       acquiresleep(&b->lock);
//       return b;
//     }
//   }

//   b = 0;
//   // 未找到缓存
//   // 回收最近最少使用且未被使用的缓冲区
//   for(int i = bid,cycle = 0; cycle < NBUCKET; i= (i+1)%NBUCKET, cycle++)
//   {
//     //访问除自己之外的桶,还要获得对应桶的锁
//     if(i != bid){
//       if(!holding(&bcache.buckets[i].lock))
//       {
//         acquire(&bcache.buckets[i].lock);
//       }
//       else{
//         continue;
//       }
//     }

//     // 遍历桶中所有缓冲区,找到最近最少使用(LRU)且未被使用的缓冲区
//     struct buf *tmp = &bcache.buckets[i].head;
//     for(tmp = tmp->next; tmp != &bcache.buckets[i].head; tmp = tmp->next)
//     {
//       if(tmp->refcnt == 0)
//       {
//         if(b == 0){
//           b = tmp;
//         }else if(tmp->timestamp < b->timestamp){
//           b = tmp;
//         }
//       }
//     }
    

//     if(b){
//       // 找到一个空闲缓冲区,将其分配给目标块
//       // 先将该缓冲区从原来的链表中删除
//       b->prev->next = b->next;
//       b->next->prev = b->prev;
//       if(i != bid && holding(&bcache.buckets[i].lock)){
//         release(&bcache.buckets[i].lock);
//       }
//       // 再将该缓冲区插入到桶的链表头部之后的位置
//       b->next = bcache.buckets[bid].head.next;
//       b->prev = &bcache.buckets[bid].head;
//       bcache.buckets[bid].head.next->prev = b;
//       bcache.buckets[bid].head.next = b;
//       // 增加引用计数
//       b->dev = dev;
//       b->blockno = blockno;
//       b->valid = 0;
//       b->refcnt = 1;
//       // 更新使用时间戳
//       acquire(&tickslock);
//       b->timestamp = ticks;
//       release(&tickslock);

//       // 释放桶锁
//       release(&bcache.buckets[bid].lock);
//       // 获取该缓冲区的睡眠锁后返回
//       acquiresleep(&b->lock);
//       return b;
//     }
//     else{
//       //遍历当前桶循环完毕,释放桶锁
//       if(i != bid && holding(&bcache.buckets[i].lock)){
//         release(&bcache.buckets[i].lock);
//       }
//     }
//   }

//   // 没有可用的缓冲区,系统异常
//   panic("bget: no buffers");
// }

static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  int bid = HASH(blockno);
  // 先获取 bcache 锁,保护缓存数据结构
  acquire(&bcache.buckets[bid].lock);

  // 检查目标块是否已被缓存
  for(b = bcache.buckets[bid].head.next; b != &bcache.buckets[bid].head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      // 找到目标缓冲区,增加引用计数
      b->refcnt++;

       //更新使用时间戳
      acquire(&tickslock);
      b->timestamp = ticks;
      release(&tickslock);

      release(&bcache.buckets[bid].lock);
      // 获取该缓冲区的睡眠锁后返回
      acquiresleep(&b->lock);
      return b;
    }
  }

  b = 0;
  int oldest_bid = bid;
  // 未找到缓存
  // 回收最近最少使用且未被使用的缓冲区
  for(int i = bid,cycle = 0; cycle < NBUCKET; i= (i+1)%NBUCKET, cycle++)
  {
    //访问除自己之外的桶,还要获得对应桶的锁
    if(i != bid){
      if(!holding(&bcache.buckets[i].lock))
      {
        acquire(&bcache.buckets[i].lock);
      }
      else{
        continue;
      }
    }

    // 遍历桶中所有缓冲区,找到最近最少使用(LRU)且未被使用的缓冲区
    struct buf *tmp = &bcache.buckets[i].head;
    // int found = 0;
    for(tmp = tmp->next; tmp != &bcache.buckets[i].head; tmp = tmp->next)
    {
      if(tmp->refcnt == 0)
      {
        // found = 1;
        if(b == 0){
          b = tmp;
          // if(oldest_bid != i &&oldest_bid != bid && holding(&bcache.buckets[oldest_bid].lock))
          // {
          //   release(&bcache.buckets[oldest_bid].lock);
          // }
          oldest_bid = i;
          
        }else if(tmp->timestamp < b->timestamp){
          b = tmp;
          // if(oldest_bid != i && oldest_bid != bid && holding(&bcache.buckets[oldest_bid].lock))
          // {
          //   release(&bcache.buckets[oldest_bid].lock);
          // }
          oldest_bid = i;
        }
      }
    }
    // if(!found)
    // {
      if(i!= bid && holding(&bcache.buckets[i].lock))
      {
        release(&bcache.buckets[i].lock);
      }
    // }
  }
    

  if(b){
    if(!holding(&bcache.buckets[oldest_bid].lock))
    {
      acquire(&bcache.buckets[oldest_bid].lock);
    }
    // 找到一个空闲缓冲区,将其分配给目标块
    // 先将该缓冲区从原来的链表中删除
    b->prev->next = b->next;
    b->next->prev = b->prev;
    if(oldest_bid != bid && holding(&bcache.buckets[oldest_bid].lock)){
      release(&bcache.buckets[oldest_bid].lock);
    }
    // 再将该缓冲区插入到桶的链表头部之后的位置
    b->next = bcache.buckets[bid].head.next;
    b->prev = &bcache.buckets[bid].head;
    bcache.buckets[bid].head.next->prev = b;
    bcache.buckets[bid].head.next = b;
    // 增加引用计数
    b->dev = dev;
    b->blockno = blockno;
    b->valid = 0;
    b->refcnt = 1;
    // 更新使用时间戳
    acquire(&tickslock);
    b->timestamp = ticks;
    release(&tickslock);

    // 释放桶锁
    release(&bcache.buckets[bid].lock);
    // 获取该缓冲区的睡眠锁后返回
    acquiresleep(&b->lock);
    return b;
  }
  // else{
  //   for(int i = 0; i < NBUCKET; i++)
  //   {
  //     if(i != bid && holding(&bcache.buckets[i].lock))
  //     {
  //       release(&bcache.buckets[i].lock);
  //     }
  //   }
  // }

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

  //通过块号获取桶索引
  int bid =HASH(b->blockno);
  // 释放睡眠锁
  releasesleep(&b->lock);

  // 获取 bcache 锁以修改引用计数和链表
  acquire(&bcache.buckets[bid].lock);
  b->refcnt--;
  
  //不再使用双向链表LRU而是记录时间戳
  // 记录时间戳
  acquire(&tickslock);
  b->timestamp = ticks;
  release(&tickslock);
  
  release(&bcache.buckets[bid].lock);
}

// 固定缓冲区,增加引用计数,防止被回收
// 用于内核需要长期持有缓冲区的情况(如日志子系统)
void
bpin(struct buf *b) {
  int bid = HASH(b->blockno);
  acquire(&bcache.buckets[bid].lock);
  b->refcnt++;
  release(&bcache.buckets[bid].lock);
}

// 解除固定缓冲区,减少引用计数
// 允许缓冲区在被回收时重新使用
void
bunpin(struct buf *b) {
  int bid = HASH(b->blockno);
  acquire(&bcache.buckets[bid].lock);
  b->refcnt--;
  release(&bcache.buckets[bid].lock);
}


