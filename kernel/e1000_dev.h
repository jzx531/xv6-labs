//
// E1000 hardware definitions: registers and DMA ring format.
// from the Intel 82540EP/EM &c manual.
// E1000硬件定义：寄存器和DMA环格式。
// 来自Intel 82540EP/EM等手册。
//

/* Registers */  // 寄存器
#define E1000_CTL      (0x00000/4)  /* Device Control Register - RW */  // 设备控制寄存器 - 读写
#define E1000_ICR      (0x000C0/4)  /* Interrupt Cause Read - R */  // 中断原因读取 - 只读
#define E1000_IMS      (0x000D0/4)  /* Interrupt Mask Set - RW */  // 中断掩码设置 - 读写
#define E1000_RCTL     (0x00100/4)  /* RX Control - RW */  // 接收控制 - 读写
#define E1000_TCTL     (0x00400/4)  /* TX Control - RW */  // 发送控制 - 读写
#define E1000_TIPG     (0x00410/4)  /* TX Inter-packet gap -RW */  // 发送包间隙 - 读写
#define E1000_RDBAL    (0x02800/4)  /* RX Descriptor Base Address Low - RW */  // 接收描述符基地址低位 - 读写
#define E1000_RDTR     (0x02820/4)  /* RX Delay Timer */  // 接收延迟定时器
#define E1000_RADV     (0x0282C/4)  /* RX Interrupt Absolute Delay Timer */  // 接收中断绝对延迟定时器
#define E1000_RDH      (0x02810/4)  /* RX Descriptor Head - RW */  // 接收描述符头 - 读写
#define E1000_RDT      (0x02818/4)  /* RX Descriptor Tail - RW */  // 接收描述符尾 - 读写
#define E1000_RDLEN    (0x02808/4)  /* RX Descriptor Length - RW */  // 接收描述符长度 - 读写
#define E1000_RSRPD    (0x02C00/4)  /* RX Small Packet Detect Interrupt */  // 接收小包检测中断
#define E1000_TDBAL    (0x03800/4)  /* TX Descriptor Base Address Low - RW */  // 发送描述符基地址低位 - 读写
#define E1000_TDLEN    (0x03808/4)  /* TX Descriptor Length - RW */  // 发送描述符长度 - 读写
#define E1000_TDH      (0x03810/4)  /* TX Descriptor Head - RW */  // 发送描述符头 - 读写
#define E1000_TDT      (0x03818/4)  /* TX Descripotr Tail - RW */  // 发送描述符尾 - 读写
#define E1000_MTA      (0x05200/4)  /* Multicast Table Array - RW Array */  // 多播表数组 - 读写数组
#define E1000_RA       (0x05400/4)  /* Receive Address - RW Array */  // 接收地址 - 读写数组

/* Device Control */  // 设备控制
#define E1000_CTL_SLU     0x00000040    /* set link up */  // 设置链路启动
#define E1000_CTL_FRCSPD  0x00000800    /* force speed */  // 强制速度
#define E1000_CTL_FRCDPLX 0x00001000    /* force duplex */  // 强制双工
#define E1000_CTL_RST     0x00400000    /* full reset */  // 完全重置

/* Transmit Control */  // 发送控制
#define E1000_TCTL_RST    0x00000001    /* software reset */  // 软件重置
#define E1000_TCTL_EN     0x00000002    /* enable tx */  // 启用发送
#define E1000_TCTL_BCE    0x00000004    /* busy check enable */  // 忙碌检查启用
#define E1000_TCTL_PSP    0x00000008    /* pad short packets */  // 填充短包
#define E1000_TCTL_CT     0x00000ff0    /* collision threshold */  // 碰撞阈值
#define E1000_TCTL_CT_SHIFT 4
#define E1000_TCTL_COLD   0x003ff000    /* collision distance */  // 碰撞距离
#define E1000_TCTL_COLD_SHIFT 12
#define E1000_TCTL_SWXOFF 0x00400000    /* SW Xoff transmission */  // SW Xoff传输
#define E1000_TCTL_PBE    0x00800000    /* Packet Burst Enable */  // 数据包突发启用
#define E1000_TCTL_RTLC   0x01000000    /* Re-transmit on late collision */  // 晚碰撞重传
#define E1000_TCTL_NRTU   0x02000000    /* No Re-transmit on underrun */  // 欠载不重传
#define E1000_TCTL_MULR   0x10000000    /* Multiple request support */  // 多请求支持

/* Receive Control */  // 接收控制
#define E1000_RCTL_RST            0x00000001    /* Software reset */  // 软件重置
#define E1000_RCTL_EN             0x00000002    /* enable */  // 启用
#define E1000_RCTL_SBP            0x00000004    /* store bad packet */  // 存储坏包
#define E1000_RCTL_UPE            0x00000008    /* unicast promiscuous enable */  // 单播混杂启用
#define E1000_RCTL_MPE            0x00000010    /* multicast promiscuous enab */  // 多播混杂启用
#define E1000_RCTL_LPE            0x00000020    /* long packet enable */  // 长包启用
#define E1000_RCTL_LBM_NO         0x00000000    /* no loopback mode */  // 无环回模式
#define E1000_RCTL_LBM_MAC        0x00000040    /* MAC loopback mode */  // MAC环回模式
#define E1000_RCTL_LBM_SLP        0x00000080    /* serial link loopback mode */  // 串行链路环回模式
#define E1000_RCTL_LBM_TCVR       0x000000C0    /* tcvr loopback mode */  // tcvr环回模式
#define E1000_RCTL_DTYP_MASK      0x00000C00    /* Descriptor type mask */  // 描述符类型掩码
#define E1000_RCTL_DTYP_PS        0x00000400    /* Packet Split descriptor */  // 数据包分割描述符
#define E1000_RCTL_RDMTS_HALF     0x00000000    /* rx desc min threshold size */  // 接收描述符最小阈值大小
#define E1000_RCTL_RDMTS_QUAT     0x00000100    /* rx desc min threshold size */  // 接收描述符最小阈值大小
#define E1000_RCTL_RDMTS_EIGTH    0x00000200    /* rx desc min threshold size */  // 接收描述符最小阈值大小
#define E1000_RCTL_MO_SHIFT       12            /* multicast offset shift */  // 多播偏移移位
#define E1000_RCTL_MO_0           0x00000000    /* multicast offset 11:0 */  // 多播偏移 11:0
#define E1000_RCTL_MO_1           0x00001000    /* multicast offset 12:1 */  // 多播偏移 12:1
#define E1000_RCTL_MO_2           0x00002000    /* multicast offset 13:2 */  // 多播偏移 13:2
#define E1000_RCTL_MO_3           0x00003000    /* multicast offset 15:4 */  // 多播偏移 15:4
#define E1000_RCTL_MDR            0x00004000    /* multicast desc ring 0 */  // 多播描述符环 0
#define E1000_RCTL_BAM            0x00008000    /* broadcast enable */  // 广播启用
/* these buffer sizes are valid if E1000_RCTL_BSEX is 0 */  // 如果E1000_RCTL_BSEX为0，这些缓冲区大小有效
#define E1000_RCTL_SZ_2048        0x00000000    /* rx buffer size 2048 */  // 接收缓冲区大小 2048
#define E1000_RCTL_SZ_1024        0x00010000    /* rx buffer size 1024 */  // 接收缓冲区大小 1024
#define E1000_RCTL_SZ_512         0x00020000    /* rx buffer size 512 */  // 接收缓冲区大小 512
#define E1000_RCTL_SZ_256         0x00030000    /* rx buffer size 256 */  // 接收缓冲区大小 256
/* these buffer sizes are valid if E1000_RCTL_BSEX is 1 */  // 如果E1000_RCTL_BSEX为1，这些缓冲区大小有效
#define E1000_RCTL_SZ_16384       0x00010000    /* rx buffer size 16384 */  // 接收缓冲区大小 16384
#define E1000_RCTL_SZ_8192        0x00020000    /* rx buffer size 8192 */  // 接收缓冲区大小 8192
#define E1000_RCTL_SZ_4096        0x00030000    /* rx buffer size 4096 */  // 接收缓冲区大小 4096
#define E1000_RCTL_VFE            0x00040000    /* vlan filter enable */  // VLAN过滤启用
#define E1000_RCTL_CFIEN          0x00080000    /* canonical form enable */  // 规范形式启用
#define E1000_RCTL_CFI            0x00100000    /* canonical form indicator */  // 规范形式指示器
#define E1000_RCTL_DPF            0x00400000    /* discard pause frames */  // 丢弃暂停帧
#define E1000_RCTL_PMCF           0x00800000    /* pass MAC control frames */  // 传递MAC控制帧
#define E1000_RCTL_BSEX           0x02000000    /* Buffer size extension */  // 缓冲区大小扩展
#define E1000_RCTL_SECRC          0x04000000    /* Strip Ethernet CRC */  // 剥离以太网CRC
#define E1000_RCTL_FLXBUF_MASK    0x78000000    /* Flexible buffer size */  // 灵活缓冲区大小
#define E1000_RCTL_FLXBUF_SHIFT   27            /* Flexible buffer shift */  // 灵活缓冲区移位

#define DATA_MAX 1518  // 数据最大值

/* Transmit Descriptor command definitions [E1000 3.3.3.1] */  // 发送描述符命令定义 [E1000 3.3.3.1]
#define E1000_TXD_CMD_EOP    0x01 /* End of Packet */  // 数据包结束
#define E1000_TXD_CMD_RS     0x08 /* Report Status */  // 报告状态

/* Transmit Descriptor status definitions [E1000 3.3.3.2] */  // 发送描述符状态定义 [E1000 3.3.3.2]
#define E1000_TXD_STAT_DD    0x00000001 /* Descriptor Done */  // 描述符完成

// [E1000 3.3.3]  // 发送描述符结构体
struct tx_desc
{
  uint64 addr;  // 地址
  uint16 length;  // 长度
  uint8 cso;  // 校验和偏移
  uint8 cmd;  // 命令
  uint8 status;  // 状态
  uint8 css;  // 校验和开始
  uint16 special;  // 特殊
};

/* Receive Descriptor bit definitions [E1000 3.2.3.1] */  // 接收描述符位定义 [E1000 3.2.3.1]
#define E1000_RXD_STAT_DD       0x01    /* Descriptor Done */  // 描述符完成
#define E1000_RXD_STAT_EOP      0x02    /* End of Packet */  // 数据包结束

// [E1000 3.2.3]  // 接收描述符结构体
struct rx_desc
{
  uint64 addr;       /* Address of the descriptor's data buffer */  // 描述符数据缓冲区的地址
  uint16 length;     /* Length of data DMAed into data buffer */  // DMA到数据缓冲区的数据长度
  uint16 csum;       /* Packet checksum */  // 数据包校验和
  uint8 status;      /* Descriptor status */  // 描述符状态
  uint8 errors;      /* Descriptor Errors */  // 描述符错误
  uint16 special;  // 特殊
};

