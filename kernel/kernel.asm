
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	df478793          	addi	a5,a5,-524 # 80005e50 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	f4e78793          	addi	a5,a5,-178 # 80000ff4 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	c3e080e7          	jalr	-962(ra) # 80000d4a <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	5fa080e7          	jalr	1530(ra) # 80002720 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	cb0080e7          	jalr	-848(ra) # 80000dfe <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	bae080e7          	jalr	-1106(ra) # 80000d4a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	a92080e7          	jalr	-1390(ra) # 80001c5c <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	296080e7          	jalr	662(ra) # 80002470 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	4b4080e7          	jalr	1204(ra) # 800026ca <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	bcc080e7          	jalr	-1076(ra) # 80000dfe <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	bb6080e7          	jalr	-1098(ra) # 80000dfe <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	a72080e7          	jalr	-1422(ra) # 80000d4a <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	480080e7          	jalr	1152(ra) # 80002776 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	af8080e7          	jalr	-1288(ra) # 80000dfe <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	1a6080e7          	jalr	422(ra) # 800025f0 <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00001097          	auipc	ra,0x1
    80000470:	84e080e7          	jalr	-1970(ra) # 80000cba <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00241797          	auipc	a5,0x241
    80000480:	54c78793          	addi	a5,a5,1356 # 802419c8 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b6050513          	addi	a0,a0,-1184 # 800080d0 <digits+0x90>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	746080e7          	jalr	1862(ra) # 80000d4a <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	69c080e7          	jalr	1692(ra) # 80000dfe <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	532080e7          	jalr	1330(ra) # 80000cba <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	4dc080e7          	jalr	1244(ra) # 80000cba <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	504080e7          	jalr	1284(ra) # 80000cfe <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	576080e7          	jalr	1398(ra) # 80000d9e <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	d4e080e7          	jalr	-690(ra) # 800025f0 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	464080e7          	jalr	1124(ra) # 80000d4a <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	b34080e7          	jalr	-1228(ra) # 80002470 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	47c080e7          	jalr	1148(ra) # 80000dfe <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	35c080e7          	jalr	860(ra) # 80000d4a <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	3fe080e7          	jalr	1022(ra) # 80000dfe <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebd9                	bnez	a5,80000ab8 <kfree+0xa6>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00245797          	auipc	a5,0x245
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80246000 <end>
    80000a2e:	08f56563          	bltu	a0,a5,80000ab8 <kfree+0xa6>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	08f57163          	bgeu	a0,a5,80000ab8 <kfree+0xa6>
    panic("kfree");

  //修改为以释放页的引用计数来考虑释放页
  acquire(&ref.lock);
    80000a3a:	00011517          	auipc	a0,0x11
    80000a3e:	f1650513          	addi	a0,a0,-234 # 80011950 <ref>
    80000a42:	00000097          	auipc	ra,0x0
    80000a46:	308080e7          	jalr	776(ra) # 80000d4a <acquire>
  if(--ref.cnt[(uint64)pa / PGSIZE] == 0)
    80000a4a:	00c4d793          	srli	a5,s1,0xc
    80000a4e:	0791                	addi	a5,a5,4
    80000a50:	078a                	slli	a5,a5,0x2
    80000a52:	00011717          	auipc	a4,0x11
    80000a56:	efe70713          	addi	a4,a4,-258 # 80011950 <ref>
    80000a5a:	97ba                	add	a5,a5,a4
    80000a5c:	4798                	lw	a4,8(a5)
    80000a5e:	377d                	addiw	a4,a4,-1
    80000a60:	0007069b          	sext.w	a3,a4
    80000a64:	c798                	sw	a4,8(a5)
    80000a66:	e2ad                	bnez	a3,80000ac8 <kfree+0xb6>
  {
    release(&ref.lock);
    80000a68:	00011517          	auipc	a0,0x11
    80000a6c:	ee850513          	addi	a0,a0,-280 # 80011950 <ref>
    80000a70:	00000097          	auipc	ra,0x0
    80000a74:	38e080e7          	jalr	910(ra) # 80000dfe <release>
    r = (struct run*)pa;

     // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a78:	6605                	lui	a2,0x1
    80000a7a:	4585                	li	a1,1
    80000a7c:	8526                	mv	a0,s1
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	3c8080e7          	jalr	968(ra) # 80000e46 <memset>

    acquire(&kmem.lock);
    80000a86:	00011917          	auipc	s2,0x11
    80000a8a:	eaa90913          	addi	s2,s2,-342 # 80011930 <kmem>
    80000a8e:	854a                	mv	a0,s2
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	2ba080e7          	jalr	698(ra) # 80000d4a <acquire>
    r->next = kmem.freelist;
    80000a98:	01893783          	ld	a5,24(s2)
    80000a9c:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a9e:	00993c23          	sd	s1,24(s2)
    release(&kmem.lock);
    80000aa2:	854a                	mv	a0,s2
    80000aa4:	00000097          	auipc	ra,0x0
    80000aa8:	35a080e7          	jalr	858(ra) # 80000dfe <release>
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
  */
}
    80000aac:	60e2                	ld	ra,24(sp)
    80000aae:	6442                	ld	s0,16(sp)
    80000ab0:	64a2                	ld	s1,8(sp)
    80000ab2:	6902                	ld	s2,0(sp)
    80000ab4:	6105                	addi	sp,sp,32
    80000ab6:	8082                	ret
    panic("kfree");
    80000ab8:	00007517          	auipc	a0,0x7
    80000abc:	5a850513          	addi	a0,a0,1448 # 80008060 <digits+0x20>
    80000ac0:	00000097          	auipc	ra,0x0
    80000ac4:	a82080e7          	jalr	-1406(ra) # 80000542 <panic>
    release(&ref.lock);
    80000ac8:	00011517          	auipc	a0,0x11
    80000acc:	e8850513          	addi	a0,a0,-376 # 80011950 <ref>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	32e080e7          	jalr	814(ra) # 80000dfe <release>
}
    80000ad8:	bfd1                	j	80000aac <kfree+0x9a>

0000000080000ada <freerange>:
{
    80000ada:	7139                	addi	sp,sp,-64
    80000adc:	fc06                	sd	ra,56(sp)
    80000ade:	f822                	sd	s0,48(sp)
    80000ae0:	f426                	sd	s1,40(sp)
    80000ae2:	f04a                	sd	s2,32(sp)
    80000ae4:	ec4e                	sd	s3,24(sp)
    80000ae6:	e852                	sd	s4,16(sp)
    80000ae8:	e456                	sd	s5,8(sp)
    80000aea:	e05a                	sd	s6,0(sp)
    80000aec:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aee:	6785                	lui	a5,0x1
    80000af0:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000af4:	9526                	add	a0,a0,s1
    80000af6:	74fd                	lui	s1,0xfffff
    80000af8:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000afa:	97a6                	add	a5,a5,s1
    80000afc:	02f5eb63          	bltu	a1,a5,80000b32 <freerange+0x58>
    80000b00:	892e                	mv	s2,a1
    ref.cnt[(uint64)p / PGSIZE] = 1; // 初始化时先设为1，以便 kfree 能正确释放到空闲链
    80000b02:	00011b17          	auipc	s6,0x11
    80000b06:	e4eb0b13          	addi	s6,s6,-434 # 80011950 <ref>
    80000b0a:	4a85                	li	s5,1
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b0c:	6a05                	lui	s4,0x1
    80000b0e:	6989                	lui	s3,0x2
    ref.cnt[(uint64)p / PGSIZE] = 1; // 初始化时先设为1，以便 kfree 能正确释放到空闲链
    80000b10:	00c4d793          	srli	a5,s1,0xc
    80000b14:	0791                	addi	a5,a5,4
    80000b16:	078a                	slli	a5,a5,0x2
    80000b18:	97da                	add	a5,a5,s6
    80000b1a:	0157a423          	sw	s5,8(a5)
    kfree(p);
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	ef2080e7          	jalr	-270(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000b28:	87a6                	mv	a5,s1
    80000b2a:	94d2                	add	s1,s1,s4
    80000b2c:	97ce                	add	a5,a5,s3
    80000b2e:	fef971e3          	bgeu	s2,a5,80000b10 <freerange+0x36>
}
    80000b32:	70e2                	ld	ra,56(sp)
    80000b34:	7442                	ld	s0,48(sp)
    80000b36:	74a2                	ld	s1,40(sp)
    80000b38:	7902                	ld	s2,32(sp)
    80000b3a:	69e2                	ld	s3,24(sp)
    80000b3c:	6a42                	ld	s4,16(sp)
    80000b3e:	6aa2                	ld	s5,8(sp)
    80000b40:	6b02                	ld	s6,0(sp)
    80000b42:	6121                	addi	sp,sp,64
    80000b44:	8082                	ret

0000000080000b46 <kinit>:
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e406                	sd	ra,8(sp)
    80000b4a:	e022                	sd	s0,0(sp)
    80000b4c:	0800                	addi	s0,sp,16
  initlock(&ref.lock, "ref");
    80000b4e:	00007597          	auipc	a1,0x7
    80000b52:	51a58593          	addi	a1,a1,1306 # 80008068 <digits+0x28>
    80000b56:	00011517          	auipc	a0,0x11
    80000b5a:	dfa50513          	addi	a0,a0,-518 # 80011950 <ref>
    80000b5e:	00000097          	auipc	ra,0x0
    80000b62:	15c080e7          	jalr	348(ra) # 80000cba <initlock>
  initlock(&kmem.lock, "kmem");
    80000b66:	00007597          	auipc	a1,0x7
    80000b6a:	50a58593          	addi	a1,a1,1290 # 80008070 <digits+0x30>
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	144080e7          	jalr	324(ra) # 80000cba <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b7e:	45c5                	li	a1,17
    80000b80:	05ee                	slli	a1,a1,0x1b
    80000b82:	00245517          	auipc	a0,0x245
    80000b86:	47e50513          	addi	a0,a0,1150 # 80246000 <end>
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	f50080e7          	jalr	-176(ra) # 80000ada <freerange>
}
    80000b92:	60a2                	ld	ra,8(sp)
    80000b94:	6402                	ld	s0,0(sp)
    80000b96:	0141                	addi	sp,sp,16
    80000b98:	8082                	ret

0000000080000b9a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b9a:	1101                	addi	sp,sp,-32
    80000b9c:	ec06                	sd	ra,24(sp)
    80000b9e:	e822                	sd	s0,16(sp)
    80000ba0:	e426                	sd	s1,8(sp)
    80000ba2:	e04a                	sd	s2,0(sp)
    80000ba4:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000ba6:	00011497          	auipc	s1,0x11
    80000baa:	d8a48493          	addi	s1,s1,-630 # 80011930 <kmem>
    80000bae:	8526                	mv	a0,s1
    80000bb0:	00000097          	auipc	ra,0x0
    80000bb4:	19a080e7          	jalr	410(ra) # 80000d4a <acquire>
  r = kmem.freelist;
    80000bb8:	6c84                	ld	s1,24(s1)
  if(r) {
    80000bba:	c0b5                	beqz	s1,80000c1e <kalloc+0x84>
    kmem.freelist = r->next;
    80000bbc:	609c                	ld	a5,0(s1)
    80000bbe:	00011917          	auipc	s2,0x11
    80000bc2:	d7290913          	addi	s2,s2,-654 # 80011930 <kmem>
    80000bc6:	00f93c23          	sd	a5,24(s2)
    acquire(&ref.lock);
    80000bca:	00011517          	auipc	a0,0x11
    80000bce:	d8650513          	addi	a0,a0,-634 # 80011950 <ref>
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	178080e7          	jalr	376(ra) # 80000d4a <acquire>
    ref.cnt[(uint64)r / PGSIZE] = 1;  // 将引用计数初始化为1
    80000bda:	00011517          	auipc	a0,0x11
    80000bde:	d7650513          	addi	a0,a0,-650 # 80011950 <ref>
    80000be2:	00c4d793          	srli	a5,s1,0xc
    80000be6:	0791                	addi	a5,a5,4
    80000be8:	078a                	slli	a5,a5,0x2
    80000bea:	97aa                	add	a5,a5,a0
    80000bec:	4705                	li	a4,1
    80000bee:	c798                	sw	a4,8(a5)
    release(&ref.lock);
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	20e080e7          	jalr	526(ra) # 80000dfe <release>
  }
  release(&kmem.lock);
    80000bf8:	854a                	mv	a0,s2
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	204080e7          	jalr	516(ra) # 80000dfe <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c02:	6605                	lui	a2,0x1
    80000c04:	4595                	li	a1,5
    80000c06:	8526                	mv	a0,s1
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	23e080e7          	jalr	574(ra) # 80000e46 <memset>
  return (void*)r;
}
    80000c10:	8526                	mv	a0,s1
    80000c12:	60e2                	ld	ra,24(sp)
    80000c14:	6442                	ld	s0,16(sp)
    80000c16:	64a2                	ld	s1,8(sp)
    80000c18:	6902                	ld	s2,0(sp)
    80000c1a:	6105                	addi	sp,sp,32
    80000c1c:	8082                	ret
  release(&kmem.lock);
    80000c1e:	00011517          	auipc	a0,0x11
    80000c22:	d1250513          	addi	a0,a0,-750 # 80011930 <kmem>
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	1d8080e7          	jalr	472(ra) # 80000dfe <release>
  if(r)
    80000c2e:	b7cd                	j	80000c10 <kalloc+0x76>

0000000080000c30 <krefcnt>:
/**
 * @brief krefcnt 获取内存的引用计数
 * @param pa 指定的内存地址
 * @return 引用计数
 */
int krefcnt(void* pa) {
    80000c30:	1141                	addi	sp,sp,-16
    80000c32:	e422                	sd	s0,8(sp)
    80000c34:	0800                	addi	s0,sp,16
  return ref.cnt[(uint64)pa / PGSIZE];
    80000c36:	8131                	srli	a0,a0,0xc
    80000c38:	0511                	addi	a0,a0,4
    80000c3a:	050a                	slli	a0,a0,0x2
    80000c3c:	00011797          	auipc	a5,0x11
    80000c40:	d1478793          	addi	a5,a5,-748 # 80011950 <ref>
    80000c44:	953e                	add	a0,a0,a5
}
    80000c46:	4508                	lw	a0,8(a0)
    80000c48:	6422                	ld	s0,8(sp)
    80000c4a:	0141                	addi	sp,sp,16
    80000c4c:	8082                	ret

0000000080000c4e <kaddrefcnt>:
 * @brief krefinc 增加内存的引用计数
 * @param pa 指定的内存地址
 * @return 引用计数
*/
int kaddrefcnt(void* pa) {
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000c4e:	03451793          	slli	a5,a0,0x34
    80000c52:	efb1                	bnez	a5,80000cae <kaddrefcnt+0x60>
int kaddrefcnt(void* pa) {
    80000c54:	1101                	addi	sp,sp,-32
    80000c56:	ec06                	sd	ra,24(sp)
    80000c58:	e822                	sd	s0,16(sp)
    80000c5a:	e426                	sd	s1,8(sp)
    80000c5c:	1000                	addi	s0,sp,32
    80000c5e:	84aa                	mv	s1,a0
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000c60:	00245797          	auipc	a5,0x245
    80000c64:	3a078793          	addi	a5,a5,928 # 80246000 <end>
    80000c68:	04f56563          	bltu	a0,a5,80000cb2 <kaddrefcnt+0x64>
    80000c6c:	47c5                	li	a5,17
    80000c6e:	07ee                	slli	a5,a5,0x1b
    80000c70:	04f57363          	bgeu	a0,a5,80000cb6 <kaddrefcnt+0x68>
    return -1;
  acquire(&ref.lock);
    80000c74:	00011517          	auipc	a0,0x11
    80000c78:	cdc50513          	addi	a0,a0,-804 # 80011950 <ref>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	0ce080e7          	jalr	206(ra) # 80000d4a <acquire>
  ++ref.cnt[(uint64)pa / PGSIZE];
    80000c84:	80b1                	srli	s1,s1,0xc
    80000c86:	00011517          	auipc	a0,0x11
    80000c8a:	cca50513          	addi	a0,a0,-822 # 80011950 <ref>
    80000c8e:	0491                	addi	s1,s1,4
    80000c90:	048a                	slli	s1,s1,0x2
    80000c92:	94aa                	add	s1,s1,a0
    80000c94:	449c                	lw	a5,8(s1)
    80000c96:	2785                	addiw	a5,a5,1
    80000c98:	c49c                	sw	a5,8(s1)
  release(&ref.lock);
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	164080e7          	jalr	356(ra) # 80000dfe <release>
  return 0;
    80000ca2:	4501                	li	a0,0
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    return -1;
    80000cae:	557d                	li	a0,-1
}
    80000cb0:	8082                	ret
    return -1;
    80000cb2:	557d                	li	a0,-1
    80000cb4:	bfc5                	j	80000ca4 <kaddrefcnt+0x56>
    80000cb6:	557d                	li	a0,-1
    80000cb8:	b7f5                	j	80000ca4 <kaddrefcnt+0x56>

0000000080000cba <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cba:	1141                	addi	sp,sp,-16
    80000cbc:	e422                	sd	s0,8(sp)
    80000cbe:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cc0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cc2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cc6:	00053823          	sd	zero,16(a0)
}
    80000cca:	6422                	ld	s0,8(sp)
    80000ccc:	0141                	addi	sp,sp,16
    80000cce:	8082                	ret

0000000080000cd0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cd0:	411c                	lw	a5,0(a0)
    80000cd2:	e399                	bnez	a5,80000cd8 <holding+0x8>
    80000cd4:	4501                	li	a0,0
  return r;
}
    80000cd6:	8082                	ret
{
    80000cd8:	1101                	addi	sp,sp,-32
    80000cda:	ec06                	sd	ra,24(sp)
    80000cdc:	e822                	sd	s0,16(sp)
    80000cde:	e426                	sd	s1,8(sp)
    80000ce0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ce2:	6904                	ld	s1,16(a0)
    80000ce4:	00001097          	auipc	ra,0x1
    80000ce8:	f5c080e7          	jalr	-164(ra) # 80001c40 <mycpu>
    80000cec:	40a48533          	sub	a0,s1,a0
    80000cf0:	00153513          	seqz	a0,a0
}
    80000cf4:	60e2                	ld	ra,24(sp)
    80000cf6:	6442                	ld	s0,16(sp)
    80000cf8:	64a2                	ld	s1,8(sp)
    80000cfa:	6105                	addi	sp,sp,32
    80000cfc:	8082                	ret

0000000080000cfe <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cfe:	1101                	addi	sp,sp,-32
    80000d00:	ec06                	sd	ra,24(sp)
    80000d02:	e822                	sd	s0,16(sp)
    80000d04:	e426                	sd	s1,8(sp)
    80000d06:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d08:	100024f3          	csrr	s1,sstatus
    80000d0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d10:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d12:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d16:	00001097          	auipc	ra,0x1
    80000d1a:	f2a080e7          	jalr	-214(ra) # 80001c40 <mycpu>
    80000d1e:	5d3c                	lw	a5,120(a0)
    80000d20:	cf89                	beqz	a5,80000d3a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d22:	00001097          	auipc	ra,0x1
    80000d26:	f1e080e7          	jalr	-226(ra) # 80001c40 <mycpu>
    80000d2a:	5d3c                	lw	a5,120(a0)
    80000d2c:	2785                	addiw	a5,a5,1
    80000d2e:	dd3c                	sw	a5,120(a0)
}
    80000d30:	60e2                	ld	ra,24(sp)
    80000d32:	6442                	ld	s0,16(sp)
    80000d34:	64a2                	ld	s1,8(sp)
    80000d36:	6105                	addi	sp,sp,32
    80000d38:	8082                	ret
    mycpu()->intena = old;
    80000d3a:	00001097          	auipc	ra,0x1
    80000d3e:	f06080e7          	jalr	-250(ra) # 80001c40 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d42:	8085                	srli	s1,s1,0x1
    80000d44:	8885                	andi	s1,s1,1
    80000d46:	dd64                	sw	s1,124(a0)
    80000d48:	bfe9                	j	80000d22 <push_off+0x24>

0000000080000d4a <acquire>:
{
    80000d4a:	1101                	addi	sp,sp,-32
    80000d4c:	ec06                	sd	ra,24(sp)
    80000d4e:	e822                	sd	s0,16(sp)
    80000d50:	e426                	sd	s1,8(sp)
    80000d52:	1000                	addi	s0,sp,32
    80000d54:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d56:	00000097          	auipc	ra,0x0
    80000d5a:	fa8080e7          	jalr	-88(ra) # 80000cfe <push_off>
  if(holding(lk))
    80000d5e:	8526                	mv	a0,s1
    80000d60:	00000097          	auipc	ra,0x0
    80000d64:	f70080e7          	jalr	-144(ra) # 80000cd0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d68:	4705                	li	a4,1
  if(holding(lk))
    80000d6a:	e115                	bnez	a0,80000d8e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d6c:	87ba                	mv	a5,a4
    80000d6e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d72:	2781                	sext.w	a5,a5
    80000d74:	ffe5                	bnez	a5,80000d6c <acquire+0x22>
  __sync_synchronize();
    80000d76:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d7a:	00001097          	auipc	ra,0x1
    80000d7e:	ec6080e7          	jalr	-314(ra) # 80001c40 <mycpu>
    80000d82:	e888                	sd	a0,16(s1)
}
    80000d84:	60e2                	ld	ra,24(sp)
    80000d86:	6442                	ld	s0,16(sp)
    80000d88:	64a2                	ld	s1,8(sp)
    80000d8a:	6105                	addi	sp,sp,32
    80000d8c:	8082                	ret
    panic("acquire");
    80000d8e:	00007517          	auipc	a0,0x7
    80000d92:	2ea50513          	addi	a0,a0,746 # 80008078 <digits+0x38>
    80000d96:	fffff097          	auipc	ra,0xfffff
    80000d9a:	7ac080e7          	jalr	1964(ra) # 80000542 <panic>

0000000080000d9e <pop_off>:

void
pop_off(void)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e406                	sd	ra,8(sp)
    80000da2:	e022                	sd	s0,0(sp)
    80000da4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000da6:	00001097          	auipc	ra,0x1
    80000daa:	e9a080e7          	jalr	-358(ra) # 80001c40 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000db2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000db4:	e78d                	bnez	a5,80000dde <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000db6:	5d3c                	lw	a5,120(a0)
    80000db8:	02f05b63          	blez	a5,80000dee <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dbc:	37fd                	addiw	a5,a5,-1
    80000dbe:	0007871b          	sext.w	a4,a5
    80000dc2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dc4:	eb09                	bnez	a4,80000dd6 <pop_off+0x38>
    80000dc6:	5d7c                	lw	a5,124(a0)
    80000dc8:	c799                	beqz	a5,80000dd6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000dce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000dd2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000dd6:	60a2                	ld	ra,8(sp)
    80000dd8:	6402                	ld	s0,0(sp)
    80000dda:	0141                	addi	sp,sp,16
    80000ddc:	8082                	ret
    panic("pop_off - interruptible");
    80000dde:	00007517          	auipc	a0,0x7
    80000de2:	2a250513          	addi	a0,a0,674 # 80008080 <digits+0x40>
    80000de6:	fffff097          	auipc	ra,0xfffff
    80000dea:	75c080e7          	jalr	1884(ra) # 80000542 <panic>
    panic("pop_off");
    80000dee:	00007517          	auipc	a0,0x7
    80000df2:	2aa50513          	addi	a0,a0,682 # 80008098 <digits+0x58>
    80000df6:	fffff097          	auipc	ra,0xfffff
    80000dfa:	74c080e7          	jalr	1868(ra) # 80000542 <panic>

0000000080000dfe <release>:
{
    80000dfe:	1101                	addi	sp,sp,-32
    80000e00:	ec06                	sd	ra,24(sp)
    80000e02:	e822                	sd	s0,16(sp)
    80000e04:	e426                	sd	s1,8(sp)
    80000e06:	1000                	addi	s0,sp,32
    80000e08:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e0a:	00000097          	auipc	ra,0x0
    80000e0e:	ec6080e7          	jalr	-314(ra) # 80000cd0 <holding>
    80000e12:	c115                	beqz	a0,80000e36 <release+0x38>
  lk->cpu = 0;
    80000e14:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e18:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e1c:	0f50000f          	fence	iorw,ow
    80000e20:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e24:	00000097          	auipc	ra,0x0
    80000e28:	f7a080e7          	jalr	-134(ra) # 80000d9e <pop_off>
}
    80000e2c:	60e2                	ld	ra,24(sp)
    80000e2e:	6442                	ld	s0,16(sp)
    80000e30:	64a2                	ld	s1,8(sp)
    80000e32:	6105                	addi	sp,sp,32
    80000e34:	8082                	ret
    panic("release");
    80000e36:	00007517          	auipc	a0,0x7
    80000e3a:	26a50513          	addi	a0,a0,618 # 800080a0 <digits+0x60>
    80000e3e:	fffff097          	auipc	ra,0xfffff
    80000e42:	704080e7          	jalr	1796(ra) # 80000542 <panic>

0000000080000e46 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e46:	1141                	addi	sp,sp,-16
    80000e48:	e422                	sd	s0,8(sp)
    80000e4a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e4c:	ca19                	beqz	a2,80000e62 <memset+0x1c>
    80000e4e:	87aa                	mv	a5,a0
    80000e50:	1602                	slli	a2,a2,0x20
    80000e52:	9201                	srli	a2,a2,0x20
    80000e54:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e58:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e5c:	0785                	addi	a5,a5,1
    80000e5e:	fee79de3          	bne	a5,a4,80000e58 <memset+0x12>
  }
  return dst;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret

0000000080000e68 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e68:	1141                	addi	sp,sp,-16
    80000e6a:	e422                	sd	s0,8(sp)
    80000e6c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e6e:	ca05                	beqz	a2,80000e9e <memcmp+0x36>
    80000e70:	fff6069b          	addiw	a3,a2,-1
    80000e74:	1682                	slli	a3,a3,0x20
    80000e76:	9281                	srli	a3,a3,0x20
    80000e78:	0685                	addi	a3,a3,1
    80000e7a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e7c:	00054783          	lbu	a5,0(a0)
    80000e80:	0005c703          	lbu	a4,0(a1)
    80000e84:	00e79863          	bne	a5,a4,80000e94 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e88:	0505                	addi	a0,a0,1
    80000e8a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e8c:	fed518e3          	bne	a0,a3,80000e7c <memcmp+0x14>
  }

  return 0;
    80000e90:	4501                	li	a0,0
    80000e92:	a019                	j	80000e98 <memcmp+0x30>
      return *s1 - *s2;
    80000e94:	40e7853b          	subw	a0,a5,a4
}
    80000e98:	6422                	ld	s0,8(sp)
    80000e9a:	0141                	addi	sp,sp,16
    80000e9c:	8082                	ret
  return 0;
    80000e9e:	4501                	li	a0,0
    80000ea0:	bfe5                	j	80000e98 <memcmp+0x30>

0000000080000ea2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ea2:	1141                	addi	sp,sp,-16
    80000ea4:	e422                	sd	s0,8(sp)
    80000ea6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ea8:	02a5e563          	bltu	a1,a0,80000ed2 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000eac:	fff6069b          	addiw	a3,a2,-1
    80000eb0:	ce11                	beqz	a2,80000ecc <memmove+0x2a>
    80000eb2:	1682                	slli	a3,a3,0x20
    80000eb4:	9281                	srli	a3,a3,0x20
    80000eb6:	0685                	addi	a3,a3,1
    80000eb8:	96ae                	add	a3,a3,a1
    80000eba:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000ebc:	0585                	addi	a1,a1,1
    80000ebe:	0785                	addi	a5,a5,1
    80000ec0:	fff5c703          	lbu	a4,-1(a1)
    80000ec4:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000ec8:	fed59ae3          	bne	a1,a3,80000ebc <memmove+0x1a>

  return dst;
}
    80000ecc:	6422                	ld	s0,8(sp)
    80000ece:	0141                	addi	sp,sp,16
    80000ed0:	8082                	ret
  if(s < d && s + n > d){
    80000ed2:	02061713          	slli	a4,a2,0x20
    80000ed6:	9301                	srli	a4,a4,0x20
    80000ed8:	00e587b3          	add	a5,a1,a4
    80000edc:	fcf578e3          	bgeu	a0,a5,80000eac <memmove+0xa>
    d += n;
    80000ee0:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000ee2:	fff6069b          	addiw	a3,a2,-1
    80000ee6:	d27d                	beqz	a2,80000ecc <memmove+0x2a>
    80000ee8:	02069613          	slli	a2,a3,0x20
    80000eec:	9201                	srli	a2,a2,0x20
    80000eee:	fff64613          	not	a2,a2
    80000ef2:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000ef4:	17fd                	addi	a5,a5,-1
    80000ef6:	177d                	addi	a4,a4,-1
    80000ef8:	0007c683          	lbu	a3,0(a5)
    80000efc:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000f00:	fef61ae3          	bne	a2,a5,80000ef4 <memmove+0x52>
    80000f04:	b7e1                	j	80000ecc <memmove+0x2a>

0000000080000f06 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f06:	1141                	addi	sp,sp,-16
    80000f08:	e406                	sd	ra,8(sp)
    80000f0a:	e022                	sd	s0,0(sp)
    80000f0c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	f94080e7          	jalr	-108(ra) # 80000ea2 <memmove>
}
    80000f16:	60a2                	ld	ra,8(sp)
    80000f18:	6402                	ld	s0,0(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret

0000000080000f1e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f1e:	1141                	addi	sp,sp,-16
    80000f20:	e422                	sd	s0,8(sp)
    80000f22:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f24:	ce11                	beqz	a2,80000f40 <strncmp+0x22>
    80000f26:	00054783          	lbu	a5,0(a0)
    80000f2a:	cf89                	beqz	a5,80000f44 <strncmp+0x26>
    80000f2c:	0005c703          	lbu	a4,0(a1)
    80000f30:	00f71a63          	bne	a4,a5,80000f44 <strncmp+0x26>
    n--, p++, q++;
    80000f34:	367d                	addiw	a2,a2,-1
    80000f36:	0505                	addi	a0,a0,1
    80000f38:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f3a:	f675                	bnez	a2,80000f26 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f3c:	4501                	li	a0,0
    80000f3e:	a809                	j	80000f50 <strncmp+0x32>
    80000f40:	4501                	li	a0,0
    80000f42:	a039                	j	80000f50 <strncmp+0x32>
  if(n == 0)
    80000f44:	ca09                	beqz	a2,80000f56 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f46:	00054503          	lbu	a0,0(a0)
    80000f4a:	0005c783          	lbu	a5,0(a1)
    80000f4e:	9d1d                	subw	a0,a0,a5
}
    80000f50:	6422                	ld	s0,8(sp)
    80000f52:	0141                	addi	sp,sp,16
    80000f54:	8082                	ret
    return 0;
    80000f56:	4501                	li	a0,0
    80000f58:	bfe5                	j	80000f50 <strncmp+0x32>

0000000080000f5a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f5a:	1141                	addi	sp,sp,-16
    80000f5c:	e422                	sd	s0,8(sp)
    80000f5e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f60:	872a                	mv	a4,a0
    80000f62:	8832                	mv	a6,a2
    80000f64:	367d                	addiw	a2,a2,-1
    80000f66:	01005963          	blez	a6,80000f78 <strncpy+0x1e>
    80000f6a:	0705                	addi	a4,a4,1
    80000f6c:	0005c783          	lbu	a5,0(a1)
    80000f70:	fef70fa3          	sb	a5,-1(a4)
    80000f74:	0585                	addi	a1,a1,1
    80000f76:	f7f5                	bnez	a5,80000f62 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f78:	86ba                	mv	a3,a4
    80000f7a:	00c05c63          	blez	a2,80000f92 <strncpy+0x38>
    *s++ = 0;
    80000f7e:	0685                	addi	a3,a3,1
    80000f80:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f84:	fff6c793          	not	a5,a3
    80000f88:	9fb9                	addw	a5,a5,a4
    80000f8a:	010787bb          	addw	a5,a5,a6
    80000f8e:	fef048e3          	bgtz	a5,80000f7e <strncpy+0x24>
  return os;
}
    80000f92:	6422                	ld	s0,8(sp)
    80000f94:	0141                	addi	sp,sp,16
    80000f96:	8082                	ret

0000000080000f98 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f98:	1141                	addi	sp,sp,-16
    80000f9a:	e422                	sd	s0,8(sp)
    80000f9c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f9e:	02c05363          	blez	a2,80000fc4 <safestrcpy+0x2c>
    80000fa2:	fff6069b          	addiw	a3,a2,-1
    80000fa6:	1682                	slli	a3,a3,0x20
    80000fa8:	9281                	srli	a3,a3,0x20
    80000faa:	96ae                	add	a3,a3,a1
    80000fac:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fae:	00d58963          	beq	a1,a3,80000fc0 <safestrcpy+0x28>
    80000fb2:	0585                	addi	a1,a1,1
    80000fb4:	0785                	addi	a5,a5,1
    80000fb6:	fff5c703          	lbu	a4,-1(a1)
    80000fba:	fee78fa3          	sb	a4,-1(a5)
    80000fbe:	fb65                	bnez	a4,80000fae <safestrcpy+0x16>
    ;
  *s = 0;
    80000fc0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fc4:	6422                	ld	s0,8(sp)
    80000fc6:	0141                	addi	sp,sp,16
    80000fc8:	8082                	ret

0000000080000fca <strlen>:

int
strlen(const char *s)
{
    80000fca:	1141                	addi	sp,sp,-16
    80000fcc:	e422                	sd	s0,8(sp)
    80000fce:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fd0:	00054783          	lbu	a5,0(a0)
    80000fd4:	cf91                	beqz	a5,80000ff0 <strlen+0x26>
    80000fd6:	0505                	addi	a0,a0,1
    80000fd8:	87aa                	mv	a5,a0
    80000fda:	4685                	li	a3,1
    80000fdc:	9e89                	subw	a3,a3,a0
    80000fde:	00f6853b          	addw	a0,a3,a5
    80000fe2:	0785                	addi	a5,a5,1
    80000fe4:	fff7c703          	lbu	a4,-1(a5)
    80000fe8:	fb7d                	bnez	a4,80000fde <strlen+0x14>
    ;
  return n;
}
    80000fea:	6422                	ld	s0,8(sp)
    80000fec:	0141                	addi	sp,sp,16
    80000fee:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ff0:	4501                	li	a0,0
    80000ff2:	bfe5                	j	80000fea <strlen+0x20>

0000000080000ff4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ff4:	1141                	addi	sp,sp,-16
    80000ff6:	e406                	sd	ra,8(sp)
    80000ff8:	e022                	sd	s0,0(sp)
    80000ffa:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ffc:	00001097          	auipc	ra,0x1
    80001000:	c34080e7          	jalr	-972(ra) # 80001c30 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001004:	00008717          	auipc	a4,0x8
    80001008:	00870713          	addi	a4,a4,8 # 8000900c <started>
  if(cpuid() == 0){
    8000100c:	c139                	beqz	a0,80001052 <main+0x5e>
    while(started == 0)
    8000100e:	431c                	lw	a5,0(a4)
    80001010:	2781                	sext.w	a5,a5
    80001012:	dff5                	beqz	a5,8000100e <main+0x1a>
      ;
    __sync_synchronize();
    80001014:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001018:	00001097          	auipc	ra,0x1
    8000101c:	c18080e7          	jalr	-1000(ra) # 80001c30 <cpuid>
    80001020:	85aa                	mv	a1,a0
    80001022:	00007517          	auipc	a0,0x7
    80001026:	09e50513          	addi	a0,a0,158 # 800080c0 <digits+0x80>
    8000102a:	fffff097          	auipc	ra,0xfffff
    8000102e:	562080e7          	jalr	1378(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80001032:	00000097          	auipc	ra,0x0
    80001036:	0d8080e7          	jalr	216(ra) # 8000110a <kvminithart>
    trapinithart();   // install kernel trap vector
    8000103a:	00002097          	auipc	ra,0x2
    8000103e:	87c080e7          	jalr	-1924(ra) # 800028b6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001042:	00005097          	auipc	ra,0x5
    80001046:	e4e080e7          	jalr	-434(ra) # 80005e90 <plicinithart>
  }

  scheduler();        
    8000104a:	00001097          	auipc	ra,0x1
    8000104e:	146080e7          	jalr	326(ra) # 80002190 <scheduler>
    consoleinit();
    80001052:	fffff097          	auipc	ra,0xfffff
    80001056:	402080e7          	jalr	1026(ra) # 80000454 <consoleinit>
    printfinit();
    8000105a:	fffff097          	auipc	ra,0xfffff
    8000105e:	712080e7          	jalr	1810(ra) # 8000076c <printfinit>
    printf("\n");
    80001062:	00007517          	auipc	a0,0x7
    80001066:	06e50513          	addi	a0,a0,110 # 800080d0 <digits+0x90>
    8000106a:	fffff097          	auipc	ra,0xfffff
    8000106e:	522080e7          	jalr	1314(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80001072:	00007517          	auipc	a0,0x7
    80001076:	03650513          	addi	a0,a0,54 # 800080a8 <digits+0x68>
    8000107a:	fffff097          	auipc	ra,0xfffff
    8000107e:	512080e7          	jalr	1298(ra) # 8000058c <printf>
    printf("\n");
    80001082:	00007517          	auipc	a0,0x7
    80001086:	04e50513          	addi	a0,a0,78 # 800080d0 <digits+0x90>
    8000108a:	fffff097          	auipc	ra,0xfffff
    8000108e:	502080e7          	jalr	1282(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80001092:	00000097          	auipc	ra,0x0
    80001096:	ab4080e7          	jalr	-1356(ra) # 80000b46 <kinit>
    kvminit();       // create kernel page table
    8000109a:	00000097          	auipc	ra,0x0
    8000109e:	2a0080e7          	jalr	672(ra) # 8000133a <kvminit>
    kvminithart();   // turn on paging
    800010a2:	00000097          	auipc	ra,0x0
    800010a6:	068080e7          	jalr	104(ra) # 8000110a <kvminithart>
    procinit();      // process table
    800010aa:	00001097          	auipc	ra,0x1
    800010ae:	ab6080e7          	jalr	-1354(ra) # 80001b60 <procinit>
    trapinit();      // trap vectors
    800010b2:	00001097          	auipc	ra,0x1
    800010b6:	7dc080e7          	jalr	2012(ra) # 8000288e <trapinit>
    trapinithart();  // install kernel trap vector
    800010ba:	00001097          	auipc	ra,0x1
    800010be:	7fc080e7          	jalr	2044(ra) # 800028b6 <trapinithart>
    plicinit();      // set up interrupt controller
    800010c2:	00005097          	auipc	ra,0x5
    800010c6:	db8080e7          	jalr	-584(ra) # 80005e7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010ca:	00005097          	auipc	ra,0x5
    800010ce:	dc6080e7          	jalr	-570(ra) # 80005e90 <plicinithart>
    binit();         // buffer cache
    800010d2:	00002097          	auipc	ra,0x2
    800010d6:	f6e080e7          	jalr	-146(ra) # 80003040 <binit>
    iinit();         // inode cache
    800010da:	00002097          	auipc	ra,0x2
    800010de:	5fe080e7          	jalr	1534(ra) # 800036d8 <iinit>
    fileinit();      // file table
    800010e2:	00003097          	auipc	ra,0x3
    800010e6:	59c080e7          	jalr	1436(ra) # 8000467e <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010ea:	00005097          	auipc	ra,0x5
    800010ee:	eae080e7          	jalr	-338(ra) # 80005f98 <virtio_disk_init>
    userinit();      // first user process
    800010f2:	00001097          	auipc	ra,0x1
    800010f6:	e34080e7          	jalr	-460(ra) # 80001f26 <userinit>
    __sync_synchronize();
    800010fa:	0ff0000f          	fence
    started = 1;
    800010fe:	4785                	li	a5,1
    80001100:	00008717          	auipc	a4,0x8
    80001104:	f0f72623          	sw	a5,-244(a4) # 8000900c <started>
    80001108:	b789                	j	8000104a <main+0x56>

000000008000110a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000110a:	1141                	addi	sp,sp,-16
    8000110c:	e422                	sd	s0,8(sp)
    8000110e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001110:	00008797          	auipc	a5,0x8
    80001114:	f007b783          	ld	a5,-256(a5) # 80009010 <kernel_pagetable>
    80001118:	83b1                	srli	a5,a5,0xc
    8000111a:	577d                	li	a4,-1
    8000111c:	177e                	slli	a4,a4,0x3f
    8000111e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001120:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001124:	12000073          	sfence.vma
  sfence_vma();
}
    80001128:	6422                	ld	s0,8(sp)
    8000112a:	0141                	addi	sp,sp,16
    8000112c:	8082                	ret

000000008000112e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000112e:	7139                	addi	sp,sp,-64
    80001130:	fc06                	sd	ra,56(sp)
    80001132:	f822                	sd	s0,48(sp)
    80001134:	f426                	sd	s1,40(sp)
    80001136:	f04a                	sd	s2,32(sp)
    80001138:	ec4e                	sd	s3,24(sp)
    8000113a:	e852                	sd	s4,16(sp)
    8000113c:	e456                	sd	s5,8(sp)
    8000113e:	e05a                	sd	s6,0(sp)
    80001140:	0080                	addi	s0,sp,64
    80001142:	84aa                	mv	s1,a0
    80001144:	89ae                	mv	s3,a1
    80001146:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001148:	57fd                	li	a5,-1
    8000114a:	83e9                	srli	a5,a5,0x1a
    8000114c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000114e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001150:	04b7f263          	bgeu	a5,a1,80001194 <walk+0x66>
    panic("walk");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8450513          	addi	a0,a0,-124 # 800080d8 <digits+0x98>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3e6080e7          	jalr	998(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001164:	060a8663          	beqz	s5,800011d0 <walk+0xa2>
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	a32080e7          	jalr	-1486(ra) # 80000b9a <kalloc>
    80001170:	84aa                	mv	s1,a0
    80001172:	c529                	beqz	a0,800011bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001174:	6605                	lui	a2,0x1
    80001176:	4581                	li	a1,0
    80001178:	00000097          	auipc	ra,0x0
    8000117c:	cce080e7          	jalr	-818(ra) # 80000e46 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001180:	00c4d793          	srli	a5,s1,0xc
    80001184:	07aa                	slli	a5,a5,0xa
    80001186:	0017e793          	ori	a5,a5,1
    8000118a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000118e:	3a5d                	addiw	s4,s4,-9
    80001190:	036a0063          	beq	s4,s6,800011b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001194:	0149d933          	srl	s2,s3,s4
    80001198:	1ff97913          	andi	s2,s2,511
    8000119c:	090e                	slli	s2,s2,0x3
    8000119e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011a0:	00093483          	ld	s1,0(s2)
    800011a4:	0014f793          	andi	a5,s1,1
    800011a8:	dfd5                	beqz	a5,80001164 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011aa:	80a9                	srli	s1,s1,0xa
    800011ac:	04b2                	slli	s1,s1,0xc
    800011ae:	b7c5                	j	8000118e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011b0:	00c9d513          	srli	a0,s3,0xc
    800011b4:	1ff57513          	andi	a0,a0,511
    800011b8:	050e                	slli	a0,a0,0x3
    800011ba:	9526                	add	a0,a0,s1
}
    800011bc:	70e2                	ld	ra,56(sp)
    800011be:	7442                	ld	s0,48(sp)
    800011c0:	74a2                	ld	s1,40(sp)
    800011c2:	7902                	ld	s2,32(sp)
    800011c4:	69e2                	ld	s3,24(sp)
    800011c6:	6a42                	ld	s4,16(sp)
    800011c8:	6aa2                	ld	s5,8(sp)
    800011ca:	6b02                	ld	s6,0(sp)
    800011cc:	6121                	addi	sp,sp,64
    800011ce:	8082                	ret
        return 0;
    800011d0:	4501                	li	a0,0
    800011d2:	b7ed                	j	800011bc <walk+0x8e>

00000000800011d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011d4:	57fd                	li	a5,-1
    800011d6:	83e9                	srli	a5,a5,0x1a
    800011d8:	00b7f463          	bgeu	a5,a1,800011e0 <walkaddr+0xc>
    return 0;
    800011dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011de:	8082                	ret
{
    800011e0:	1141                	addi	sp,sp,-16
    800011e2:	e406                	sd	ra,8(sp)
    800011e4:	e022                	sd	s0,0(sp)
    800011e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011e8:	4601                	li	a2,0
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f44080e7          	jalr	-188(ra) # 8000112e <walk>
  if(pte == 0)
    800011f2:	c105                	beqz	a0,80001212 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011f6:	0117f693          	andi	a3,a5,17
    800011fa:	4745                	li	a4,17
    return 0;
    800011fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011fe:	00e68663          	beq	a3,a4,8000120a <walkaddr+0x36>
}
    80001202:	60a2                	ld	ra,8(sp)
    80001204:	6402                	ld	s0,0(sp)
    80001206:	0141                	addi	sp,sp,16
    80001208:	8082                	ret
  pa = PTE2PA(*pte);
    8000120a:	00a7d513          	srli	a0,a5,0xa
    8000120e:	0532                	slli	a0,a0,0xc
  return pa;
    80001210:	bfcd                	j	80001202 <walkaddr+0x2e>
    return 0;
    80001212:	4501                	li	a0,0
    80001214:	b7fd                	j	80001202 <walkaddr+0x2e>

0000000080001216 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001216:	1101                	addi	sp,sp,-32
    80001218:	ec06                	sd	ra,24(sp)
    8000121a:	e822                	sd	s0,16(sp)
    8000121c:	e426                	sd	s1,8(sp)
    8000121e:	1000                	addi	s0,sp,32
    80001220:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001222:	1552                	slli	a0,a0,0x34
    80001224:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001228:	4601                	li	a2,0
    8000122a:	00008517          	auipc	a0,0x8
    8000122e:	de653503          	ld	a0,-538(a0) # 80009010 <kernel_pagetable>
    80001232:	00000097          	auipc	ra,0x0
    80001236:	efc080e7          	jalr	-260(ra) # 8000112e <walk>
  if(pte == 0)
    8000123a:	cd09                	beqz	a0,80001254 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000123c:	6108                	ld	a0,0(a0)
    8000123e:	00157793          	andi	a5,a0,1
    80001242:	c38d                	beqz	a5,80001264 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001244:	8129                	srli	a0,a0,0xa
    80001246:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001248:	9526                	add	a0,a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6105                	addi	sp,sp,32
    80001252:	8082                	ret
    panic("kvmpa");
    80001254:	00007517          	auipc	a0,0x7
    80001258:	e8c50513          	addi	a0,a0,-372 # 800080e0 <digits+0xa0>
    8000125c:	fffff097          	auipc	ra,0xfffff
    80001260:	2e6080e7          	jalr	742(ra) # 80000542 <panic>
    panic("kvmpa");
    80001264:	00007517          	auipc	a0,0x7
    80001268:	e7c50513          	addi	a0,a0,-388 # 800080e0 <digits+0xa0>
    8000126c:	fffff097          	auipc	ra,0xfffff
    80001270:	2d6080e7          	jalr	726(ra) # 80000542 <panic>

0000000080001274 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001274:	715d                	addi	sp,sp,-80
    80001276:	e486                	sd	ra,72(sp)
    80001278:	e0a2                	sd	s0,64(sp)
    8000127a:	fc26                	sd	s1,56(sp)
    8000127c:	f84a                	sd	s2,48(sp)
    8000127e:	f44e                	sd	s3,40(sp)
    80001280:	f052                	sd	s4,32(sp)
    80001282:	ec56                	sd	s5,24(sp)
    80001284:	e85a                	sd	s6,16(sp)
    80001286:	e45e                	sd	s7,8(sp)
    80001288:	0880                	addi	s0,sp,80
    8000128a:	8aaa                	mv	s5,a0
    8000128c:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000128e:	777d                	lui	a4,0xfffff
    80001290:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001294:	167d                	addi	a2,a2,-1
    80001296:	00b609b3          	add	s3,a2,a1
    8000129a:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000129e:	893e                	mv	s2,a5
    800012a0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800012a4:	6b85                	lui	s7,0x1
    800012a6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012aa:	4605                	li	a2,1
    800012ac:	85ca                	mv	a1,s2
    800012ae:	8556                	mv	a0,s5
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	e7e080e7          	jalr	-386(ra) # 8000112e <walk>
    800012b8:	c51d                	beqz	a0,800012e6 <mappages+0x72>
    if(*pte & PTE_V)
    800012ba:	611c                	ld	a5,0(a0)
    800012bc:	8b85                	andi	a5,a5,1
    800012be:	ef81                	bnez	a5,800012d6 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012c0:	80b1                	srli	s1,s1,0xc
    800012c2:	04aa                	slli	s1,s1,0xa
    800012c4:	0164e4b3          	or	s1,s1,s6
    800012c8:	0014e493          	ori	s1,s1,1
    800012cc:	e104                	sd	s1,0(a0)
    if(a == last)
    800012ce:	03390863          	beq	s2,s3,800012fe <mappages+0x8a>
    a += PGSIZE;
    800012d2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012d4:	bfc9                	j	800012a6 <mappages+0x32>
      panic("remap");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e1250513          	addi	a0,a0,-494 # 800080e8 <digits+0xa8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	264080e7          	jalr	612(ra) # 80000542 <panic>
      return -1;
    800012e6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012e8:	60a6                	ld	ra,72(sp)
    800012ea:	6406                	ld	s0,64(sp)
    800012ec:	74e2                	ld	s1,56(sp)
    800012ee:	7942                	ld	s2,48(sp)
    800012f0:	79a2                	ld	s3,40(sp)
    800012f2:	7a02                	ld	s4,32(sp)
    800012f4:	6ae2                	ld	s5,24(sp)
    800012f6:	6b42                	ld	s6,16(sp)
    800012f8:	6ba2                	ld	s7,8(sp)
    800012fa:	6161                	addi	sp,sp,80
    800012fc:	8082                	ret
  return 0;
    800012fe:	4501                	li	a0,0
    80001300:	b7e5                	j	800012e8 <mappages+0x74>

0000000080001302 <kvmmap>:
{
    80001302:	1141                	addi	sp,sp,-16
    80001304:	e406                	sd	ra,8(sp)
    80001306:	e022                	sd	s0,0(sp)
    80001308:	0800                	addi	s0,sp,16
    8000130a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000130c:	86ae                	mv	a3,a1
    8000130e:	85aa                	mv	a1,a0
    80001310:	00008517          	auipc	a0,0x8
    80001314:	d0053503          	ld	a0,-768(a0) # 80009010 <kernel_pagetable>
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	f5c080e7          	jalr	-164(ra) # 80001274 <mappages>
    80001320:	e509                	bnez	a0,8000132a <kvmmap+0x28>
}
    80001322:	60a2                	ld	ra,8(sp)
    80001324:	6402                	ld	s0,0(sp)
    80001326:	0141                	addi	sp,sp,16
    80001328:	8082                	ret
    panic("kvmmap");
    8000132a:	00007517          	auipc	a0,0x7
    8000132e:	dc650513          	addi	a0,a0,-570 # 800080f0 <digits+0xb0>
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	210080e7          	jalr	528(ra) # 80000542 <panic>

000000008000133a <kvminit>:
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001344:	00000097          	auipc	ra,0x0
    80001348:	856080e7          	jalr	-1962(ra) # 80000b9a <kalloc>
    8000134c:	00008797          	auipc	a5,0x8
    80001350:	cca7b223          	sd	a0,-828(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001354:	6605                	lui	a2,0x1
    80001356:	4581                	li	a1,0
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	aee080e7          	jalr	-1298(ra) # 80000e46 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001360:	4699                	li	a3,6
    80001362:	6605                	lui	a2,0x1
    80001364:	100005b7          	lui	a1,0x10000
    80001368:	10000537          	lui	a0,0x10000
    8000136c:	00000097          	auipc	ra,0x0
    80001370:	f96080e7          	jalr	-106(ra) # 80001302 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001374:	4699                	li	a3,6
    80001376:	6605                	lui	a2,0x1
    80001378:	100015b7          	lui	a1,0x10001
    8000137c:	10001537          	lui	a0,0x10001
    80001380:	00000097          	auipc	ra,0x0
    80001384:	f82080e7          	jalr	-126(ra) # 80001302 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001388:	4699                	li	a3,6
    8000138a:	6641                	lui	a2,0x10
    8000138c:	020005b7          	lui	a1,0x2000
    80001390:	02000537          	lui	a0,0x2000
    80001394:	00000097          	auipc	ra,0x0
    80001398:	f6e080e7          	jalr	-146(ra) # 80001302 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000139c:	4699                	li	a3,6
    8000139e:	00400637          	lui	a2,0x400
    800013a2:	0c0005b7          	lui	a1,0xc000
    800013a6:	0c000537          	lui	a0,0xc000
    800013aa:	00000097          	auipc	ra,0x0
    800013ae:	f58080e7          	jalr	-168(ra) # 80001302 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013b2:	00007497          	auipc	s1,0x7
    800013b6:	c4e48493          	addi	s1,s1,-946 # 80008000 <etext>
    800013ba:	46a9                	li	a3,10
    800013bc:	80007617          	auipc	a2,0x80007
    800013c0:	c4460613          	addi	a2,a2,-956 # 8000 <_entry-0x7fff8000>
    800013c4:	4585                	li	a1,1
    800013c6:	05fe                	slli	a1,a1,0x1f
    800013c8:	852e                	mv	a0,a1
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	f38080e7          	jalr	-200(ra) # 80001302 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013d2:	4699                	li	a3,6
    800013d4:	4645                	li	a2,17
    800013d6:	066e                	slli	a2,a2,0x1b
    800013d8:	8e05                	sub	a2,a2,s1
    800013da:	85a6                	mv	a1,s1
    800013dc:	8526                	mv	a0,s1
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	f24080e7          	jalr	-220(ra) # 80001302 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013e6:	46a9                	li	a3,10
    800013e8:	6605                	lui	a2,0x1
    800013ea:	00006597          	auipc	a1,0x6
    800013ee:	c1658593          	addi	a1,a1,-1002 # 80007000 <_trampoline>
    800013f2:	04000537          	lui	a0,0x4000
    800013f6:	157d                	addi	a0,a0,-1
    800013f8:	0532                	slli	a0,a0,0xc
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	f08080e7          	jalr	-248(ra) # 80001302 <kvmmap>
}
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret

000000008000140c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000140c:	715d                	addi	sp,sp,-80
    8000140e:	e486                	sd	ra,72(sp)
    80001410:	e0a2                	sd	s0,64(sp)
    80001412:	fc26                	sd	s1,56(sp)
    80001414:	f84a                	sd	s2,48(sp)
    80001416:	f44e                	sd	s3,40(sp)
    80001418:	f052                	sd	s4,32(sp)
    8000141a:	ec56                	sd	s5,24(sp)
    8000141c:	e85a                	sd	s6,16(sp)
    8000141e:	e45e                	sd	s7,8(sp)
    80001420:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001422:	03459793          	slli	a5,a1,0x34
    80001426:	e795                	bnez	a5,80001452 <uvmunmap+0x46>
    80001428:	8a2a                	mv	s4,a0
    8000142a:	892e                	mv	s2,a1
    8000142c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000142e:	0632                	slli	a2,a2,0xc
    80001430:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001434:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001436:	6b05                	lui	s6,0x1
    80001438:	0735e263          	bltu	a1,s3,8000149c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000143c:	60a6                	ld	ra,72(sp)
    8000143e:	6406                	ld	s0,64(sp)
    80001440:	74e2                	ld	s1,56(sp)
    80001442:	7942                	ld	s2,48(sp)
    80001444:	79a2                	ld	s3,40(sp)
    80001446:	7a02                	ld	s4,32(sp)
    80001448:	6ae2                	ld	s5,24(sp)
    8000144a:	6b42                	ld	s6,16(sp)
    8000144c:	6ba2                	ld	s7,8(sp)
    8000144e:	6161                	addi	sp,sp,80
    80001450:	8082                	ret
    panic("uvmunmap: not aligned");
    80001452:	00007517          	auipc	a0,0x7
    80001456:	ca650513          	addi	a0,a0,-858 # 800080f8 <digits+0xb8>
    8000145a:	fffff097          	auipc	ra,0xfffff
    8000145e:	0e8080e7          	jalr	232(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001462:	00007517          	auipc	a0,0x7
    80001466:	cae50513          	addi	a0,a0,-850 # 80008110 <digits+0xd0>
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	0d8080e7          	jalr	216(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001472:	00007517          	auipc	a0,0x7
    80001476:	cae50513          	addi	a0,a0,-850 # 80008120 <digits+0xe0>
    8000147a:	fffff097          	auipc	ra,0xfffff
    8000147e:	0c8080e7          	jalr	200(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    80001482:	00007517          	auipc	a0,0x7
    80001486:	cb650513          	addi	a0,a0,-842 # 80008138 <digits+0xf8>
    8000148a:	fffff097          	auipc	ra,0xfffff
    8000148e:	0b8080e7          	jalr	184(ra) # 80000542 <panic>
    *pte = 0;
    80001492:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001496:	995a                	add	s2,s2,s6
    80001498:	fb3972e3          	bgeu	s2,s3,8000143c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000149c:	4601                	li	a2,0
    8000149e:	85ca                	mv	a1,s2
    800014a0:	8552                	mv	a0,s4
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	c8c080e7          	jalr	-884(ra) # 8000112e <walk>
    800014aa:	84aa                	mv	s1,a0
    800014ac:	d95d                	beqz	a0,80001462 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014ae:	6108                	ld	a0,0(a0)
    800014b0:	00157793          	andi	a5,a0,1
    800014b4:	dfdd                	beqz	a5,80001472 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014b6:	3ff57793          	andi	a5,a0,1023
    800014ba:	fd7784e3          	beq	a5,s7,80001482 <uvmunmap+0x76>
    if(do_free){
    800014be:	fc0a8ae3          	beqz	s5,80001492 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014c2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014c4:	0532                	slli	a0,a0,0xc
    800014c6:	fffff097          	auipc	ra,0xfffff
    800014ca:	54c080e7          	jalr	1356(ra) # 80000a12 <kfree>
    800014ce:	b7d1                	j	80001492 <uvmunmap+0x86>

00000000800014d0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014d0:	1101                	addi	sp,sp,-32
    800014d2:	ec06                	sd	ra,24(sp)
    800014d4:	e822                	sd	s0,16(sp)
    800014d6:	e426                	sd	s1,8(sp)
    800014d8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014da:	fffff097          	auipc	ra,0xfffff
    800014de:	6c0080e7          	jalr	1728(ra) # 80000b9a <kalloc>
    800014e2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014e4:	c519                	beqz	a0,800014f2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014e6:	6605                	lui	a2,0x1
    800014e8:	4581                	li	a1,0
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	95c080e7          	jalr	-1700(ra) # 80000e46 <memset>
  return pagetable;
}
    800014f2:	8526                	mv	a0,s1
    800014f4:	60e2                	ld	ra,24(sp)
    800014f6:	6442                	ld	s0,16(sp)
    800014f8:	64a2                	ld	s1,8(sp)
    800014fa:	6105                	addi	sp,sp,32
    800014fc:	8082                	ret

00000000800014fe <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014fe:	7179                	addi	sp,sp,-48
    80001500:	f406                	sd	ra,40(sp)
    80001502:	f022                	sd	s0,32(sp)
    80001504:	ec26                	sd	s1,24(sp)
    80001506:	e84a                	sd	s2,16(sp)
    80001508:	e44e                	sd	s3,8(sp)
    8000150a:	e052                	sd	s4,0(sp)
    8000150c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000150e:	6785                	lui	a5,0x1
    80001510:	04f67863          	bgeu	a2,a5,80001560 <uvminit+0x62>
    80001514:	8a2a                	mv	s4,a0
    80001516:	89ae                	mv	s3,a1
    80001518:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	680080e7          	jalr	1664(ra) # 80000b9a <kalloc>
    80001522:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001524:	6605                	lui	a2,0x1
    80001526:	4581                	li	a1,0
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	91e080e7          	jalr	-1762(ra) # 80000e46 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001530:	4779                	li	a4,30
    80001532:	86ca                	mv	a3,s2
    80001534:	6605                	lui	a2,0x1
    80001536:	4581                	li	a1,0
    80001538:	8552                	mv	a0,s4
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	d3a080e7          	jalr	-710(ra) # 80001274 <mappages>
  memmove(mem, src, sz);
    80001542:	8626                	mv	a2,s1
    80001544:	85ce                	mv	a1,s3
    80001546:	854a                	mv	a0,s2
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	95a080e7          	jalr	-1702(ra) # 80000ea2 <memmove>
}
    80001550:	70a2                	ld	ra,40(sp)
    80001552:	7402                	ld	s0,32(sp)
    80001554:	64e2                	ld	s1,24(sp)
    80001556:	6942                	ld	s2,16(sp)
    80001558:	69a2                	ld	s3,8(sp)
    8000155a:	6a02                	ld	s4,0(sp)
    8000155c:	6145                	addi	sp,sp,48
    8000155e:	8082                	ret
    panic("inituvm: more than a page");
    80001560:	00007517          	auipc	a0,0x7
    80001564:	bf050513          	addi	a0,a0,-1040 # 80008150 <digits+0x110>
    80001568:	fffff097          	auipc	ra,0xfffff
    8000156c:	fda080e7          	jalr	-38(ra) # 80000542 <panic>

0000000080001570 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001570:	1101                	addi	sp,sp,-32
    80001572:	ec06                	sd	ra,24(sp)
    80001574:	e822                	sd	s0,16(sp)
    80001576:	e426                	sd	s1,8(sp)
    80001578:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000157a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000157c:	00b67d63          	bgeu	a2,a1,80001596 <uvmdealloc+0x26>
    80001580:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001582:	6785                	lui	a5,0x1
    80001584:	17fd                	addi	a5,a5,-1
    80001586:	00f60733          	add	a4,a2,a5
    8000158a:	767d                	lui	a2,0xfffff
    8000158c:	8f71                	and	a4,a4,a2
    8000158e:	97ae                	add	a5,a5,a1
    80001590:	8ff1                	and	a5,a5,a2
    80001592:	00f76863          	bltu	a4,a5,800015a2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001596:	8526                	mv	a0,s1
    80001598:	60e2                	ld	ra,24(sp)
    8000159a:	6442                	ld	s0,16(sp)
    8000159c:	64a2                	ld	s1,8(sp)
    8000159e:	6105                	addi	sp,sp,32
    800015a0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015a2:	8f99                	sub	a5,a5,a4
    800015a4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015a6:	4685                	li	a3,1
    800015a8:	0007861b          	sext.w	a2,a5
    800015ac:	85ba                	mv	a1,a4
    800015ae:	00000097          	auipc	ra,0x0
    800015b2:	e5e080e7          	jalr	-418(ra) # 8000140c <uvmunmap>
    800015b6:	b7c5                	j	80001596 <uvmdealloc+0x26>

00000000800015b8 <uvmalloc>:
  if(newsz < oldsz)
    800015b8:	0ab66163          	bltu	a2,a1,8000165a <uvmalloc+0xa2>
{
    800015bc:	7139                	addi	sp,sp,-64
    800015be:	fc06                	sd	ra,56(sp)
    800015c0:	f822                	sd	s0,48(sp)
    800015c2:	f426                	sd	s1,40(sp)
    800015c4:	f04a                	sd	s2,32(sp)
    800015c6:	ec4e                	sd	s3,24(sp)
    800015c8:	e852                	sd	s4,16(sp)
    800015ca:	e456                	sd	s5,8(sp)
    800015cc:	0080                	addi	s0,sp,64
    800015ce:	8aaa                	mv	s5,a0
    800015d0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015d2:	6985                	lui	s3,0x1
    800015d4:	19fd                	addi	s3,s3,-1
    800015d6:	95ce                	add	a1,a1,s3
    800015d8:	79fd                	lui	s3,0xfffff
    800015da:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015de:	08c9f063          	bgeu	s3,a2,8000165e <uvmalloc+0xa6>
    800015e2:	894e                	mv	s2,s3
    mem = kalloc();
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	5b6080e7          	jalr	1462(ra) # 80000b9a <kalloc>
    800015ec:	84aa                	mv	s1,a0
    if(mem == 0){
    800015ee:	c51d                	beqz	a0,8000161c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015f0:	6605                	lui	a2,0x1
    800015f2:	4581                	li	a1,0
    800015f4:	00000097          	auipc	ra,0x0
    800015f8:	852080e7          	jalr	-1966(ra) # 80000e46 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015fc:	4779                	li	a4,30
    800015fe:	86a6                	mv	a3,s1
    80001600:	6605                	lui	a2,0x1
    80001602:	85ca                	mv	a1,s2
    80001604:	8556                	mv	a0,s5
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	c6e080e7          	jalr	-914(ra) # 80001274 <mappages>
    8000160e:	e905                	bnez	a0,8000163e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001610:	6785                	lui	a5,0x1
    80001612:	993e                	add	s2,s2,a5
    80001614:	fd4968e3          	bltu	s2,s4,800015e4 <uvmalloc+0x2c>
  return newsz;
    80001618:	8552                	mv	a0,s4
    8000161a:	a809                	j	8000162c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000161c:	864e                	mv	a2,s3
    8000161e:	85ca                	mv	a1,s2
    80001620:	8556                	mv	a0,s5
    80001622:	00000097          	auipc	ra,0x0
    80001626:	f4e080e7          	jalr	-178(ra) # 80001570 <uvmdealloc>
      return 0;
    8000162a:	4501                	li	a0,0
}
    8000162c:	70e2                	ld	ra,56(sp)
    8000162e:	7442                	ld	s0,48(sp)
    80001630:	74a2                	ld	s1,40(sp)
    80001632:	7902                	ld	s2,32(sp)
    80001634:	69e2                	ld	s3,24(sp)
    80001636:	6a42                	ld	s4,16(sp)
    80001638:	6aa2                	ld	s5,8(sp)
    8000163a:	6121                	addi	sp,sp,64
    8000163c:	8082                	ret
      kfree(mem);
    8000163e:	8526                	mv	a0,s1
    80001640:	fffff097          	auipc	ra,0xfffff
    80001644:	3d2080e7          	jalr	978(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001648:	864e                	mv	a2,s3
    8000164a:	85ca                	mv	a1,s2
    8000164c:	8556                	mv	a0,s5
    8000164e:	00000097          	auipc	ra,0x0
    80001652:	f22080e7          	jalr	-222(ra) # 80001570 <uvmdealloc>
      return 0;
    80001656:	4501                	li	a0,0
    80001658:	bfd1                	j	8000162c <uvmalloc+0x74>
    return oldsz;
    8000165a:	852e                	mv	a0,a1
}
    8000165c:	8082                	ret
  return newsz;
    8000165e:	8532                	mv	a0,a2
    80001660:	b7f1                	j	8000162c <uvmalloc+0x74>

0000000080001662 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001662:	7179                	addi	sp,sp,-48
    80001664:	f406                	sd	ra,40(sp)
    80001666:	f022                	sd	s0,32(sp)
    80001668:	ec26                	sd	s1,24(sp)
    8000166a:	e84a                	sd	s2,16(sp)
    8000166c:	e44e                	sd	s3,8(sp)
    8000166e:	e052                	sd	s4,0(sp)
    80001670:	1800                	addi	s0,sp,48
    80001672:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001674:	84aa                	mv	s1,a0
    80001676:	6905                	lui	s2,0x1
    80001678:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000167a:	4985                	li	s3,1
    8000167c:	a821                	j	80001694 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000167e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001680:	0532                	slli	a0,a0,0xc
    80001682:	00000097          	auipc	ra,0x0
    80001686:	fe0080e7          	jalr	-32(ra) # 80001662 <freewalk>
      pagetable[i] = 0;
    8000168a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000168e:	04a1                	addi	s1,s1,8
    80001690:	03248163          	beq	s1,s2,800016b2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001694:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001696:	00f57793          	andi	a5,a0,15
    8000169a:	ff3782e3          	beq	a5,s3,8000167e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000169e:	8905                	andi	a0,a0,1
    800016a0:	d57d                	beqz	a0,8000168e <freewalk+0x2c>
      panic("freewalk: leaf");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	ace50513          	addi	a0,a0,-1330 # 80008170 <digits+0x130>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e98080e7          	jalr	-360(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    800016b2:	8552                	mv	a0,s4
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	35e080e7          	jalr	862(ra) # 80000a12 <kfree>
}
    800016bc:	70a2                	ld	ra,40(sp)
    800016be:	7402                	ld	s0,32(sp)
    800016c0:	64e2                	ld	s1,24(sp)
    800016c2:	6942                	ld	s2,16(sp)
    800016c4:	69a2                	ld	s3,8(sp)
    800016c6:	6a02                	ld	s4,0(sp)
    800016c8:	6145                	addi	sp,sp,48
    800016ca:	8082                	ret

00000000800016cc <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016cc:	1101                	addi	sp,sp,-32
    800016ce:	ec06                	sd	ra,24(sp)
    800016d0:	e822                	sd	s0,16(sp)
    800016d2:	e426                	sd	s1,8(sp)
    800016d4:	1000                	addi	s0,sp,32
    800016d6:	84aa                	mv	s1,a0
  if(sz > 0)
    800016d8:	e999                	bnez	a1,800016ee <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016da:	8526                	mv	a0,s1
    800016dc:	00000097          	auipc	ra,0x0
    800016e0:	f86080e7          	jalr	-122(ra) # 80001662 <freewalk>
}
    800016e4:	60e2                	ld	ra,24(sp)
    800016e6:	6442                	ld	s0,16(sp)
    800016e8:	64a2                	ld	s1,8(sp)
    800016ea:	6105                	addi	sp,sp,32
    800016ec:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016ee:	6605                	lui	a2,0x1
    800016f0:	167d                	addi	a2,a2,-1
    800016f2:	962e                	add	a2,a2,a1
    800016f4:	4685                	li	a3,1
    800016f6:	8231                	srli	a2,a2,0xc
    800016f8:	4581                	li	a1,0
    800016fa:	00000097          	auipc	ra,0x0
    800016fe:	d12080e7          	jalr	-750(ra) # 8000140c <uvmunmap>
    80001702:	bfe1                	j	800016da <uvmfree+0xe>

0000000080001704 <uvmcopy>:
修改uvmcopy函数，实现COW机制，父进程复制给子进程时,不为子进程分配内存,
而是将父进程的物理内存映射到子进程的虚拟地址上
*/
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001704:	715d                	addi	sp,sp,-80
    80001706:	e486                	sd	ra,72(sp)
    80001708:	e0a2                	sd	s0,64(sp)
    8000170a:	fc26                	sd	s1,56(sp)
    8000170c:	f84a                	sd	s2,48(sp)
    8000170e:	f44e                	sd	s3,40(sp)
    80001710:	f052                	sd	s4,32(sp)
    80001712:	ec56                	sd	s5,24(sp)
    80001714:	e85a                	sd	s6,16(sp)
    80001716:	e45e                	sd	s7,8(sp)
    80001718:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000171a:	c269                	beqz	a2,800017dc <uvmcopy+0xd8>
    8000171c:	8aaa                	mv	s5,a0
    8000171e:	8a2e                	mv	s4,a1
    80001720:	89b2                	mv	s3,a2
    80001722:	4481                	li	s1,0
    if(flags & PTE_W)
    {
      //禁用写并设置COW Fork标记
      //关闭写标记,表示为COW页面，触发cause == 15异常
      flags = (flags | PTE_F) & ~PTE_W;
      *pte = PA2PTE(pa) | flags;
    80001724:	7b7d                	lui	s6,0xfffff
    80001726:	002b5b13          	srli	s6,s6,0x2
    8000172a:	a8a1                	j	80001782 <uvmcopy+0x7e>
      panic("uvmcopy: pte should exist");
    8000172c:	00007517          	auipc	a0,0x7
    80001730:	a5450513          	addi	a0,a0,-1452 # 80008180 <digits+0x140>
    80001734:	fffff097          	auipc	ra,0xfffff
    80001738:	e0e080e7          	jalr	-498(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    8000173c:	00007517          	auipc	a0,0x7
    80001740:	a6450513          	addi	a0,a0,-1436 # 800081a0 <digits+0x160>
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	dfe080e7          	jalr	-514(ra) # 80000542 <panic>
      flags = (flags | PTE_F) & ~PTE_W;
    8000174c:	3fb77693          	andi	a3,a4,1019
    80001750:	1006e713          	ori	a4,a3,256
      *pte = PA2PTE(pa) | flags;
    80001754:	0167f7b3          	and	a5,a5,s6
    80001758:	8fd9                	or	a5,a5,a4
    8000175a:	e11c                	sd	a5,0(a0)
    }
    if(mappages(new, i, PGSIZE, pa, flags) != 0)
    8000175c:	86ca                	mv	a3,s2
    8000175e:	6605                	lui	a2,0x1
    80001760:	85a6                	mv	a1,s1
    80001762:	8552                	mv	a0,s4
    80001764:	00000097          	auipc	ra,0x0
    80001768:	b10080e7          	jalr	-1264(ra) # 80001274 <mappages>
    8000176c:	8baa                	mv	s7,a0
    8000176e:	e129                	bnez	a0,800017b0 <uvmcopy+0xac>
    {
      uvmunmap(new, 0, i / PGSIZE, 1);
      return -1;
    }
    //增加内存引用计数
    kaddrefcnt((char*)pa);
    80001770:	854a                	mv	a0,s2
    80001772:	fffff097          	auipc	ra,0xfffff
    80001776:	4dc080e7          	jalr	1244(ra) # 80000c4e <kaddrefcnt>
  for(i = 0; i < sz; i += PGSIZE){
    8000177a:	6785                	lui	a5,0x1
    8000177c:	94be                	add	s1,s1,a5
    8000177e:	0534f363          	bgeu	s1,s3,800017c4 <uvmcopy+0xc0>
    if((pte = walk(old, i, 0)) == 0)
    80001782:	4601                	li	a2,0
    80001784:	85a6                	mv	a1,s1
    80001786:	8556                	mv	a0,s5
    80001788:	00000097          	auipc	ra,0x0
    8000178c:	9a6080e7          	jalr	-1626(ra) # 8000112e <walk>
    80001790:	dd51                	beqz	a0,8000172c <uvmcopy+0x28>
    if((*pte & PTE_V) == 0)
    80001792:	611c                	ld	a5,0(a0)
    80001794:	0017f713          	andi	a4,a5,1
    80001798:	d355                	beqz	a4,8000173c <uvmcopy+0x38>
    pa = PTE2PA(*pte);
    8000179a:	00a7d913          	srli	s2,a5,0xa
    8000179e:	0932                	slli	s2,s2,0xc
    flags = PTE_FLAGS(*pte);
    800017a0:	0007871b          	sext.w	a4,a5
    if(flags & PTE_W)
    800017a4:	0047f693          	andi	a3,a5,4
    800017a8:	f2d5                	bnez	a3,8000174c <uvmcopy+0x48>
    flags = PTE_FLAGS(*pte);
    800017aa:	3ff77713          	andi	a4,a4,1023
    800017ae:	b77d                	j	8000175c <uvmcopy+0x58>
      uvmunmap(new, 0, i / PGSIZE, 1);
    800017b0:	4685                	li	a3,1
    800017b2:	00c4d613          	srli	a2,s1,0xc
    800017b6:	4581                	li	a1,0
    800017b8:	8552                	mv	a0,s4
    800017ba:	00000097          	auipc	ra,0x0
    800017be:	c52080e7          	jalr	-942(ra) # 8000140c <uvmunmap>
      return -1;
    800017c2:	5bfd                	li	s7,-1
  return 0;

//  err:
//   uvmunmap(new, 0, i / PGSIZE, 1);
//   return -1;
}
    800017c4:	855e                	mv	a0,s7
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
  return 0;
    800017dc:	4b81                	li	s7,0
    800017de:	b7dd                	j	800017c4 <uvmcopy+0xc0>

00000000800017e0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017e0:	1141                	addi	sp,sp,-16
    800017e2:	e406                	sd	ra,8(sp)
    800017e4:	e022                	sd	s0,0(sp)
    800017e6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017e8:	4601                	li	a2,0
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	944080e7          	jalr	-1724(ra) # 8000112e <walk>
  if(pte == 0)
    800017f2:	c901                	beqz	a0,80001802 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017f4:	611c                	ld	a5,0(a0)
    800017f6:	9bbd                	andi	a5,a5,-17
    800017f8:	e11c                	sd	a5,0(a0)
}
    800017fa:	60a2                	ld	ra,8(sp)
    800017fc:	6402                	ld	s0,0(sp)
    800017fe:	0141                	addi	sp,sp,16
    80001800:	8082                	ret
    panic("uvmclear");
    80001802:	00007517          	auipc	a0,0x7
    80001806:	9be50513          	addi	a0,a0,-1602 # 800081c0 <digits+0x180>
    8000180a:	fffff097          	auipc	ra,0xfffff
    8000180e:	d38080e7          	jalr	-712(ra) # 80000542 <panic>

0000000080001812 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001812:	caa5                	beqz	a3,80001882 <copyin+0x70>
{
    80001814:	715d                	addi	sp,sp,-80
    80001816:	e486                	sd	ra,72(sp)
    80001818:	e0a2                	sd	s0,64(sp)
    8000181a:	fc26                	sd	s1,56(sp)
    8000181c:	f84a                	sd	s2,48(sp)
    8000181e:	f44e                	sd	s3,40(sp)
    80001820:	f052                	sd	s4,32(sp)
    80001822:	ec56                	sd	s5,24(sp)
    80001824:	e85a                	sd	s6,16(sp)
    80001826:	e45e                	sd	s7,8(sp)
    80001828:	e062                	sd	s8,0(sp)
    8000182a:	0880                	addi	s0,sp,80
    8000182c:	8b2a                	mv	s6,a0
    8000182e:	8a2e                	mv	s4,a1
    80001830:	8c32                	mv	s8,a2
    80001832:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001834:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001836:	6a85                	lui	s5,0x1
    80001838:	a01d                	j	8000185e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000183a:	018505b3          	add	a1,a0,s8
    8000183e:	0004861b          	sext.w	a2,s1
    80001842:	412585b3          	sub	a1,a1,s2
    80001846:	8552                	mv	a0,s4
    80001848:	fffff097          	auipc	ra,0xfffff
    8000184c:	65a080e7          	jalr	1626(ra) # 80000ea2 <memmove>

    len -= n;
    80001850:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001854:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001856:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000185a:	02098263          	beqz	s3,8000187e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000185e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001862:	85ca                	mv	a1,s2
    80001864:	855a                	mv	a0,s6
    80001866:	00000097          	auipc	ra,0x0
    8000186a:	96e080e7          	jalr	-1682(ra) # 800011d4 <walkaddr>
    if(pa0 == 0)
    8000186e:	cd01                	beqz	a0,80001886 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001870:	418904b3          	sub	s1,s2,s8
    80001874:	94d6                	add	s1,s1,s5
    if(n > len)
    80001876:	fc99f2e3          	bgeu	s3,s1,8000183a <copyin+0x28>
    8000187a:	84ce                	mv	s1,s3
    8000187c:	bf7d                	j	8000183a <copyin+0x28>
  }
  return 0;
    8000187e:	4501                	li	a0,0
    80001880:	a021                	j	80001888 <copyin+0x76>
    80001882:	4501                	li	a0,0
}
    80001884:	8082                	ret
      return -1;
    80001886:	557d                	li	a0,-1
}
    80001888:	60a6                	ld	ra,72(sp)
    8000188a:	6406                	ld	s0,64(sp)
    8000188c:	74e2                	ld	s1,56(sp)
    8000188e:	7942                	ld	s2,48(sp)
    80001890:	79a2                	ld	s3,40(sp)
    80001892:	7a02                	ld	s4,32(sp)
    80001894:	6ae2                	ld	s5,24(sp)
    80001896:	6b42                	ld	s6,16(sp)
    80001898:	6ba2                	ld	s7,8(sp)
    8000189a:	6c02                	ld	s8,0(sp)
    8000189c:	6161                	addi	sp,sp,80
    8000189e:	8082                	ret

00000000800018a0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018a0:	c6c5                	beqz	a3,80001948 <copyinstr+0xa8>
{
    800018a2:	715d                	addi	sp,sp,-80
    800018a4:	e486                	sd	ra,72(sp)
    800018a6:	e0a2                	sd	s0,64(sp)
    800018a8:	fc26                	sd	s1,56(sp)
    800018aa:	f84a                	sd	s2,48(sp)
    800018ac:	f44e                	sd	s3,40(sp)
    800018ae:	f052                	sd	s4,32(sp)
    800018b0:	ec56                	sd	s5,24(sp)
    800018b2:	e85a                	sd	s6,16(sp)
    800018b4:	e45e                	sd	s7,8(sp)
    800018b6:	0880                	addi	s0,sp,80
    800018b8:	8a2a                	mv	s4,a0
    800018ba:	8b2e                	mv	s6,a1
    800018bc:	8bb2                	mv	s7,a2
    800018be:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018c0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018c2:	6985                	lui	s3,0x1
    800018c4:	a035                	j	800018f0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018c6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018ca:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018cc:	0017b793          	seqz	a5,a5
    800018d0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018d4:	60a6                	ld	ra,72(sp)
    800018d6:	6406                	ld	s0,64(sp)
    800018d8:	74e2                	ld	s1,56(sp)
    800018da:	7942                	ld	s2,48(sp)
    800018dc:	79a2                	ld	s3,40(sp)
    800018de:	7a02                	ld	s4,32(sp)
    800018e0:	6ae2                	ld	s5,24(sp)
    800018e2:	6b42                	ld	s6,16(sp)
    800018e4:	6ba2                	ld	s7,8(sp)
    800018e6:	6161                	addi	sp,sp,80
    800018e8:	8082                	ret
    srcva = va0 + PGSIZE;
    800018ea:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018ee:	c8a9                	beqz	s1,80001940 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018f0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018f4:	85ca                	mv	a1,s2
    800018f6:	8552                	mv	a0,s4
    800018f8:	00000097          	auipc	ra,0x0
    800018fc:	8dc080e7          	jalr	-1828(ra) # 800011d4 <walkaddr>
    if(pa0 == 0)
    80001900:	c131                	beqz	a0,80001944 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001902:	41790833          	sub	a6,s2,s7
    80001906:	984e                	add	a6,a6,s3
    if(n > max)
    80001908:	0104f363          	bgeu	s1,a6,8000190e <copyinstr+0x6e>
    8000190c:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000190e:	955e                	add	a0,a0,s7
    80001910:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001914:	fc080be3          	beqz	a6,800018ea <copyinstr+0x4a>
    80001918:	985a                	add	a6,a6,s6
    8000191a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000191c:	41650633          	sub	a2,a0,s6
    80001920:	14fd                	addi	s1,s1,-1
    80001922:	9b26                	add	s6,s6,s1
    80001924:	00f60733          	add	a4,a2,a5
    80001928:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdb9000>
    8000192c:	df49                	beqz	a4,800018c6 <copyinstr+0x26>
        *dst = *p;
    8000192e:	00e78023          	sb	a4,0(a5)
      --max;
    80001932:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001936:	0785                	addi	a5,a5,1
    while(n > 0){
    80001938:	ff0796e3          	bne	a5,a6,80001924 <copyinstr+0x84>
      dst++;
    8000193c:	8b42                	mv	s6,a6
    8000193e:	b775                	j	800018ea <copyinstr+0x4a>
    80001940:	4781                	li	a5,0
    80001942:	b769                	j	800018cc <copyinstr+0x2c>
      return -1;
    80001944:	557d                	li	a0,-1
    80001946:	b779                	j	800018d4 <copyinstr+0x34>
  int got_null = 0;
    80001948:	4781                	li	a5,0
  if(got_null){
    8000194a:	0017b793          	seqz	a5,a5
    8000194e:	40f00533          	neg	a0,a5
}
    80001952:	8082                	ret

0000000080001954 <cowpage>:
 * @param pagetable 指定查询的页表
 * @param va 虚拟地址
 * @return 0 是 -1 不是
 */
int cowpage(pagetable_t pagetable, uint64 va) {
  if(va >= MAXVA)
    80001954:	57fd                	li	a5,-1
    80001956:	83e9                	srli	a5,a5,0x1a
    80001958:	02b7e963          	bltu	a5,a1,8000198a <cowpage+0x36>
int cowpage(pagetable_t pagetable, uint64 va) {
    8000195c:	1141                	addi	sp,sp,-16
    8000195e:	e406                	sd	ra,8(sp)
    80001960:	e022                	sd	s0,0(sp)
    80001962:	0800                	addi	s0,sp,16
    return -1;
  pte_t* pte = walk(pagetable, va, 0);
    80001964:	4601                	li	a2,0
    80001966:	fffff097          	auipc	ra,0xfffff
    8000196a:	7c8080e7          	jalr	1992(ra) # 8000112e <walk>
  if(pte == 0)
    8000196e:	c105                	beqz	a0,8000198e <cowpage+0x3a>
    return -1;
  if((*pte & PTE_V) == 0)
    return -1;
  return (*pte & PTE_F ? 0 : -1);
    80001970:	6108                	ld	a0,0(a0)
    80001972:	10157513          	andi	a0,a0,257
    80001976:	eff50513          	addi	a0,a0,-257
    8000197a:	00a03533          	snez	a0,a0
    8000197e:	40a00533          	neg	a0,a0
}
    80001982:	60a2                	ld	ra,8(sp)
    80001984:	6402                	ld	s0,0(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret
    return -1;
    8000198a:	557d                	li	a0,-1
}
    8000198c:	8082                	ret
    return -1;
    8000198e:	557d                	li	a0,-1
    80001990:	bfcd                	j	80001982 <cowpage+0x2e>

0000000080001992 <cowalloc>:
 * @brief uvmcow 实现COW机制
 * @param pagetable 指定查询的页表
 * @param va 虚拟地址
 * @return 0 成功 -1 失败
 */
void* cowalloc(pagetable_t pagetable, uint64 va) {
    80001992:	7139                	addi	sp,sp,-64
    80001994:	fc06                	sd	ra,56(sp)
    80001996:	f822                	sd	s0,48(sp)
    80001998:	f426                	sd	s1,40(sp)
    8000199a:	f04a                	sd	s2,32(sp)
    8000199c:	ec4e                	sd	s3,24(sp)
    8000199e:	e852                	sd	s4,16(sp)
    800019a0:	e456                	sd	s5,8(sp)
    800019a2:	0080                	addi	s0,sp,64
  if(va % PGSIZE != 0)
    800019a4:	03459793          	slli	a5,a1,0x34
    return 0;
    800019a8:	4901                	li	s2,0
  if(va % PGSIZE != 0)
    800019aa:	efbd                	bnez	a5,80001a28 <cowalloc+0x96>
    800019ac:	89aa                	mv	s3,a0
    800019ae:	84ae                	mv	s1,a1

  uint64 pa = walkaddr(pagetable, va);  // 获取对应的物理地址
    800019b0:	00000097          	auipc	ra,0x0
    800019b4:	824080e7          	jalr	-2012(ra) # 800011d4 <walkaddr>
    800019b8:	8a2a                	mv	s4,a0
  if(pa == 0)
    return 0;
    800019ba:	4901                	li	s2,0
  if(pa == 0)
    800019bc:	c535                	beqz	a0,80001a28 <cowalloc+0x96>

  pte_t* pte = walk(pagetable, va, 0);  // 获取对应的PTE
    800019be:	4601                	li	a2,0
    800019c0:	85a6                	mv	a1,s1
    800019c2:	854e                	mv	a0,s3
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	76a080e7          	jalr	1898(ra) # 8000112e <walk>
    800019cc:	8aaa                	mv	s5,a0

  if(krefcnt((char*)pa) == 1) {
    800019ce:	8552                	mv	a0,s4
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	260080e7          	jalr	608(ra) # 80000c30 <krefcnt>
    800019d8:	4785                	li	a5,1
    800019da:	06f50163          	beq	a0,a5,80001a3c <cowalloc+0xaa>
    *pte &= ~PTE_F;
    return (void*)pa;
  } else {
    // 多个进程对物理内存存在引用
    // 需要分配新的页面，并拷贝旧页面的内容
    char* mem = kalloc();
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	1bc080e7          	jalr	444(ra) # 80000b9a <kalloc>
    800019e6:	892a                	mv	s2,a0
    if(mem == 0)
    800019e8:	c121                	beqz	a0,80001a28 <cowalloc+0x96>
      return 0;

    // 复制旧页面内容到新页
    memmove(mem, (char*)pa, PGSIZE);
    800019ea:	6605                	lui	a2,0x1
    800019ec:	85d2                	mv	a1,s4
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	4b4080e7          	jalr	1204(ra) # 80000ea2 <memmove>

    // 清除PTE_V，否则在mappagges中会判定为remap
    *pte &= ~PTE_V;
    800019f6:	000ab703          	ld	a4,0(s5) # fffffffffffff000 <end+0xffffffff7fdb9000>
    800019fa:	9b79                	andi	a4,a4,-2
    800019fc:	00eab023          	sd	a4,0(s5)

    // 为新页面添加映射
    if(mappages(pagetable, va, PGSIZE, (uint64)mem, (PTE_FLAGS(*pte) | PTE_W) & ~PTE_F) != 0) {
    80001a00:	2fb77713          	andi	a4,a4,763
    80001a04:	00476713          	ori	a4,a4,4
    80001a08:	86ca                	mv	a3,s2
    80001a0a:	6605                	lui	a2,0x1
    80001a0c:	85a6                	mv	a1,s1
    80001a0e:	854e                	mv	a0,s3
    80001a10:	00000097          	auipc	ra,0x0
    80001a14:	864080e7          	jalr	-1948(ra) # 80001274 <mappages>
    80001a18:	ed05                	bnez	a0,80001a50 <cowalloc+0xbe>
      *pte |= PTE_V;
      return 0;
    }

    // 将原来的物理内存引用计数减1,因为已经将一个引用重分配了物理内存
    kfree((char*)PGROUNDDOWN(pa));
    80001a1a:	757d                	lui	a0,0xfffff
    80001a1c:	00aa7533          	and	a0,s4,a0
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	ff2080e7          	jalr	-14(ra) # 80000a12 <kfree>
    return mem;
  }
}
    80001a28:	854a                	mv	a0,s2
    80001a2a:	70e2                	ld	ra,56(sp)
    80001a2c:	7442                	ld	s0,48(sp)
    80001a2e:	74a2                	ld	s1,40(sp)
    80001a30:	7902                	ld	s2,32(sp)
    80001a32:	69e2                	ld	s3,24(sp)
    80001a34:	6a42                	ld	s4,16(sp)
    80001a36:	6aa2                	ld	s5,8(sp)
    80001a38:	6121                	addi	sp,sp,64
    80001a3a:	8082                	ret
    *pte &= ~PTE_F;
    80001a3c:	000ab783          	ld	a5,0(s5)
    80001a40:	eff7f793          	andi	a5,a5,-257
    80001a44:	0047e793          	ori	a5,a5,4
    80001a48:	00fab023          	sd	a5,0(s5)
    return (void*)pa;
    80001a4c:	8952                	mv	s2,s4
    80001a4e:	bfe9                	j	80001a28 <cowalloc+0x96>
      kfree(mem);
    80001a50:	854a                	mv	a0,s2
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	fc0080e7          	jalr	-64(ra) # 80000a12 <kfree>
      *pte |= PTE_V;
    80001a5a:	000ab783          	ld	a5,0(s5)
    80001a5e:	0017e793          	ori	a5,a5,1
    80001a62:	00fab023          	sd	a5,0(s5)
      return 0;
    80001a66:	4901                	li	s2,0
    80001a68:	b7c1                	j	80001a28 <cowalloc+0x96>

0000000080001a6a <copyout>:
  while(len > 0){
    80001a6a:	cac9                	beqz	a3,80001afc <copyout+0x92>
{
    80001a6c:	711d                	addi	sp,sp,-96
    80001a6e:	ec86                	sd	ra,88(sp)
    80001a70:	e8a2                	sd	s0,80(sp)
    80001a72:	e4a6                	sd	s1,72(sp)
    80001a74:	e0ca                	sd	s2,64(sp)
    80001a76:	fc4e                	sd	s3,56(sp)
    80001a78:	f852                	sd	s4,48(sp)
    80001a7a:	f456                	sd	s5,40(sp)
    80001a7c:	f05a                	sd	s6,32(sp)
    80001a7e:	ec5e                	sd	s7,24(sp)
    80001a80:	e862                	sd	s8,16(sp)
    80001a82:	e466                	sd	s9,8(sp)
    80001a84:	1080                	addi	s0,sp,96
    80001a86:	8baa                	mv	s7,a0
    80001a88:	89ae                	mv	s3,a1
    80001a8a:	8b32                	mv	s6,a2
    80001a8c:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    80001a8e:	7cfd                	lui	s9,0xfffff
    n = PGSIZE - (dstva - va0);
    80001a90:	6c05                	lui	s8,0x1
    80001a92:	a815                	j	80001ac6 <copyout+0x5c>
    pa0 = (uint64)cowalloc(pagetable, va0);
    80001a94:	85ca                	mv	a1,s2
    80001a96:	855e                	mv	a0,s7
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	efa080e7          	jalr	-262(ra) # 80001992 <cowalloc>
    80001aa0:	8a2a                	mv	s4,a0
    80001aa2:	a091                	j	80001ae6 <copyout+0x7c>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001aa4:	41298533          	sub	a0,s3,s2
    80001aa8:	0004861b          	sext.w	a2,s1
    80001aac:	85da                	mv	a1,s6
    80001aae:	9552                	add	a0,a0,s4
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	3f2080e7          	jalr	1010(ra) # 80000ea2 <memmove>
    len -= n;
    80001ab8:	409a8ab3          	sub	s5,s5,s1
    src += n;
    80001abc:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    80001abe:	018909b3          	add	s3,s2,s8
  while(len > 0){
    80001ac2:	020a8b63          	beqz	s5,80001af8 <copyout+0x8e>
    va0 = PGROUNDDOWN(dstva);
    80001ac6:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    80001aca:	85ca                	mv	a1,s2
    80001acc:	855e                	mv	a0,s7
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	706080e7          	jalr	1798(ra) # 800011d4 <walkaddr>
    80001ad6:	8a2a                	mv	s4,a0
  if(cowpage(pagetable, va0) == 0) {
    80001ad8:	85ca                	mv	a1,s2
    80001ada:	855e                	mv	a0,s7
    80001adc:	00000097          	auipc	ra,0x0
    80001ae0:	e78080e7          	jalr	-392(ra) # 80001954 <cowpage>
    80001ae4:	d945                	beqz	a0,80001a94 <copyout+0x2a>
    if(pa0 == 0)
    80001ae6:	000a0d63          	beqz	s4,80001b00 <copyout+0x96>
    n = PGSIZE - (dstva - va0);
    80001aea:	413904b3          	sub	s1,s2,s3
    80001aee:	94e2                	add	s1,s1,s8
    if(n > len)
    80001af0:	fa9afae3          	bgeu	s5,s1,80001aa4 <copyout+0x3a>
    80001af4:	84d6                	mv	s1,s5
    80001af6:	b77d                	j	80001aa4 <copyout+0x3a>
  return 0;
    80001af8:	4501                	li	a0,0
    80001afa:	a021                	j	80001b02 <copyout+0x98>
    80001afc:	4501                	li	a0,0
}
    80001afe:	8082                	ret
      return -1;
    80001b00:	557d                	li	a0,-1
}
    80001b02:	60e6                	ld	ra,88(sp)
    80001b04:	6446                	ld	s0,80(sp)
    80001b06:	64a6                	ld	s1,72(sp)
    80001b08:	6906                	ld	s2,64(sp)
    80001b0a:	79e2                	ld	s3,56(sp)
    80001b0c:	7a42                	ld	s4,48(sp)
    80001b0e:	7aa2                	ld	s5,40(sp)
    80001b10:	7b02                	ld	s6,32(sp)
    80001b12:	6be2                	ld	s7,24(sp)
    80001b14:	6c42                	ld	s8,16(sp)
    80001b16:	6ca2                	ld	s9,8(sp)
    80001b18:	6125                	addi	sp,sp,96
    80001b1a:	8082                	ret

0000000080001b1c <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001b1c:	1101                	addi	sp,sp,-32
    80001b1e:	ec06                	sd	ra,24(sp)
    80001b20:	e822                	sd	s0,16(sp)
    80001b22:	e426                	sd	s1,8(sp)
    80001b24:	1000                	addi	s0,sp,32
    80001b26:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	1a8080e7          	jalr	424(ra) # 80000cd0 <holding>
    80001b30:	c909                	beqz	a0,80001b42 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001b32:	749c                	ld	a5,40(s1)
    80001b34:	00978f63          	beq	a5,s1,80001b52 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001b38:	60e2                	ld	ra,24(sp)
    80001b3a:	6442                	ld	s0,16(sp)
    80001b3c:	64a2                	ld	s1,8(sp)
    80001b3e:	6105                	addi	sp,sp,32
    80001b40:	8082                	ret
    panic("wakeup1");
    80001b42:	00006517          	auipc	a0,0x6
    80001b46:	68e50513          	addi	a0,a0,1678 # 800081d0 <digits+0x190>
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	9f8080e7          	jalr	-1544(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001b52:	4c98                	lw	a4,24(s1)
    80001b54:	4785                	li	a5,1
    80001b56:	fef711e3          	bne	a4,a5,80001b38 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001b5a:	4789                	li	a5,2
    80001b5c:	cc9c                	sw	a5,24(s1)
}
    80001b5e:	bfe9                	j	80001b38 <wakeup1+0x1c>

0000000080001b60 <procinit>:
{
    80001b60:	715d                	addi	sp,sp,-80
    80001b62:	e486                	sd	ra,72(sp)
    80001b64:	e0a2                	sd	s0,64(sp)
    80001b66:	fc26                	sd	s1,56(sp)
    80001b68:	f84a                	sd	s2,48(sp)
    80001b6a:	f44e                	sd	s3,40(sp)
    80001b6c:	f052                	sd	s4,32(sp)
    80001b6e:	ec56                	sd	s5,24(sp)
    80001b70:	e85a                	sd	s6,16(sp)
    80001b72:	e45e                	sd	s7,8(sp)
    80001b74:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001b76:	00006597          	auipc	a1,0x6
    80001b7a:	66258593          	addi	a1,a1,1634 # 800081d8 <digits+0x198>
    80001b7e:	00230517          	auipc	a0,0x230
    80001b82:	dea50513          	addi	a0,a0,-534 # 80231968 <pid_lock>
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	134080e7          	jalr	308(ra) # 80000cba <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b8e:	00230917          	auipc	s2,0x230
    80001b92:	1f290913          	addi	s2,s2,498 # 80231d80 <proc>
      initlock(&p->lock, "proc");
    80001b96:	00006b97          	auipc	s7,0x6
    80001b9a:	64ab8b93          	addi	s7,s7,1610 # 800081e0 <digits+0x1a0>
      uint64 va = KSTACK((int) (p - proc));
    80001b9e:	8b4a                	mv	s6,s2
    80001ba0:	00006a97          	auipc	s5,0x6
    80001ba4:	460a8a93          	addi	s5,s5,1120 # 80008000 <etext>
    80001ba8:	040009b7          	lui	s3,0x4000
    80001bac:	19fd                	addi	s3,s3,-1
    80001bae:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb0:	00236a17          	auipc	s4,0x236
    80001bb4:	bd0a0a13          	addi	s4,s4,-1072 # 80237780 <tickslock>
      initlock(&p->lock, "proc");
    80001bb8:	85de                	mv	a1,s7
    80001bba:	854a                	mv	a0,s2
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	0fe080e7          	jalr	254(ra) # 80000cba <initlock>
      char *pa = kalloc();
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	fd6080e7          	jalr	-42(ra) # 80000b9a <kalloc>
    80001bcc:	85aa                	mv	a1,a0
      if(pa == 0)
    80001bce:	c929                	beqz	a0,80001c20 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001bd0:	416904b3          	sub	s1,s2,s6
    80001bd4:	848d                	srai	s1,s1,0x3
    80001bd6:	000ab783          	ld	a5,0(s5)
    80001bda:	02f484b3          	mul	s1,s1,a5
    80001bde:	2485                	addiw	s1,s1,1
    80001be0:	00d4949b          	slliw	s1,s1,0xd
    80001be4:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001be8:	4699                	li	a3,6
    80001bea:	6605                	lui	a2,0x1
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	714080e7          	jalr	1812(ra) # 80001302 <kvmmap>
      p->kstack = va;
    80001bf6:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfa:	16890913          	addi	s2,s2,360
    80001bfe:	fb491de3          	bne	s2,s4,80001bb8 <procinit+0x58>
  kvminithart();
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	508080e7          	jalr	1288(ra) # 8000110a <kvminithart>
}
    80001c0a:	60a6                	ld	ra,72(sp)
    80001c0c:	6406                	ld	s0,64(sp)
    80001c0e:	74e2                	ld	s1,56(sp)
    80001c10:	7942                	ld	s2,48(sp)
    80001c12:	79a2                	ld	s3,40(sp)
    80001c14:	7a02                	ld	s4,32(sp)
    80001c16:	6ae2                	ld	s5,24(sp)
    80001c18:	6b42                	ld	s6,16(sp)
    80001c1a:	6ba2                	ld	s7,8(sp)
    80001c1c:	6161                	addi	sp,sp,80
    80001c1e:	8082                	ret
        panic("kalloc");
    80001c20:	00006517          	auipc	a0,0x6
    80001c24:	5c850513          	addi	a0,a0,1480 # 800081e8 <digits+0x1a8>
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	91a080e7          	jalr	-1766(ra) # 80000542 <panic>

0000000080001c30 <cpuid>:
{
    80001c30:	1141                	addi	sp,sp,-16
    80001c32:	e422                	sd	s0,8(sp)
    80001c34:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c36:	8512                	mv	a0,tp
}
    80001c38:	2501                	sext.w	a0,a0
    80001c3a:	6422                	ld	s0,8(sp)
    80001c3c:	0141                	addi	sp,sp,16
    80001c3e:	8082                	ret

0000000080001c40 <mycpu>:
mycpu(void) {
    80001c40:	1141                	addi	sp,sp,-16
    80001c42:	e422                	sd	s0,8(sp)
    80001c44:	0800                	addi	s0,sp,16
    80001c46:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001c48:	2781                	sext.w	a5,a5
    80001c4a:	079e                	slli	a5,a5,0x7
}
    80001c4c:	00230517          	auipc	a0,0x230
    80001c50:	d3450513          	addi	a0,a0,-716 # 80231980 <cpus>
    80001c54:	953e                	add	a0,a0,a5
    80001c56:	6422                	ld	s0,8(sp)
    80001c58:	0141                	addi	sp,sp,16
    80001c5a:	8082                	ret

0000000080001c5c <myproc>:
myproc(void) {
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	1000                	addi	s0,sp,32
  push_off();
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	098080e7          	jalr	152(ra) # 80000cfe <push_off>
    80001c6e:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001c70:	2781                	sext.w	a5,a5
    80001c72:	079e                	slli	a5,a5,0x7
    80001c74:	00230717          	auipc	a4,0x230
    80001c78:	cf470713          	addi	a4,a4,-780 # 80231968 <pid_lock>
    80001c7c:	97ba                	add	a5,a5,a4
    80001c7e:	6f84                	ld	s1,24(a5)
  pop_off();
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	11e080e7          	jalr	286(ra) # 80000d9e <pop_off>
}
    80001c88:	8526                	mv	a0,s1
    80001c8a:	60e2                	ld	ra,24(sp)
    80001c8c:	6442                	ld	s0,16(sp)
    80001c8e:	64a2                	ld	s1,8(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret

0000000080001c94 <forkret>:
{
    80001c94:	1141                	addi	sp,sp,-16
    80001c96:	e406                	sd	ra,8(sp)
    80001c98:	e022                	sd	s0,0(sp)
    80001c9a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	fc0080e7          	jalr	-64(ra) # 80001c5c <myproc>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	15a080e7          	jalr	346(ra) # 80000dfe <release>
  if (first) {
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	b747a783          	lw	a5,-1164(a5) # 80008820 <first.1>
    80001cb4:	eb89                	bnez	a5,80001cc6 <forkret+0x32>
  usertrapret();
    80001cb6:	00001097          	auipc	ra,0x1
    80001cba:	c18080e7          	jalr	-1000(ra) # 800028ce <usertrapret>
}
    80001cbe:	60a2                	ld	ra,8(sp)
    80001cc0:	6402                	ld	s0,0(sp)
    80001cc2:	0141                	addi	sp,sp,16
    80001cc4:	8082                	ret
    first = 0;
    80001cc6:	00007797          	auipc	a5,0x7
    80001cca:	b407ad23          	sw	zero,-1190(a5) # 80008820 <first.1>
    fsinit(ROOTDEV);
    80001cce:	4505                	li	a0,1
    80001cd0:	00002097          	auipc	ra,0x2
    80001cd4:	988080e7          	jalr	-1656(ra) # 80003658 <fsinit>
    80001cd8:	bff9                	j	80001cb6 <forkret+0x22>

0000000080001cda <allocpid>:
allocpid() {
    80001cda:	1101                	addi	sp,sp,-32
    80001cdc:	ec06                	sd	ra,24(sp)
    80001cde:	e822                	sd	s0,16(sp)
    80001ce0:	e426                	sd	s1,8(sp)
    80001ce2:	e04a                	sd	s2,0(sp)
    80001ce4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ce6:	00230917          	auipc	s2,0x230
    80001cea:	c8290913          	addi	s2,s2,-894 # 80231968 <pid_lock>
    80001cee:	854a                	mv	a0,s2
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	05a080e7          	jalr	90(ra) # 80000d4a <acquire>
  pid = nextpid;
    80001cf8:	00007797          	auipc	a5,0x7
    80001cfc:	b2c78793          	addi	a5,a5,-1236 # 80008824 <nextpid>
    80001d00:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d02:	0014871b          	addiw	a4,s1,1
    80001d06:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d08:	854a                	mv	a0,s2
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	0f4080e7          	jalr	244(ra) # 80000dfe <release>
}
    80001d12:	8526                	mv	a0,s1
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6902                	ld	s2,0(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <proc_pagetable>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	7a2080e7          	jalr	1954(ra) # 800014d0 <uvmcreate>
    80001d36:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d38:	c121                	beqz	a0,80001d78 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d3a:	4729                	li	a4,10
    80001d3c:	00005697          	auipc	a3,0x5
    80001d40:	2c468693          	addi	a3,a3,708 # 80007000 <_trampoline>
    80001d44:	6605                	lui	a2,0x1
    80001d46:	040005b7          	lui	a1,0x4000
    80001d4a:	15fd                	addi	a1,a1,-1
    80001d4c:	05b2                	slli	a1,a1,0xc
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	526080e7          	jalr	1318(ra) # 80001274 <mappages>
    80001d56:	02054863          	bltz	a0,80001d86 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d5a:	4719                	li	a4,6
    80001d5c:	05893683          	ld	a3,88(s2)
    80001d60:	6605                	lui	a2,0x1
    80001d62:	020005b7          	lui	a1,0x2000
    80001d66:	15fd                	addi	a1,a1,-1
    80001d68:	05b6                	slli	a1,a1,0xd
    80001d6a:	8526                	mv	a0,s1
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	508080e7          	jalr	1288(ra) # 80001274 <mappages>
    80001d74:	02054163          	bltz	a0,80001d96 <proc_pagetable+0x76>
}
    80001d78:	8526                	mv	a0,s1
    80001d7a:	60e2                	ld	ra,24(sp)
    80001d7c:	6442                	ld	s0,16(sp)
    80001d7e:	64a2                	ld	s1,8(sp)
    80001d80:	6902                	ld	s2,0(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret
    uvmfree(pagetable, 0);
    80001d86:	4581                	li	a1,0
    80001d88:	8526                	mv	a0,s1
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	942080e7          	jalr	-1726(ra) # 800016cc <uvmfree>
    return 0;
    80001d92:	4481                	li	s1,0
    80001d94:	b7d5                	j	80001d78 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d96:	4681                	li	a3,0
    80001d98:	4605                	li	a2,1
    80001d9a:	040005b7          	lui	a1,0x4000
    80001d9e:	15fd                	addi	a1,a1,-1
    80001da0:	05b2                	slli	a1,a1,0xc
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	668080e7          	jalr	1640(ra) # 8000140c <uvmunmap>
    uvmfree(pagetable, 0);
    80001dac:	4581                	li	a1,0
    80001dae:	8526                	mv	a0,s1
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	91c080e7          	jalr	-1764(ra) # 800016cc <uvmfree>
    return 0;
    80001db8:	4481                	li	s1,0
    80001dba:	bf7d                	j	80001d78 <proc_pagetable+0x58>

0000000080001dbc <proc_freepagetable>:
{
    80001dbc:	1101                	addi	sp,sp,-32
    80001dbe:	ec06                	sd	ra,24(sp)
    80001dc0:	e822                	sd	s0,16(sp)
    80001dc2:	e426                	sd	s1,8(sp)
    80001dc4:	e04a                	sd	s2,0(sp)
    80001dc6:	1000                	addi	s0,sp,32
    80001dc8:	84aa                	mv	s1,a0
    80001dca:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dcc:	4681                	li	a3,0
    80001dce:	4605                	li	a2,1
    80001dd0:	040005b7          	lui	a1,0x4000
    80001dd4:	15fd                	addi	a1,a1,-1
    80001dd6:	05b2                	slli	a1,a1,0xc
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	634080e7          	jalr	1588(ra) # 8000140c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001de0:	4681                	li	a3,0
    80001de2:	4605                	li	a2,1
    80001de4:	020005b7          	lui	a1,0x2000
    80001de8:	15fd                	addi	a1,a1,-1
    80001dea:	05b6                	slli	a1,a1,0xd
    80001dec:	8526                	mv	a0,s1
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	61e080e7          	jalr	1566(ra) # 8000140c <uvmunmap>
  uvmfree(pagetable, sz);
    80001df6:	85ca                	mv	a1,s2
    80001df8:	8526                	mv	a0,s1
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	8d2080e7          	jalr	-1838(ra) # 800016cc <uvmfree>
}
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6902                	ld	s2,0(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret

0000000080001e0e <freeproc>:
{
    80001e0e:	1101                	addi	sp,sp,-32
    80001e10:	ec06                	sd	ra,24(sp)
    80001e12:	e822                	sd	s0,16(sp)
    80001e14:	e426                	sd	s1,8(sp)
    80001e16:	1000                	addi	s0,sp,32
    80001e18:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e1a:	6d28                	ld	a0,88(a0)
    80001e1c:	c509                	beqz	a0,80001e26 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	bf4080e7          	jalr	-1036(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001e26:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e2a:	68a8                	ld	a0,80(s1)
    80001e2c:	c511                	beqz	a0,80001e38 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e2e:	64ac                	ld	a1,72(s1)
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	f8c080e7          	jalr	-116(ra) # 80001dbc <proc_freepagetable>
  p->pagetable = 0;
    80001e38:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e3c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e40:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001e44:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001e48:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e4c:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001e50:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001e54:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001e58:	0004ac23          	sw	zero,24(s1)
}
    80001e5c:	60e2                	ld	ra,24(sp)
    80001e5e:	6442                	ld	s0,16(sp)
    80001e60:	64a2                	ld	s1,8(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret

0000000080001e66 <allocproc>:
{
    80001e66:	1101                	addi	sp,sp,-32
    80001e68:	ec06                	sd	ra,24(sp)
    80001e6a:	e822                	sd	s0,16(sp)
    80001e6c:	e426                	sd	s1,8(sp)
    80001e6e:	e04a                	sd	s2,0(sp)
    80001e70:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e72:	00230497          	auipc	s1,0x230
    80001e76:	f0e48493          	addi	s1,s1,-242 # 80231d80 <proc>
    80001e7a:	00236917          	auipc	s2,0x236
    80001e7e:	90690913          	addi	s2,s2,-1786 # 80237780 <tickslock>
    acquire(&p->lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	ec6080e7          	jalr	-314(ra) # 80000d4a <acquire>
    if(p->state == UNUSED) {
    80001e8c:	4c9c                	lw	a5,24(s1)
    80001e8e:	cf81                	beqz	a5,80001ea6 <allocproc+0x40>
      release(&p->lock);
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	f6c080e7          	jalr	-148(ra) # 80000dfe <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e9a:	16848493          	addi	s1,s1,360
    80001e9e:	ff2492e3          	bne	s1,s2,80001e82 <allocproc+0x1c>
  return 0;
    80001ea2:	4481                	li	s1,0
    80001ea4:	a0b9                	j	80001ef2 <allocproc+0x8c>
  p->pid = allocpid();
    80001ea6:	00000097          	auipc	ra,0x0
    80001eaa:	e34080e7          	jalr	-460(ra) # 80001cda <allocpid>
    80001eae:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	cea080e7          	jalr	-790(ra) # 80000b9a <kalloc>
    80001eb8:	892a                	mv	s2,a0
    80001eba:	eca8                	sd	a0,88(s1)
    80001ebc:	c131                	beqz	a0,80001f00 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	00000097          	auipc	ra,0x0
    80001ec4:	e60080e7          	jalr	-416(ra) # 80001d20 <proc_pagetable>
    80001ec8:	892a                	mv	s2,a0
    80001eca:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ecc:	c129                	beqz	a0,80001f0e <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001ece:	07000613          	li	a2,112
    80001ed2:	4581                	li	a1,0
    80001ed4:	06048513          	addi	a0,s1,96
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	f6e080e7          	jalr	-146(ra) # 80000e46 <memset>
  p->context.ra = (uint64)forkret;
    80001ee0:	00000797          	auipc	a5,0x0
    80001ee4:	db478793          	addi	a5,a5,-588 # 80001c94 <forkret>
    80001ee8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001eea:	60bc                	ld	a5,64(s1)
    80001eec:	6705                	lui	a4,0x1
    80001eee:	97ba                	add	a5,a5,a4
    80001ef0:	f4bc                	sd	a5,104(s1)
}
    80001ef2:	8526                	mv	a0,s1
    80001ef4:	60e2                	ld	ra,24(sp)
    80001ef6:	6442                	ld	s0,16(sp)
    80001ef8:	64a2                	ld	s1,8(sp)
    80001efa:	6902                	ld	s2,0(sp)
    80001efc:	6105                	addi	sp,sp,32
    80001efe:	8082                	ret
    release(&p->lock);
    80001f00:	8526                	mv	a0,s1
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	efc080e7          	jalr	-260(ra) # 80000dfe <release>
    return 0;
    80001f0a:	84ca                	mv	s1,s2
    80001f0c:	b7dd                	j	80001ef2 <allocproc+0x8c>
    freeproc(p);
    80001f0e:	8526                	mv	a0,s1
    80001f10:	00000097          	auipc	ra,0x0
    80001f14:	efe080e7          	jalr	-258(ra) # 80001e0e <freeproc>
    release(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	ee4080e7          	jalr	-284(ra) # 80000dfe <release>
    return 0;
    80001f22:	84ca                	mv	s1,s2
    80001f24:	b7f9                	j	80001ef2 <allocproc+0x8c>

0000000080001f26 <userinit>:
{
    80001f26:	1101                	addi	sp,sp,-32
    80001f28:	ec06                	sd	ra,24(sp)
    80001f2a:	e822                	sd	s0,16(sp)
    80001f2c:	e426                	sd	s1,8(sp)
    80001f2e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	f36080e7          	jalr	-202(ra) # 80001e66 <allocproc>
    80001f38:	84aa                	mv	s1,a0
  initproc = p;
    80001f3a:	00007797          	auipc	a5,0x7
    80001f3e:	0ca7bf23          	sd	a0,222(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f42:	03400613          	li	a2,52
    80001f46:	00007597          	auipc	a1,0x7
    80001f4a:	8ea58593          	addi	a1,a1,-1814 # 80008830 <initcode>
    80001f4e:	6928                	ld	a0,80(a0)
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	5ae080e7          	jalr	1454(ra) # 800014fe <uvminit>
  p->sz = PGSIZE;
    80001f58:	6785                	lui	a5,0x1
    80001f5a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f5c:	6cb8                	ld	a4,88(s1)
    80001f5e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f62:	6cb8                	ld	a4,88(s1)
    80001f64:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f66:	4641                	li	a2,16
    80001f68:	00006597          	auipc	a1,0x6
    80001f6c:	28858593          	addi	a1,a1,648 # 800081f0 <digits+0x1b0>
    80001f70:	15848513          	addi	a0,s1,344
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	024080e7          	jalr	36(ra) # 80000f98 <safestrcpy>
  p->cwd = namei("/");
    80001f7c:	00006517          	auipc	a0,0x6
    80001f80:	28450513          	addi	a0,a0,644 # 80008200 <digits+0x1c0>
    80001f84:	00002097          	auipc	ra,0x2
    80001f88:	100080e7          	jalr	256(ra) # 80004084 <namei>
    80001f8c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f90:	4789                	li	a5,2
    80001f92:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	e68080e7          	jalr	-408(ra) # 80000dfe <release>
}
    80001f9e:	60e2                	ld	ra,24(sp)
    80001fa0:	6442                	ld	s0,16(sp)
    80001fa2:	64a2                	ld	s1,8(sp)
    80001fa4:	6105                	addi	sp,sp,32
    80001fa6:	8082                	ret

0000000080001fa8 <growproc>:
{
    80001fa8:	1101                	addi	sp,sp,-32
    80001faa:	ec06                	sd	ra,24(sp)
    80001fac:	e822                	sd	s0,16(sp)
    80001fae:	e426                	sd	s1,8(sp)
    80001fb0:	e04a                	sd	s2,0(sp)
    80001fb2:	1000                	addi	s0,sp,32
    80001fb4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	ca6080e7          	jalr	-858(ra) # 80001c5c <myproc>
    80001fbe:	892a                	mv	s2,a0
  sz = p->sz;
    80001fc0:	652c                	ld	a1,72(a0)
    80001fc2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001fc6:	00904f63          	bgtz	s1,80001fe4 <growproc+0x3c>
  } else if(n < 0){
    80001fca:	0204cc63          	bltz	s1,80002002 <growproc+0x5a>
  p->sz = sz;
    80001fce:	1602                	slli	a2,a2,0x20
    80001fd0:	9201                	srli	a2,a2,0x20
    80001fd2:	04c93423          	sd	a2,72(s2)
  return 0;
    80001fd6:	4501                	li	a0,0
}
    80001fd8:	60e2                	ld	ra,24(sp)
    80001fda:	6442                	ld	s0,16(sp)
    80001fdc:	64a2                	ld	s1,8(sp)
    80001fde:	6902                	ld	s2,0(sp)
    80001fe0:	6105                	addi	sp,sp,32
    80001fe2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fe4:	9e25                	addw	a2,a2,s1
    80001fe6:	1602                	slli	a2,a2,0x20
    80001fe8:	9201                	srli	a2,a2,0x20
    80001fea:	1582                	slli	a1,a1,0x20
    80001fec:	9181                	srli	a1,a1,0x20
    80001fee:	6928                	ld	a0,80(a0)
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	5c8080e7          	jalr	1480(ra) # 800015b8 <uvmalloc>
    80001ff8:	0005061b          	sext.w	a2,a0
    80001ffc:	fa69                	bnez	a2,80001fce <growproc+0x26>
      return -1;
    80001ffe:	557d                	li	a0,-1
    80002000:	bfe1                	j	80001fd8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002002:	9e25                	addw	a2,a2,s1
    80002004:	1602                	slli	a2,a2,0x20
    80002006:	9201                	srli	a2,a2,0x20
    80002008:	1582                	slli	a1,a1,0x20
    8000200a:	9181                	srli	a1,a1,0x20
    8000200c:	6928                	ld	a0,80(a0)
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	562080e7          	jalr	1378(ra) # 80001570 <uvmdealloc>
    80002016:	0005061b          	sext.w	a2,a0
    8000201a:	bf55                	j	80001fce <growproc+0x26>

000000008000201c <fork>:
{
    8000201c:	7139                	addi	sp,sp,-64
    8000201e:	fc06                	sd	ra,56(sp)
    80002020:	f822                	sd	s0,48(sp)
    80002022:	f426                	sd	s1,40(sp)
    80002024:	f04a                	sd	s2,32(sp)
    80002026:	ec4e                	sd	s3,24(sp)
    80002028:	e852                	sd	s4,16(sp)
    8000202a:	e456                	sd	s5,8(sp)
    8000202c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	c2e080e7          	jalr	-978(ra) # 80001c5c <myproc>
    80002036:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	e2e080e7          	jalr	-466(ra) # 80001e66 <allocproc>
    80002040:	c17d                	beqz	a0,80002126 <fork+0x10a>
    80002042:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002044:	048ab603          	ld	a2,72(s5)
    80002048:	692c                	ld	a1,80(a0)
    8000204a:	050ab503          	ld	a0,80(s5)
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	6b6080e7          	jalr	1718(ra) # 80001704 <uvmcopy>
    80002056:	04054a63          	bltz	a0,800020aa <fork+0x8e>
  np->sz = p->sz;
    8000205a:	048ab783          	ld	a5,72(s5)
    8000205e:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80002062:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80002066:	058ab683          	ld	a3,88(s5)
    8000206a:	87b6                	mv	a5,a3
    8000206c:	058a3703          	ld	a4,88(s4)
    80002070:	12068693          	addi	a3,a3,288
    80002074:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002078:	6788                	ld	a0,8(a5)
    8000207a:	6b8c                	ld	a1,16(a5)
    8000207c:	6f90                	ld	a2,24(a5)
    8000207e:	01073023          	sd	a6,0(a4)
    80002082:	e708                	sd	a0,8(a4)
    80002084:	eb0c                	sd	a1,16(a4)
    80002086:	ef10                	sd	a2,24(a4)
    80002088:	02078793          	addi	a5,a5,32
    8000208c:	02070713          	addi	a4,a4,32
    80002090:	fed792e3          	bne	a5,a3,80002074 <fork+0x58>
  np->trapframe->a0 = 0;
    80002094:	058a3783          	ld	a5,88(s4)
    80002098:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000209c:	0d0a8493          	addi	s1,s5,208
    800020a0:	0d0a0913          	addi	s2,s4,208
    800020a4:	150a8993          	addi	s3,s5,336
    800020a8:	a00d                	j	800020ca <fork+0xae>
    freeproc(np);
    800020aa:	8552                	mv	a0,s4
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	d62080e7          	jalr	-670(ra) # 80001e0e <freeproc>
    release(&np->lock);
    800020b4:	8552                	mv	a0,s4
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	d48080e7          	jalr	-696(ra) # 80000dfe <release>
    return -1;
    800020be:	54fd                	li	s1,-1
    800020c0:	a889                	j	80002112 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    800020c2:	04a1                	addi	s1,s1,8
    800020c4:	0921                	addi	s2,s2,8
    800020c6:	01348b63          	beq	s1,s3,800020dc <fork+0xc0>
    if(p->ofile[i])
    800020ca:	6088                	ld	a0,0(s1)
    800020cc:	d97d                	beqz	a0,800020c2 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    800020ce:	00002097          	auipc	ra,0x2
    800020d2:	642080e7          	jalr	1602(ra) # 80004710 <filedup>
    800020d6:	00a93023          	sd	a0,0(s2)
    800020da:	b7e5                	j	800020c2 <fork+0xa6>
  np->cwd = idup(p->cwd);
    800020dc:	150ab503          	ld	a0,336(s5)
    800020e0:	00001097          	auipc	ra,0x1
    800020e4:	7b2080e7          	jalr	1970(ra) # 80003892 <idup>
    800020e8:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020ec:	4641                	li	a2,16
    800020ee:	158a8593          	addi	a1,s5,344
    800020f2:	158a0513          	addi	a0,s4,344
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	ea2080e7          	jalr	-350(ra) # 80000f98 <safestrcpy>
  pid = np->pid;
    800020fe:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80002102:	4789                	li	a5,2
    80002104:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002108:	8552                	mv	a0,s4
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	cf4080e7          	jalr	-780(ra) # 80000dfe <release>
}
    80002112:	8526                	mv	a0,s1
    80002114:	70e2                	ld	ra,56(sp)
    80002116:	7442                	ld	s0,48(sp)
    80002118:	74a2                	ld	s1,40(sp)
    8000211a:	7902                	ld	s2,32(sp)
    8000211c:	69e2                	ld	s3,24(sp)
    8000211e:	6a42                	ld	s4,16(sp)
    80002120:	6aa2                	ld	s5,8(sp)
    80002122:	6121                	addi	sp,sp,64
    80002124:	8082                	ret
    return -1;
    80002126:	54fd                	li	s1,-1
    80002128:	b7ed                	j	80002112 <fork+0xf6>

000000008000212a <reparent>:
{
    8000212a:	7179                	addi	sp,sp,-48
    8000212c:	f406                	sd	ra,40(sp)
    8000212e:	f022                	sd	s0,32(sp)
    80002130:	ec26                	sd	s1,24(sp)
    80002132:	e84a                	sd	s2,16(sp)
    80002134:	e44e                	sd	s3,8(sp)
    80002136:	e052                	sd	s4,0(sp)
    80002138:	1800                	addi	s0,sp,48
    8000213a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000213c:	00230497          	auipc	s1,0x230
    80002140:	c4448493          	addi	s1,s1,-956 # 80231d80 <proc>
      pp->parent = initproc;
    80002144:	00007a17          	auipc	s4,0x7
    80002148:	ed4a0a13          	addi	s4,s4,-300 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000214c:	00235997          	auipc	s3,0x235
    80002150:	63498993          	addi	s3,s3,1588 # 80237780 <tickslock>
    80002154:	a029                	j	8000215e <reparent+0x34>
    80002156:	16848493          	addi	s1,s1,360
    8000215a:	03348363          	beq	s1,s3,80002180 <reparent+0x56>
    if(pp->parent == p){
    8000215e:	709c                	ld	a5,32(s1)
    80002160:	ff279be3          	bne	a5,s2,80002156 <reparent+0x2c>
      acquire(&pp->lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	be4080e7          	jalr	-1052(ra) # 80000d4a <acquire>
      pp->parent = initproc;
    8000216e:	000a3783          	ld	a5,0(s4)
    80002172:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	c88080e7          	jalr	-888(ra) # 80000dfe <release>
    8000217e:	bfe1                	j	80002156 <reparent+0x2c>
}
    80002180:	70a2                	ld	ra,40(sp)
    80002182:	7402                	ld	s0,32(sp)
    80002184:	64e2                	ld	s1,24(sp)
    80002186:	6942                	ld	s2,16(sp)
    80002188:	69a2                	ld	s3,8(sp)
    8000218a:	6a02                	ld	s4,0(sp)
    8000218c:	6145                	addi	sp,sp,48
    8000218e:	8082                	ret

0000000080002190 <scheduler>:
{
    80002190:	711d                	addi	sp,sp,-96
    80002192:	ec86                	sd	ra,88(sp)
    80002194:	e8a2                	sd	s0,80(sp)
    80002196:	e4a6                	sd	s1,72(sp)
    80002198:	e0ca                	sd	s2,64(sp)
    8000219a:	fc4e                	sd	s3,56(sp)
    8000219c:	f852                	sd	s4,48(sp)
    8000219e:	f456                	sd	s5,40(sp)
    800021a0:	f05a                	sd	s6,32(sp)
    800021a2:	ec5e                	sd	s7,24(sp)
    800021a4:	e862                	sd	s8,16(sp)
    800021a6:	e466                	sd	s9,8(sp)
    800021a8:	1080                	addi	s0,sp,96
    800021aa:	8792                	mv	a5,tp
  int id = r_tp();
    800021ac:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021ae:	00779c13          	slli	s8,a5,0x7
    800021b2:	0022f717          	auipc	a4,0x22f
    800021b6:	7b670713          	addi	a4,a4,1974 # 80231968 <pid_lock>
    800021ba:	9762                	add	a4,a4,s8
    800021bc:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800021c0:	0022f717          	auipc	a4,0x22f
    800021c4:	7c870713          	addi	a4,a4,1992 # 80231988 <cpus+0x8>
    800021c8:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    800021ca:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    800021cc:	4a89                	li	s5,2
        c->proc = p;
    800021ce:	079e                	slli	a5,a5,0x7
    800021d0:	0022fb17          	auipc	s6,0x22f
    800021d4:	798b0b13          	addi	s6,s6,1944 # 80231968 <pid_lock>
    800021d8:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800021da:	00235a17          	auipc	s4,0x235
    800021de:	5a6a0a13          	addi	s4,s4,1446 # 80237780 <tickslock>
    800021e2:	a8a1                	j	8000223a <scheduler+0xaa>
      release(&p->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	c18080e7          	jalr	-1000(ra) # 80000dfe <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021ee:	16848493          	addi	s1,s1,360
    800021f2:	03448a63          	beq	s1,s4,80002226 <scheduler+0x96>
      acquire(&p->lock);
    800021f6:	8526                	mv	a0,s1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	b52080e7          	jalr	-1198(ra) # 80000d4a <acquire>
      if(p->state != UNUSED) {
    80002200:	4c9c                	lw	a5,24(s1)
    80002202:	d3ed                	beqz	a5,800021e4 <scheduler+0x54>
        nproc++;
    80002204:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002206:	fd579fe3          	bne	a5,s5,800021e4 <scheduler+0x54>
        p->state = RUNNING;
    8000220a:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    8000220e:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002212:	06048593          	addi	a1,s1,96
    80002216:	8562                	mv	a0,s8
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	60c080e7          	jalr	1548(ra) # 80002824 <swtch>
        c->proc = 0;
    80002220:	000b3c23          	sd	zero,24(s6)
    80002224:	b7c1                	j	800021e4 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002226:	013aca63          	blt	s5,s3,8000223a <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000222a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000222e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002232:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002236:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000223a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000223e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002242:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002246:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002248:	00230497          	auipc	s1,0x230
    8000224c:	b3848493          	addi	s1,s1,-1224 # 80231d80 <proc>
        p->state = RUNNING;
    80002250:	4b8d                	li	s7,3
    80002252:	b755                	j	800021f6 <scheduler+0x66>

0000000080002254 <sched>:
{
    80002254:	7179                	addi	sp,sp,-48
    80002256:	f406                	sd	ra,40(sp)
    80002258:	f022                	sd	s0,32(sp)
    8000225a:	ec26                	sd	s1,24(sp)
    8000225c:	e84a                	sd	s2,16(sp)
    8000225e:	e44e                	sd	s3,8(sp)
    80002260:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002262:	00000097          	auipc	ra,0x0
    80002266:	9fa080e7          	jalr	-1542(ra) # 80001c5c <myproc>
    8000226a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a64080e7          	jalr	-1436(ra) # 80000cd0 <holding>
    80002274:	c93d                	beqz	a0,800022ea <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002276:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002278:	2781                	sext.w	a5,a5
    8000227a:	079e                	slli	a5,a5,0x7
    8000227c:	0022f717          	auipc	a4,0x22f
    80002280:	6ec70713          	addi	a4,a4,1772 # 80231968 <pid_lock>
    80002284:	97ba                	add	a5,a5,a4
    80002286:	0907a703          	lw	a4,144(a5)
    8000228a:	4785                	li	a5,1
    8000228c:	06f71763          	bne	a4,a5,800022fa <sched+0xa6>
  if(p->state == RUNNING)
    80002290:	4c98                	lw	a4,24(s1)
    80002292:	478d                	li	a5,3
    80002294:	06f70b63          	beq	a4,a5,8000230a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002298:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000229c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000229e:	efb5                	bnez	a5,8000231a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022a0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022a2:	0022f917          	auipc	s2,0x22f
    800022a6:	6c690913          	addi	s2,s2,1734 # 80231968 <pid_lock>
    800022aa:	2781                	sext.w	a5,a5
    800022ac:	079e                	slli	a5,a5,0x7
    800022ae:	97ca                	add	a5,a5,s2
    800022b0:	0947a983          	lw	s3,148(a5)
    800022b4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022b6:	2781                	sext.w	a5,a5
    800022b8:	079e                	slli	a5,a5,0x7
    800022ba:	0022f597          	auipc	a1,0x22f
    800022be:	6ce58593          	addi	a1,a1,1742 # 80231988 <cpus+0x8>
    800022c2:	95be                	add	a1,a1,a5
    800022c4:	06048513          	addi	a0,s1,96
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	55c080e7          	jalr	1372(ra) # 80002824 <swtch>
    800022d0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022d2:	2781                	sext.w	a5,a5
    800022d4:	079e                	slli	a5,a5,0x7
    800022d6:	97ca                	add	a5,a5,s2
    800022d8:	0937aa23          	sw	s3,148(a5)
}
    800022dc:	70a2                	ld	ra,40(sp)
    800022de:	7402                	ld	s0,32(sp)
    800022e0:	64e2                	ld	s1,24(sp)
    800022e2:	6942                	ld	s2,16(sp)
    800022e4:	69a2                	ld	s3,8(sp)
    800022e6:	6145                	addi	sp,sp,48
    800022e8:	8082                	ret
    panic("sched p->lock");
    800022ea:	00006517          	auipc	a0,0x6
    800022ee:	f1e50513          	addi	a0,a0,-226 # 80008208 <digits+0x1c8>
    800022f2:	ffffe097          	auipc	ra,0xffffe
    800022f6:	250080e7          	jalr	592(ra) # 80000542 <panic>
    panic("sched locks");
    800022fa:	00006517          	auipc	a0,0x6
    800022fe:	f1e50513          	addi	a0,a0,-226 # 80008218 <digits+0x1d8>
    80002302:	ffffe097          	auipc	ra,0xffffe
    80002306:	240080e7          	jalr	576(ra) # 80000542 <panic>
    panic("sched running");
    8000230a:	00006517          	auipc	a0,0x6
    8000230e:	f1e50513          	addi	a0,a0,-226 # 80008228 <digits+0x1e8>
    80002312:	ffffe097          	auipc	ra,0xffffe
    80002316:	230080e7          	jalr	560(ra) # 80000542 <panic>
    panic("sched interruptible");
    8000231a:	00006517          	auipc	a0,0x6
    8000231e:	f1e50513          	addi	a0,a0,-226 # 80008238 <digits+0x1f8>
    80002322:	ffffe097          	auipc	ra,0xffffe
    80002326:	220080e7          	jalr	544(ra) # 80000542 <panic>

000000008000232a <exit>:
{
    8000232a:	7179                	addi	sp,sp,-48
    8000232c:	f406                	sd	ra,40(sp)
    8000232e:	f022                	sd	s0,32(sp)
    80002330:	ec26                	sd	s1,24(sp)
    80002332:	e84a                	sd	s2,16(sp)
    80002334:	e44e                	sd	s3,8(sp)
    80002336:	e052                	sd	s4,0(sp)
    80002338:	1800                	addi	s0,sp,48
    8000233a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	920080e7          	jalr	-1760(ra) # 80001c5c <myproc>
    80002344:	89aa                	mv	s3,a0
  if(p == initproc)
    80002346:	00007797          	auipc	a5,0x7
    8000234a:	cd27b783          	ld	a5,-814(a5) # 80009018 <initproc>
    8000234e:	0d050493          	addi	s1,a0,208
    80002352:	15050913          	addi	s2,a0,336
    80002356:	02a79363          	bne	a5,a0,8000237c <exit+0x52>
    panic("init exiting");
    8000235a:	00006517          	auipc	a0,0x6
    8000235e:	ef650513          	addi	a0,a0,-266 # 80008250 <digits+0x210>
    80002362:	ffffe097          	auipc	ra,0xffffe
    80002366:	1e0080e7          	jalr	480(ra) # 80000542 <panic>
      fileclose(f);
    8000236a:	00002097          	auipc	ra,0x2
    8000236e:	3f8080e7          	jalr	1016(ra) # 80004762 <fileclose>
      p->ofile[fd] = 0;
    80002372:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002376:	04a1                	addi	s1,s1,8
    80002378:	01248563          	beq	s1,s2,80002382 <exit+0x58>
    if(p->ofile[fd]){
    8000237c:	6088                	ld	a0,0(s1)
    8000237e:	f575                	bnez	a0,8000236a <exit+0x40>
    80002380:	bfdd                	j	80002376 <exit+0x4c>
  begin_op();
    80002382:	00002097          	auipc	ra,0x2
    80002386:	f0e080e7          	jalr	-242(ra) # 80004290 <begin_op>
  iput(p->cwd);
    8000238a:	1509b503          	ld	a0,336(s3)
    8000238e:	00001097          	auipc	ra,0x1
    80002392:	6fc080e7          	jalr	1788(ra) # 80003a8a <iput>
  end_op();
    80002396:	00002097          	auipc	ra,0x2
    8000239a:	f7a080e7          	jalr	-134(ra) # 80004310 <end_op>
  p->cwd = 0;
    8000239e:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800023a2:	00007497          	auipc	s1,0x7
    800023a6:	c7648493          	addi	s1,s1,-906 # 80009018 <initproc>
    800023aa:	6088                	ld	a0,0(s1)
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	99e080e7          	jalr	-1634(ra) # 80000d4a <acquire>
  wakeup1(initproc);
    800023b4:	6088                	ld	a0,0(s1)
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	766080e7          	jalr	1894(ra) # 80001b1c <wakeup1>
  release(&initproc->lock);
    800023be:	6088                	ld	a0,0(s1)
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	a3e080e7          	jalr	-1474(ra) # 80000dfe <release>
  acquire(&p->lock);
    800023c8:	854e                	mv	a0,s3
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	980080e7          	jalr	-1664(ra) # 80000d4a <acquire>
  struct proc *original_parent = p->parent;
    800023d2:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800023d6:	854e                	mv	a0,s3
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	a26080e7          	jalr	-1498(ra) # 80000dfe <release>
  acquire(&original_parent->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	968080e7          	jalr	-1688(ra) # 80000d4a <acquire>
  acquire(&p->lock);
    800023ea:	854e                	mv	a0,s3
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	95e080e7          	jalr	-1698(ra) # 80000d4a <acquire>
  reparent(p);
    800023f4:	854e                	mv	a0,s3
    800023f6:	00000097          	auipc	ra,0x0
    800023fa:	d34080e7          	jalr	-716(ra) # 8000212a <reparent>
  wakeup1(original_parent);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	71c080e7          	jalr	1820(ra) # 80001b1c <wakeup1>
  p->xstate = status;
    80002408:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000240c:	4791                	li	a5,4
    8000240e:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	9ea080e7          	jalr	-1558(ra) # 80000dfe <release>
  sched();
    8000241c:	00000097          	auipc	ra,0x0
    80002420:	e38080e7          	jalr	-456(ra) # 80002254 <sched>
  panic("zombie exit");
    80002424:	00006517          	auipc	a0,0x6
    80002428:	e3c50513          	addi	a0,a0,-452 # 80008260 <digits+0x220>
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	116080e7          	jalr	278(ra) # 80000542 <panic>

0000000080002434 <yield>:
{
    80002434:	1101                	addi	sp,sp,-32
    80002436:	ec06                	sd	ra,24(sp)
    80002438:	e822                	sd	s0,16(sp)
    8000243a:	e426                	sd	s1,8(sp)
    8000243c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000243e:	00000097          	auipc	ra,0x0
    80002442:	81e080e7          	jalr	-2018(ra) # 80001c5c <myproc>
    80002446:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	902080e7          	jalr	-1790(ra) # 80000d4a <acquire>
  p->state = RUNNABLE;
    80002450:	4789                	li	a5,2
    80002452:	cc9c                	sw	a5,24(s1)
  sched();
    80002454:	00000097          	auipc	ra,0x0
    80002458:	e00080e7          	jalr	-512(ra) # 80002254 <sched>
  release(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	9a0080e7          	jalr	-1632(ra) # 80000dfe <release>
}
    80002466:	60e2                	ld	ra,24(sp)
    80002468:	6442                	ld	s0,16(sp)
    8000246a:	64a2                	ld	s1,8(sp)
    8000246c:	6105                	addi	sp,sp,32
    8000246e:	8082                	ret

0000000080002470 <sleep>:
{
    80002470:	7179                	addi	sp,sp,-48
    80002472:	f406                	sd	ra,40(sp)
    80002474:	f022                	sd	s0,32(sp)
    80002476:	ec26                	sd	s1,24(sp)
    80002478:	e84a                	sd	s2,16(sp)
    8000247a:	e44e                	sd	s3,8(sp)
    8000247c:	1800                	addi	s0,sp,48
    8000247e:	89aa                	mv	s3,a0
    80002480:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	7da080e7          	jalr	2010(ra) # 80001c5c <myproc>
    8000248a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000248c:	05250663          	beq	a0,s2,800024d8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	8ba080e7          	jalr	-1862(ra) # 80000d4a <acquire>
    release(lk);
    80002498:	854a                	mv	a0,s2
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	964080e7          	jalr	-1692(ra) # 80000dfe <release>
  p->chan = chan;
    800024a2:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800024a6:	4785                	li	a5,1
    800024a8:	cc9c                	sw	a5,24(s1)
  sched();
    800024aa:	00000097          	auipc	ra,0x0
    800024ae:	daa080e7          	jalr	-598(ra) # 80002254 <sched>
  p->chan = 0;
    800024b2:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	946080e7          	jalr	-1722(ra) # 80000dfe <release>
    acquire(lk);
    800024c0:	854a                	mv	a0,s2
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	888080e7          	jalr	-1912(ra) # 80000d4a <acquire>
}
    800024ca:	70a2                	ld	ra,40(sp)
    800024cc:	7402                	ld	s0,32(sp)
    800024ce:	64e2                	ld	s1,24(sp)
    800024d0:	6942                	ld	s2,16(sp)
    800024d2:	69a2                	ld	s3,8(sp)
    800024d4:	6145                	addi	sp,sp,48
    800024d6:	8082                	ret
  p->chan = chan;
    800024d8:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800024dc:	4785                	li	a5,1
    800024de:	cd1c                	sw	a5,24(a0)
  sched();
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	d74080e7          	jalr	-652(ra) # 80002254 <sched>
  p->chan = 0;
    800024e8:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800024ec:	bff9                	j	800024ca <sleep+0x5a>

00000000800024ee <wait>:
{
    800024ee:	715d                	addi	sp,sp,-80
    800024f0:	e486                	sd	ra,72(sp)
    800024f2:	e0a2                	sd	s0,64(sp)
    800024f4:	fc26                	sd	s1,56(sp)
    800024f6:	f84a                	sd	s2,48(sp)
    800024f8:	f44e                	sd	s3,40(sp)
    800024fa:	f052                	sd	s4,32(sp)
    800024fc:	ec56                	sd	s5,24(sp)
    800024fe:	e85a                	sd	s6,16(sp)
    80002500:	e45e                	sd	s7,8(sp)
    80002502:	0880                	addi	s0,sp,80
    80002504:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	756080e7          	jalr	1878(ra) # 80001c5c <myproc>
    8000250e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	83a080e7          	jalr	-1990(ra) # 80000d4a <acquire>
    havekids = 0;
    80002518:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000251a:	4a11                	li	s4,4
        havekids = 1;
    8000251c:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000251e:	00235997          	auipc	s3,0x235
    80002522:	26298993          	addi	s3,s3,610 # 80237780 <tickslock>
    havekids = 0;
    80002526:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002528:	00230497          	auipc	s1,0x230
    8000252c:	85848493          	addi	s1,s1,-1960 # 80231d80 <proc>
    80002530:	a08d                	j	80002592 <wait+0xa4>
          pid = np->pid;
    80002532:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002536:	000b0e63          	beqz	s6,80002552 <wait+0x64>
    8000253a:	4691                	li	a3,4
    8000253c:	03448613          	addi	a2,s1,52
    80002540:	85da                	mv	a1,s6
    80002542:	05093503          	ld	a0,80(s2)
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	524080e7          	jalr	1316(ra) # 80001a6a <copyout>
    8000254e:	02054263          	bltz	a0,80002572 <wait+0x84>
          freeproc(np);
    80002552:	8526                	mv	a0,s1
    80002554:	00000097          	auipc	ra,0x0
    80002558:	8ba080e7          	jalr	-1862(ra) # 80001e0e <freeproc>
          release(&np->lock);
    8000255c:	8526                	mv	a0,s1
    8000255e:	fffff097          	auipc	ra,0xfffff
    80002562:	8a0080e7          	jalr	-1888(ra) # 80000dfe <release>
          release(&p->lock);
    80002566:	854a                	mv	a0,s2
    80002568:	fffff097          	auipc	ra,0xfffff
    8000256c:	896080e7          	jalr	-1898(ra) # 80000dfe <release>
          return pid;
    80002570:	a8a9                	j	800025ca <wait+0xdc>
            release(&np->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	88a080e7          	jalr	-1910(ra) # 80000dfe <release>
            release(&p->lock);
    8000257c:	854a                	mv	a0,s2
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	880080e7          	jalr	-1920(ra) # 80000dfe <release>
            return -1;
    80002586:	59fd                	li	s3,-1
    80002588:	a089                	j	800025ca <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000258a:	16848493          	addi	s1,s1,360
    8000258e:	03348463          	beq	s1,s3,800025b6 <wait+0xc8>
      if(np->parent == p){
    80002592:	709c                	ld	a5,32(s1)
    80002594:	ff279be3          	bne	a5,s2,8000258a <wait+0x9c>
        acquire(&np->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	7b0080e7          	jalr	1968(ra) # 80000d4a <acquire>
        if(np->state == ZOMBIE){
    800025a2:	4c9c                	lw	a5,24(s1)
    800025a4:	f94787e3          	beq	a5,s4,80002532 <wait+0x44>
        release(&np->lock);
    800025a8:	8526                	mv	a0,s1
    800025aa:	fffff097          	auipc	ra,0xfffff
    800025ae:	854080e7          	jalr	-1964(ra) # 80000dfe <release>
        havekids = 1;
    800025b2:	8756                	mv	a4,s5
    800025b4:	bfd9                	j	8000258a <wait+0x9c>
    if(!havekids || p->killed){
    800025b6:	c701                	beqz	a4,800025be <wait+0xd0>
    800025b8:	03092783          	lw	a5,48(s2)
    800025bc:	c39d                	beqz	a5,800025e2 <wait+0xf4>
      release(&p->lock);
    800025be:	854a                	mv	a0,s2
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	83e080e7          	jalr	-1986(ra) # 80000dfe <release>
      return -1;
    800025c8:	59fd                	li	s3,-1
}
    800025ca:	854e                	mv	a0,s3
    800025cc:	60a6                	ld	ra,72(sp)
    800025ce:	6406                	ld	s0,64(sp)
    800025d0:	74e2                	ld	s1,56(sp)
    800025d2:	7942                	ld	s2,48(sp)
    800025d4:	79a2                	ld	s3,40(sp)
    800025d6:	7a02                	ld	s4,32(sp)
    800025d8:	6ae2                	ld	s5,24(sp)
    800025da:	6b42                	ld	s6,16(sp)
    800025dc:	6ba2                	ld	s7,8(sp)
    800025de:	6161                	addi	sp,sp,80
    800025e0:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800025e2:	85ca                	mv	a1,s2
    800025e4:	854a                	mv	a0,s2
    800025e6:	00000097          	auipc	ra,0x0
    800025ea:	e8a080e7          	jalr	-374(ra) # 80002470 <sleep>
    havekids = 0;
    800025ee:	bf25                	j	80002526 <wait+0x38>

00000000800025f0 <wakeup>:
{
    800025f0:	7139                	addi	sp,sp,-64
    800025f2:	fc06                	sd	ra,56(sp)
    800025f4:	f822                	sd	s0,48(sp)
    800025f6:	f426                	sd	s1,40(sp)
    800025f8:	f04a                	sd	s2,32(sp)
    800025fa:	ec4e                	sd	s3,24(sp)
    800025fc:	e852                	sd	s4,16(sp)
    800025fe:	e456                	sd	s5,8(sp)
    80002600:	0080                	addi	s0,sp,64
    80002602:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002604:	0022f497          	auipc	s1,0x22f
    80002608:	77c48493          	addi	s1,s1,1916 # 80231d80 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000260c:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000260e:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002610:	00235917          	auipc	s2,0x235
    80002614:	17090913          	addi	s2,s2,368 # 80237780 <tickslock>
    80002618:	a811                	j	8000262c <wakeup+0x3c>
    release(&p->lock);
    8000261a:	8526                	mv	a0,s1
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	7e2080e7          	jalr	2018(ra) # 80000dfe <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002624:	16848493          	addi	s1,s1,360
    80002628:	03248063          	beq	s1,s2,80002648 <wakeup+0x58>
    acquire(&p->lock);
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	71c080e7          	jalr	1820(ra) # 80000d4a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002636:	4c9c                	lw	a5,24(s1)
    80002638:	ff3791e3          	bne	a5,s3,8000261a <wakeup+0x2a>
    8000263c:	749c                	ld	a5,40(s1)
    8000263e:	fd479ee3          	bne	a5,s4,8000261a <wakeup+0x2a>
      p->state = RUNNABLE;
    80002642:	0154ac23          	sw	s5,24(s1)
    80002646:	bfd1                	j	8000261a <wakeup+0x2a>
}
    80002648:	70e2                	ld	ra,56(sp)
    8000264a:	7442                	ld	s0,48(sp)
    8000264c:	74a2                	ld	s1,40(sp)
    8000264e:	7902                	ld	s2,32(sp)
    80002650:	69e2                	ld	s3,24(sp)
    80002652:	6a42                	ld	s4,16(sp)
    80002654:	6aa2                	ld	s5,8(sp)
    80002656:	6121                	addi	sp,sp,64
    80002658:	8082                	ret

000000008000265a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000265a:	7179                	addi	sp,sp,-48
    8000265c:	f406                	sd	ra,40(sp)
    8000265e:	f022                	sd	s0,32(sp)
    80002660:	ec26                	sd	s1,24(sp)
    80002662:	e84a                	sd	s2,16(sp)
    80002664:	e44e                	sd	s3,8(sp)
    80002666:	1800                	addi	s0,sp,48
    80002668:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000266a:	0022f497          	auipc	s1,0x22f
    8000266e:	71648493          	addi	s1,s1,1814 # 80231d80 <proc>
    80002672:	00235997          	auipc	s3,0x235
    80002676:	10e98993          	addi	s3,s3,270 # 80237780 <tickslock>
    acquire(&p->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	6ce080e7          	jalr	1742(ra) # 80000d4a <acquire>
    if(p->pid == pid){
    80002684:	5c9c                	lw	a5,56(s1)
    80002686:	01278d63          	beq	a5,s2,800026a0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	772080e7          	jalr	1906(ra) # 80000dfe <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002694:	16848493          	addi	s1,s1,360
    80002698:	ff3491e3          	bne	s1,s3,8000267a <kill+0x20>
  }
  return -1;
    8000269c:	557d                	li	a0,-1
    8000269e:	a821                	j	800026b6 <kill+0x5c>
      p->killed = 1;
    800026a0:	4785                	li	a5,1
    800026a2:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800026a4:	4c98                	lw	a4,24(s1)
    800026a6:	00f70f63          	beq	a4,a5,800026c4 <kill+0x6a>
      release(&p->lock);
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	752080e7          	jalr	1874(ra) # 80000dfe <release>
      return 0;
    800026b4:	4501                	li	a0,0
}
    800026b6:	70a2                	ld	ra,40(sp)
    800026b8:	7402                	ld	s0,32(sp)
    800026ba:	64e2                	ld	s1,24(sp)
    800026bc:	6942                	ld	s2,16(sp)
    800026be:	69a2                	ld	s3,8(sp)
    800026c0:	6145                	addi	sp,sp,48
    800026c2:	8082                	ret
        p->state = RUNNABLE;
    800026c4:	4789                	li	a5,2
    800026c6:	cc9c                	sw	a5,24(s1)
    800026c8:	b7cd                	j	800026aa <kill+0x50>

00000000800026ca <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026ca:	7179                	addi	sp,sp,-48
    800026cc:	f406                	sd	ra,40(sp)
    800026ce:	f022                	sd	s0,32(sp)
    800026d0:	ec26                	sd	s1,24(sp)
    800026d2:	e84a                	sd	s2,16(sp)
    800026d4:	e44e                	sd	s3,8(sp)
    800026d6:	e052                	sd	s4,0(sp)
    800026d8:	1800                	addi	s0,sp,48
    800026da:	84aa                	mv	s1,a0
    800026dc:	892e                	mv	s2,a1
    800026de:	89b2                	mv	s3,a2
    800026e0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026e2:	fffff097          	auipc	ra,0xfffff
    800026e6:	57a080e7          	jalr	1402(ra) # 80001c5c <myproc>
  if(user_dst){
    800026ea:	c08d                	beqz	s1,8000270c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026ec:	86d2                	mv	a3,s4
    800026ee:	864e                	mv	a2,s3
    800026f0:	85ca                	mv	a1,s2
    800026f2:	6928                	ld	a0,80(a0)
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	376080e7          	jalr	886(ra) # 80001a6a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026fc:	70a2                	ld	ra,40(sp)
    800026fe:	7402                	ld	s0,32(sp)
    80002700:	64e2                	ld	s1,24(sp)
    80002702:	6942                	ld	s2,16(sp)
    80002704:	69a2                	ld	s3,8(sp)
    80002706:	6a02                	ld	s4,0(sp)
    80002708:	6145                	addi	sp,sp,48
    8000270a:	8082                	ret
    memmove((char *)dst, src, len);
    8000270c:	000a061b          	sext.w	a2,s4
    80002710:	85ce                	mv	a1,s3
    80002712:	854a                	mv	a0,s2
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	78e080e7          	jalr	1934(ra) # 80000ea2 <memmove>
    return 0;
    8000271c:	8526                	mv	a0,s1
    8000271e:	bff9                	j	800026fc <either_copyout+0x32>

0000000080002720 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002720:	7179                	addi	sp,sp,-48
    80002722:	f406                	sd	ra,40(sp)
    80002724:	f022                	sd	s0,32(sp)
    80002726:	ec26                	sd	s1,24(sp)
    80002728:	e84a                	sd	s2,16(sp)
    8000272a:	e44e                	sd	s3,8(sp)
    8000272c:	e052                	sd	s4,0(sp)
    8000272e:	1800                	addi	s0,sp,48
    80002730:	892a                	mv	s2,a0
    80002732:	84ae                	mv	s1,a1
    80002734:	89b2                	mv	s3,a2
    80002736:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	524080e7          	jalr	1316(ra) # 80001c5c <myproc>
  if(user_src){
    80002740:	c08d                	beqz	s1,80002762 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002742:	86d2                	mv	a3,s4
    80002744:	864e                	mv	a2,s3
    80002746:	85ca                	mv	a1,s2
    80002748:	6928                	ld	a0,80(a0)
    8000274a:	fffff097          	auipc	ra,0xfffff
    8000274e:	0c8080e7          	jalr	200(ra) # 80001812 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002752:	70a2                	ld	ra,40(sp)
    80002754:	7402                	ld	s0,32(sp)
    80002756:	64e2                	ld	s1,24(sp)
    80002758:	6942                	ld	s2,16(sp)
    8000275a:	69a2                	ld	s3,8(sp)
    8000275c:	6a02                	ld	s4,0(sp)
    8000275e:	6145                	addi	sp,sp,48
    80002760:	8082                	ret
    memmove(dst, (char*)src, len);
    80002762:	000a061b          	sext.w	a2,s4
    80002766:	85ce                	mv	a1,s3
    80002768:	854a                	mv	a0,s2
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	738080e7          	jalr	1848(ra) # 80000ea2 <memmove>
    return 0;
    80002772:	8526                	mv	a0,s1
    80002774:	bff9                	j	80002752 <either_copyin+0x32>

0000000080002776 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002776:	715d                	addi	sp,sp,-80
    80002778:	e486                	sd	ra,72(sp)
    8000277a:	e0a2                	sd	s0,64(sp)
    8000277c:	fc26                	sd	s1,56(sp)
    8000277e:	f84a                	sd	s2,48(sp)
    80002780:	f44e                	sd	s3,40(sp)
    80002782:	f052                	sd	s4,32(sp)
    80002784:	ec56                	sd	s5,24(sp)
    80002786:	e85a                	sd	s6,16(sp)
    80002788:	e45e                	sd	s7,8(sp)
    8000278a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000278c:	00006517          	auipc	a0,0x6
    80002790:	94450513          	addi	a0,a0,-1724 # 800080d0 <digits+0x90>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	df8080e7          	jalr	-520(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000279c:	0022f497          	auipc	s1,0x22f
    800027a0:	73c48493          	addi	s1,s1,1852 # 80231ed8 <proc+0x158>
    800027a4:	00235917          	auipc	s2,0x235
    800027a8:	13490913          	addi	s2,s2,308 # 802378d8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ac:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800027ae:	00006997          	auipc	s3,0x6
    800027b2:	ac298993          	addi	s3,s3,-1342 # 80008270 <digits+0x230>
    printf("%d %s %s", p->pid, state, p->name);
    800027b6:	00006a97          	auipc	s5,0x6
    800027ba:	ac2a8a93          	addi	s5,s5,-1342 # 80008278 <digits+0x238>
    printf("\n");
    800027be:	00006a17          	auipc	s4,0x6
    800027c2:	912a0a13          	addi	s4,s4,-1774 # 800080d0 <digits+0x90>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c6:	00006b97          	auipc	s7,0x6
    800027ca:	aeab8b93          	addi	s7,s7,-1302 # 800082b0 <states.0>
    800027ce:	a00d                	j	800027f0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027d0:	ee06a583          	lw	a1,-288(a3)
    800027d4:	8556                	mv	a0,s5
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	db6080e7          	jalr	-586(ra) # 8000058c <printf>
    printf("\n");
    800027de:	8552                	mv	a0,s4
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	dac080e7          	jalr	-596(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027e8:	16848493          	addi	s1,s1,360
    800027ec:	03248163          	beq	s1,s2,8000280e <procdump+0x98>
    if(p->state == UNUSED)
    800027f0:	86a6                	mv	a3,s1
    800027f2:	ec04a783          	lw	a5,-320(s1)
    800027f6:	dbed                	beqz	a5,800027e8 <procdump+0x72>
      state = "???";
    800027f8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027fa:	fcfb6be3          	bltu	s6,a5,800027d0 <procdump+0x5a>
    800027fe:	1782                	slli	a5,a5,0x20
    80002800:	9381                	srli	a5,a5,0x20
    80002802:	078e                	slli	a5,a5,0x3
    80002804:	97de                	add	a5,a5,s7
    80002806:	6390                	ld	a2,0(a5)
    80002808:	f661                	bnez	a2,800027d0 <procdump+0x5a>
      state = "???";
    8000280a:	864e                	mv	a2,s3
    8000280c:	b7d1                	j	800027d0 <procdump+0x5a>
  }
}
    8000280e:	60a6                	ld	ra,72(sp)
    80002810:	6406                	ld	s0,64(sp)
    80002812:	74e2                	ld	s1,56(sp)
    80002814:	7942                	ld	s2,48(sp)
    80002816:	79a2                	ld	s3,40(sp)
    80002818:	7a02                	ld	s4,32(sp)
    8000281a:	6ae2                	ld	s5,24(sp)
    8000281c:	6b42                	ld	s6,16(sp)
    8000281e:	6ba2                	ld	s7,8(sp)
    80002820:	6161                	addi	sp,sp,80
    80002822:	8082                	ret

0000000080002824 <swtch>:
    80002824:	00153023          	sd	ra,0(a0)
    80002828:	00253423          	sd	sp,8(a0)
    8000282c:	e900                	sd	s0,16(a0)
    8000282e:	ed04                	sd	s1,24(a0)
    80002830:	03253023          	sd	s2,32(a0)
    80002834:	03353423          	sd	s3,40(a0)
    80002838:	03453823          	sd	s4,48(a0)
    8000283c:	03553c23          	sd	s5,56(a0)
    80002840:	05653023          	sd	s6,64(a0)
    80002844:	05753423          	sd	s7,72(a0)
    80002848:	05853823          	sd	s8,80(a0)
    8000284c:	05953c23          	sd	s9,88(a0)
    80002850:	07a53023          	sd	s10,96(a0)
    80002854:	07b53423          	sd	s11,104(a0)
    80002858:	0005b083          	ld	ra,0(a1)
    8000285c:	0085b103          	ld	sp,8(a1)
    80002860:	6980                	ld	s0,16(a1)
    80002862:	6d84                	ld	s1,24(a1)
    80002864:	0205b903          	ld	s2,32(a1)
    80002868:	0285b983          	ld	s3,40(a1)
    8000286c:	0305ba03          	ld	s4,48(a1)
    80002870:	0385ba83          	ld	s5,56(a1)
    80002874:	0405bb03          	ld	s6,64(a1)
    80002878:	0485bb83          	ld	s7,72(a1)
    8000287c:	0505bc03          	ld	s8,80(a1)
    80002880:	0585bc83          	ld	s9,88(a1)
    80002884:	0605bd03          	ld	s10,96(a1)
    80002888:	0685bd83          	ld	s11,104(a1)
    8000288c:	8082                	ret

000000008000288e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000288e:	1141                	addi	sp,sp,-16
    80002890:	e406                	sd	ra,8(sp)
    80002892:	e022                	sd	s0,0(sp)
    80002894:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002896:	00006597          	auipc	a1,0x6
    8000289a:	a4258593          	addi	a1,a1,-1470 # 800082d8 <states.0+0x28>
    8000289e:	00235517          	auipc	a0,0x235
    800028a2:	ee250513          	addi	a0,a0,-286 # 80237780 <tickslock>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	414080e7          	jalr	1044(ra) # 80000cba <initlock>
}
    800028ae:	60a2                	ld	ra,8(sp)
    800028b0:	6402                	ld	s0,0(sp)
    800028b2:	0141                	addi	sp,sp,16
    800028b4:	8082                	ret

00000000800028b6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028b6:	1141                	addi	sp,sp,-16
    800028b8:	e422                	sd	s0,8(sp)
    800028ba:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028bc:	00003797          	auipc	a5,0x3
    800028c0:	50478793          	addi	a5,a5,1284 # 80005dc0 <kernelvec>
    800028c4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028c8:	6422                	ld	s0,8(sp)
    800028ca:	0141                	addi	sp,sp,16
    800028cc:	8082                	ret

00000000800028ce <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028ce:	1141                	addi	sp,sp,-16
    800028d0:	e406                	sd	ra,8(sp)
    800028d2:	e022                	sd	s0,0(sp)
    800028d4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028d6:	fffff097          	auipc	ra,0xfffff
    800028da:	386080e7          	jalr	902(ra) # 80001c5c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028de:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028e2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028e8:	00004617          	auipc	a2,0x4
    800028ec:	71860613          	addi	a2,a2,1816 # 80007000 <_trampoline>
    800028f0:	00004697          	auipc	a3,0x4
    800028f4:	71068693          	addi	a3,a3,1808 # 80007000 <_trampoline>
    800028f8:	8e91                	sub	a3,a3,a2
    800028fa:	040007b7          	lui	a5,0x4000
    800028fe:	17fd                	addi	a5,a5,-1
    80002900:	07b2                	slli	a5,a5,0xc
    80002902:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002904:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002908:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000290a:	180026f3          	csrr	a3,satp
    8000290e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002910:	6d38                	ld	a4,88(a0)
    80002912:	6134                	ld	a3,64(a0)
    80002914:	6585                	lui	a1,0x1
    80002916:	96ae                	add	a3,a3,a1
    80002918:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000291a:	6d38                	ld	a4,88(a0)
    8000291c:	00000697          	auipc	a3,0x0
    80002920:	13868693          	addi	a3,a3,312 # 80002a54 <usertrap>
    80002924:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002926:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002928:	8692                	mv	a3,tp
    8000292a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002930:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002934:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002938:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000293c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000293e:	6f18                	ld	a4,24(a4)
    80002940:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002944:	692c                	ld	a1,80(a0)
    80002946:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002948:	00004717          	auipc	a4,0x4
    8000294c:	74870713          	addi	a4,a4,1864 # 80007090 <userret>
    80002950:	8f11                	sub	a4,a4,a2
    80002952:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002954:	577d                	li	a4,-1
    80002956:	177e                	slli	a4,a4,0x3f
    80002958:	8dd9                	or	a1,a1,a4
    8000295a:	02000537          	lui	a0,0x2000
    8000295e:	157d                	addi	a0,a0,-1
    80002960:	0536                	slli	a0,a0,0xd
    80002962:	9782                	jalr	a5
}
    80002964:	60a2                	ld	ra,8(sp)
    80002966:	6402                	ld	s0,0(sp)
    80002968:	0141                	addi	sp,sp,16
    8000296a:	8082                	ret

000000008000296c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000296c:	1101                	addi	sp,sp,-32
    8000296e:	ec06                	sd	ra,24(sp)
    80002970:	e822                	sd	s0,16(sp)
    80002972:	e426                	sd	s1,8(sp)
    80002974:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002976:	00235497          	auipc	s1,0x235
    8000297a:	e0a48493          	addi	s1,s1,-502 # 80237780 <tickslock>
    8000297e:	8526                	mv	a0,s1
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	3ca080e7          	jalr	970(ra) # 80000d4a <acquire>
  ticks++;
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	69850513          	addi	a0,a0,1688 # 80009020 <ticks>
    80002990:	411c                	lw	a5,0(a0)
    80002992:	2785                	addiw	a5,a5,1
    80002994:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002996:	00000097          	auipc	ra,0x0
    8000299a:	c5a080e7          	jalr	-934(ra) # 800025f0 <wakeup>
  release(&tickslock);
    8000299e:	8526                	mv	a0,s1
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	45e080e7          	jalr	1118(ra) # 80000dfe <release>
}
    800029a8:	60e2                	ld	ra,24(sp)
    800029aa:	6442                	ld	s0,16(sp)
    800029ac:	64a2                	ld	s1,8(sp)
    800029ae:	6105                	addi	sp,sp,32
    800029b0:	8082                	ret

00000000800029b2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029b2:	1101                	addi	sp,sp,-32
    800029b4:	ec06                	sd	ra,24(sp)
    800029b6:	e822                	sd	s0,16(sp)
    800029b8:	e426                	sd	s1,8(sp)
    800029ba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029bc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029c0:	00074d63          	bltz	a4,800029da <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029c4:	57fd                	li	a5,-1
    800029c6:	17fe                	slli	a5,a5,0x3f
    800029c8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029ca:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029cc:	06f70363          	beq	a4,a5,80002a32 <devintr+0x80>
  }
}
    800029d0:	60e2                	ld	ra,24(sp)
    800029d2:	6442                	ld	s0,16(sp)
    800029d4:	64a2                	ld	s1,8(sp)
    800029d6:	6105                	addi	sp,sp,32
    800029d8:	8082                	ret
     (scause & 0xff) == 9){
    800029da:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029de:	46a5                	li	a3,9
    800029e0:	fed792e3          	bne	a5,a3,800029c4 <devintr+0x12>
    int irq = plic_claim();
    800029e4:	00003097          	auipc	ra,0x3
    800029e8:	4e4080e7          	jalr	1252(ra) # 80005ec8 <plic_claim>
    800029ec:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029ee:	47a9                	li	a5,10
    800029f0:	02f50763          	beq	a0,a5,80002a1e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029f4:	4785                	li	a5,1
    800029f6:	02f50963          	beq	a0,a5,80002a28 <devintr+0x76>
    return 1;
    800029fa:	4505                	li	a0,1
    } else if(irq){
    800029fc:	d8f1                	beqz	s1,800029d0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029fe:	85a6                	mv	a1,s1
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	8e050513          	addi	a0,a0,-1824 # 800082e0 <states.0+0x30>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b84080e7          	jalr	-1148(ra) # 8000058c <printf>
      plic_complete(irq);
    80002a10:	8526                	mv	a0,s1
    80002a12:	00003097          	auipc	ra,0x3
    80002a16:	4da080e7          	jalr	1242(ra) # 80005eec <plic_complete>
    return 1;
    80002a1a:	4505                	li	a0,1
    80002a1c:	bf55                	j	800029d0 <devintr+0x1e>
      uartintr();
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	fa4080e7          	jalr	-92(ra) # 800009c2 <uartintr>
    80002a26:	b7ed                	j	80002a10 <devintr+0x5e>
      virtio_disk_intr();
    80002a28:	00004097          	auipc	ra,0x4
    80002a2c:	93e080e7          	jalr	-1730(ra) # 80006366 <virtio_disk_intr>
    80002a30:	b7c5                	j	80002a10 <devintr+0x5e>
    if(cpuid() == 0){
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	1fe080e7          	jalr	510(ra) # 80001c30 <cpuid>
    80002a3a:	c901                	beqz	a0,80002a4a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a3c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a40:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a42:	14479073          	csrw	sip,a5
    return 2;
    80002a46:	4509                	li	a0,2
    80002a48:	b761                	j	800029d0 <devintr+0x1e>
      clockintr();
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	f22080e7          	jalr	-222(ra) # 8000296c <clockintr>
    80002a52:	b7ed                	j	80002a3c <devintr+0x8a>

0000000080002a54 <usertrap>:
{
    80002a54:	7179                	addi	sp,sp,-48
    80002a56:	f406                	sd	ra,40(sp)
    80002a58:	f022                	sd	s0,32(sp)
    80002a5a:	ec26                	sd	s1,24(sp)
    80002a5c:	e84a                	sd	s2,16(sp)
    80002a5e:	e44e                	sd	s3,8(sp)
    80002a60:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a62:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a66:	1007f793          	andi	a5,a5,256
    80002a6a:	e3b5                	bnez	a5,80002ace <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a6c:	00003797          	auipc	a5,0x3
    80002a70:	35478793          	addi	a5,a5,852 # 80005dc0 <kernelvec>
    80002a74:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	1e4080e7          	jalr	484(ra) # 80001c5c <myproc>
    80002a80:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a82:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a84:	14102773          	csrr	a4,sepc
    80002a88:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a8a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a8e:	47a1                	li	a5,8
    80002a90:	04f71d63          	bne	a4,a5,80002aea <usertrap+0x96>
    if(p->killed)
    80002a94:	591c                	lw	a5,48(a0)
    80002a96:	e7a1                	bnez	a5,80002ade <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002a98:	6cb8                	ld	a4,88(s1)
    80002a9a:	6f1c                	ld	a5,24(a4)
    80002a9c:	0791                	addi	a5,a5,4
    80002a9e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aa4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa8:	10079073          	csrw	sstatus,a5
    syscall();
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	328080e7          	jalr	808(ra) # 80002dd4 <syscall>
  if(p->killed)
    80002ab4:	589c                	lw	a5,48(s1)
    80002ab6:	efe1                	bnez	a5,80002b8e <usertrap+0x13a>
  usertrapret();
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	e16080e7          	jalr	-490(ra) # 800028ce <usertrapret>
}
    80002ac0:	70a2                	ld	ra,40(sp)
    80002ac2:	7402                	ld	s0,32(sp)
    80002ac4:	64e2                	ld	s1,24(sp)
    80002ac6:	6942                	ld	s2,16(sp)
    80002ac8:	69a2                	ld	s3,8(sp)
    80002aca:	6145                	addi	sp,sp,48
    80002acc:	8082                	ret
    panic("usertrap: not from user mode");
    80002ace:	00006517          	auipc	a0,0x6
    80002ad2:	83250513          	addi	a0,a0,-1998 # 80008300 <states.0+0x50>
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	a6c080e7          	jalr	-1428(ra) # 80000542 <panic>
      exit(-1);
    80002ade:	557d                	li	a0,-1
    80002ae0:	00000097          	auipc	ra,0x0
    80002ae4:	84a080e7          	jalr	-1974(ra) # 8000232a <exit>
    80002ae8:	bf45                	j	80002a98 <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	ec8080e7          	jalr	-312(ra) # 800029b2 <devintr>
    80002af2:	892a                	mv	s2,a0
    80002af4:	e951                	bnez	a0,80002b88 <usertrap+0x134>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af6:	14202773          	csrr	a4,scause
  else if((r_scause() == 13)|| (r_scause() == 15))
    80002afa:	47b5                	li	a5,13
    80002afc:	00f70763          	beq	a4,a5,80002b0a <usertrap+0xb6>
    80002b00:	14202773          	csrr	a4,scause
    80002b04:	47bd                	li	a5,15
    80002b06:	04f71763          	bne	a4,a5,80002b54 <usertrap+0x100>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b0a:	143029f3          	csrr	s3,stval
  if(fault_va >= p->sz
    80002b0e:	64bc                	ld	a5,72(s1)
    80002b10:	02f9e163          	bltu	s3,a5,80002b32 <usertrap+0xde>
    p->killed = 1;
    80002b14:	4785                	li	a5,1
    80002b16:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002b18:	557d                	li	a0,-1
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	810080e7          	jalr	-2032(ra) # 8000232a <exit>
  if(which_dev == 2)
    80002b22:	4789                	li	a5,2
    80002b24:	f8f91ae3          	bne	s2,a5,80002ab8 <usertrap+0x64>
    yield();
    80002b28:	00000097          	auipc	ra,0x0
    80002b2c:	90c080e7          	jalr	-1780(ra) # 80002434 <yield>
    80002b30:	b761                	j	80002ab8 <usertrap+0x64>
    || cowpage(p->pagetable, fault_va) != 0
    80002b32:	85ce                	mv	a1,s3
    80002b34:	68a8                	ld	a0,80(s1)
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	e1e080e7          	jalr	-482(ra) # 80001954 <cowpage>
    80002b3e:	f979                	bnez	a0,80002b14 <usertrap+0xc0>
    || cowalloc(p->pagetable, PGROUNDDOWN(fault_va)) == 0)
    80002b40:	75fd                	lui	a1,0xfffff
    80002b42:	00b9f5b3          	and	a1,s3,a1
    80002b46:	68a8                	ld	a0,80(s1)
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	e4a080e7          	jalr	-438(ra) # 80001992 <cowalloc>
    80002b50:	f135                	bnez	a0,80002ab4 <usertrap+0x60>
    80002b52:	b7c9                	j	80002b14 <usertrap+0xc0>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b54:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b58:	5c90                	lw	a2,56(s1)
    80002b5a:	00005517          	auipc	a0,0x5
    80002b5e:	7c650513          	addi	a0,a0,1990 # 80008320 <states.0+0x70>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a2a080e7          	jalr	-1494(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b6e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b72:	00005517          	auipc	a0,0x5
    80002b76:	7de50513          	addi	a0,a0,2014 # 80008350 <states.0+0xa0>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	a12080e7          	jalr	-1518(ra) # 8000058c <printf>
    p->killed = 1;
    80002b82:	4785                	li	a5,1
    80002b84:	d89c                	sw	a5,48(s1)
    80002b86:	bf49                	j	80002b18 <usertrap+0xc4>
  if(p->killed)
    80002b88:	589c                	lw	a5,48(s1)
    80002b8a:	dfc1                	beqz	a5,80002b22 <usertrap+0xce>
    80002b8c:	b771                	j	80002b18 <usertrap+0xc4>
    80002b8e:	4901                	li	s2,0
    80002b90:	b761                	j	80002b18 <usertrap+0xc4>

0000000080002b92 <kerneltrap>:
{
    80002b92:	7179                	addi	sp,sp,-48
    80002b94:	f406                	sd	ra,40(sp)
    80002b96:	f022                	sd	s0,32(sp)
    80002b98:	ec26                	sd	s1,24(sp)
    80002b9a:	e84a                	sd	s2,16(sp)
    80002b9c:	e44e                	sd	s3,8(sp)
    80002b9e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ba8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bac:	1004f793          	andi	a5,s1,256
    80002bb0:	cb85                	beqz	a5,80002be0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bb6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bb8:	ef85                	bnez	a5,80002bf0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	df8080e7          	jalr	-520(ra) # 800029b2 <devintr>
    80002bc2:	cd1d                	beqz	a0,80002c00 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bc4:	4789                	li	a5,2
    80002bc6:	06f50a63          	beq	a0,a5,80002c3a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bca:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bce:	10049073          	csrw	sstatus,s1
}
    80002bd2:	70a2                	ld	ra,40(sp)
    80002bd4:	7402                	ld	s0,32(sp)
    80002bd6:	64e2                	ld	s1,24(sp)
    80002bd8:	6942                	ld	s2,16(sp)
    80002bda:	69a2                	ld	s3,8(sp)
    80002bdc:	6145                	addi	sp,sp,48
    80002bde:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002be0:	00005517          	auipc	a0,0x5
    80002be4:	79050513          	addi	a0,a0,1936 # 80008370 <states.0+0xc0>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	95a080e7          	jalr	-1702(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bf0:	00005517          	auipc	a0,0x5
    80002bf4:	7a850513          	addi	a0,a0,1960 # 80008398 <states.0+0xe8>
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	94a080e7          	jalr	-1718(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002c00:	85ce                	mv	a1,s3
    80002c02:	00005517          	auipc	a0,0x5
    80002c06:	7b650513          	addi	a0,a0,1974 # 800083b8 <states.0+0x108>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	982080e7          	jalr	-1662(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c16:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c1a:	00005517          	auipc	a0,0x5
    80002c1e:	7ae50513          	addi	a0,a0,1966 # 800083c8 <states.0+0x118>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	96a080e7          	jalr	-1686(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002c2a:	00005517          	auipc	a0,0x5
    80002c2e:	7b650513          	addi	a0,a0,1974 # 800083e0 <states.0+0x130>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	910080e7          	jalr	-1776(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	022080e7          	jalr	34(ra) # 80001c5c <myproc>
    80002c42:	d541                	beqz	a0,80002bca <kerneltrap+0x38>
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	018080e7          	jalr	24(ra) # 80001c5c <myproc>
    80002c4c:	4d18                	lw	a4,24(a0)
    80002c4e:	478d                	li	a5,3
    80002c50:	f6f71de3          	bne	a4,a5,80002bca <kerneltrap+0x38>
    yield();
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	7e0080e7          	jalr	2016(ra) # 80002434 <yield>
    80002c5c:	b7bd                	j	80002bca <kerneltrap+0x38>

0000000080002c5e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c5e:	1101                	addi	sp,sp,-32
    80002c60:	ec06                	sd	ra,24(sp)
    80002c62:	e822                	sd	s0,16(sp)
    80002c64:	e426                	sd	s1,8(sp)
    80002c66:	1000                	addi	s0,sp,32
    80002c68:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	ff2080e7          	jalr	-14(ra) # 80001c5c <myproc>
  switch (n) {
    80002c72:	4795                	li	a5,5
    80002c74:	0497e163          	bltu	a5,s1,80002cb6 <argraw+0x58>
    80002c78:	048a                	slli	s1,s1,0x2
    80002c7a:	00005717          	auipc	a4,0x5
    80002c7e:	79e70713          	addi	a4,a4,1950 # 80008418 <states.0+0x168>
    80002c82:	94ba                	add	s1,s1,a4
    80002c84:	409c                	lw	a5,0(s1)
    80002c86:	97ba                	add	a5,a5,a4
    80002c88:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c8a:	6d3c                	ld	a5,88(a0)
    80002c8c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6105                	addi	sp,sp,32
    80002c96:	8082                	ret
    return p->trapframe->a1;
    80002c98:	6d3c                	ld	a5,88(a0)
    80002c9a:	7fa8                	ld	a0,120(a5)
    80002c9c:	bfcd                	j	80002c8e <argraw+0x30>
    return p->trapframe->a2;
    80002c9e:	6d3c                	ld	a5,88(a0)
    80002ca0:	63c8                	ld	a0,128(a5)
    80002ca2:	b7f5                	j	80002c8e <argraw+0x30>
    return p->trapframe->a3;
    80002ca4:	6d3c                	ld	a5,88(a0)
    80002ca6:	67c8                	ld	a0,136(a5)
    80002ca8:	b7dd                	j	80002c8e <argraw+0x30>
    return p->trapframe->a4;
    80002caa:	6d3c                	ld	a5,88(a0)
    80002cac:	6bc8                	ld	a0,144(a5)
    80002cae:	b7c5                	j	80002c8e <argraw+0x30>
    return p->trapframe->a5;
    80002cb0:	6d3c                	ld	a5,88(a0)
    80002cb2:	6fc8                	ld	a0,152(a5)
    80002cb4:	bfe9                	j	80002c8e <argraw+0x30>
  panic("argraw");
    80002cb6:	00005517          	auipc	a0,0x5
    80002cba:	73a50513          	addi	a0,a0,1850 # 800083f0 <states.0+0x140>
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	884080e7          	jalr	-1916(ra) # 80000542 <panic>

0000000080002cc6 <fetchaddr>:
{
    80002cc6:	1101                	addi	sp,sp,-32
    80002cc8:	ec06                	sd	ra,24(sp)
    80002cca:	e822                	sd	s0,16(sp)
    80002ccc:	e426                	sd	s1,8(sp)
    80002cce:	e04a                	sd	s2,0(sp)
    80002cd0:	1000                	addi	s0,sp,32
    80002cd2:	84aa                	mv	s1,a0
    80002cd4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	f86080e7          	jalr	-122(ra) # 80001c5c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cde:	653c                	ld	a5,72(a0)
    80002ce0:	02f4f863          	bgeu	s1,a5,80002d10 <fetchaddr+0x4a>
    80002ce4:	00848713          	addi	a4,s1,8
    80002ce8:	02e7e663          	bltu	a5,a4,80002d14 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cec:	46a1                	li	a3,8
    80002cee:	8626                	mv	a2,s1
    80002cf0:	85ca                	mv	a1,s2
    80002cf2:	6928                	ld	a0,80(a0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	b1e080e7          	jalr	-1250(ra) # 80001812 <copyin>
    80002cfc:	00a03533          	snez	a0,a0
    80002d00:	40a00533          	neg	a0,a0
}
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	64a2                	ld	s1,8(sp)
    80002d0a:	6902                	ld	s2,0(sp)
    80002d0c:	6105                	addi	sp,sp,32
    80002d0e:	8082                	ret
    return -1;
    80002d10:	557d                	li	a0,-1
    80002d12:	bfcd                	j	80002d04 <fetchaddr+0x3e>
    80002d14:	557d                	li	a0,-1
    80002d16:	b7fd                	j	80002d04 <fetchaddr+0x3e>

0000000080002d18 <fetchstr>:
{
    80002d18:	7179                	addi	sp,sp,-48
    80002d1a:	f406                	sd	ra,40(sp)
    80002d1c:	f022                	sd	s0,32(sp)
    80002d1e:	ec26                	sd	s1,24(sp)
    80002d20:	e84a                	sd	s2,16(sp)
    80002d22:	e44e                	sd	s3,8(sp)
    80002d24:	1800                	addi	s0,sp,48
    80002d26:	892a                	mv	s2,a0
    80002d28:	84ae                	mv	s1,a1
    80002d2a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	f30080e7          	jalr	-208(ra) # 80001c5c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d34:	86ce                	mv	a3,s3
    80002d36:	864a                	mv	a2,s2
    80002d38:	85a6                	mv	a1,s1
    80002d3a:	6928                	ld	a0,80(a0)
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	b64080e7          	jalr	-1180(ra) # 800018a0 <copyinstr>
  if(err < 0)
    80002d44:	00054763          	bltz	a0,80002d52 <fetchstr+0x3a>
  return strlen(buf);
    80002d48:	8526                	mv	a0,s1
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	280080e7          	jalr	640(ra) # 80000fca <strlen>
}
    80002d52:	70a2                	ld	ra,40(sp)
    80002d54:	7402                	ld	s0,32(sp)
    80002d56:	64e2                	ld	s1,24(sp)
    80002d58:	6942                	ld	s2,16(sp)
    80002d5a:	69a2                	ld	s3,8(sp)
    80002d5c:	6145                	addi	sp,sp,48
    80002d5e:	8082                	ret

0000000080002d60 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d60:	1101                	addi	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	1000                	addi	s0,sp,32
    80002d6a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	ef2080e7          	jalr	-270(ra) # 80002c5e <argraw>
    80002d74:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d76:	4501                	li	a0,0
    80002d78:	60e2                	ld	ra,24(sp)
    80002d7a:	6442                	ld	s0,16(sp)
    80002d7c:	64a2                	ld	s1,8(sp)
    80002d7e:	6105                	addi	sp,sp,32
    80002d80:	8082                	ret

0000000080002d82 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d82:	1101                	addi	sp,sp,-32
    80002d84:	ec06                	sd	ra,24(sp)
    80002d86:	e822                	sd	s0,16(sp)
    80002d88:	e426                	sd	s1,8(sp)
    80002d8a:	1000                	addi	s0,sp,32
    80002d8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	ed0080e7          	jalr	-304(ra) # 80002c5e <argraw>
    80002d96:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d98:	4501                	li	a0,0
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	64a2                	ld	s1,8(sp)
    80002da0:	6105                	addi	sp,sp,32
    80002da2:	8082                	ret

0000000080002da4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	e426                	sd	s1,8(sp)
    80002dac:	e04a                	sd	s2,0(sp)
    80002dae:	1000                	addi	s0,sp,32
    80002db0:	84ae                	mv	s1,a1
    80002db2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002db4:	00000097          	auipc	ra,0x0
    80002db8:	eaa080e7          	jalr	-342(ra) # 80002c5e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dbc:	864a                	mv	a2,s2
    80002dbe:	85a6                	mv	a1,s1
    80002dc0:	00000097          	auipc	ra,0x0
    80002dc4:	f58080e7          	jalr	-168(ra) # 80002d18 <fetchstr>
}
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	64a2                	ld	s1,8(sp)
    80002dce:	6902                	ld	s2,0(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002dd4:	1101                	addi	sp,sp,-32
    80002dd6:	ec06                	sd	ra,24(sp)
    80002dd8:	e822                	sd	s0,16(sp)
    80002dda:	e426                	sd	s1,8(sp)
    80002ddc:	e04a                	sd	s2,0(sp)
    80002dde:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	e7c080e7          	jalr	-388(ra) # 80001c5c <myproc>
    80002de8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dea:	05853903          	ld	s2,88(a0)
    80002dee:	0a893783          	ld	a5,168(s2)
    80002df2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002df6:	37fd                	addiw	a5,a5,-1
    80002df8:	4751                	li	a4,20
    80002dfa:	00f76f63          	bltu	a4,a5,80002e18 <syscall+0x44>
    80002dfe:	00369713          	slli	a4,a3,0x3
    80002e02:	00005797          	auipc	a5,0x5
    80002e06:	62e78793          	addi	a5,a5,1582 # 80008430 <syscalls>
    80002e0a:	97ba                	add	a5,a5,a4
    80002e0c:	639c                	ld	a5,0(a5)
    80002e0e:	c789                	beqz	a5,80002e18 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e10:	9782                	jalr	a5
    80002e12:	06a93823          	sd	a0,112(s2)
    80002e16:	a839                	j	80002e34 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e18:	15848613          	addi	a2,s1,344
    80002e1c:	5c8c                	lw	a1,56(s1)
    80002e1e:	00005517          	auipc	a0,0x5
    80002e22:	5da50513          	addi	a0,a0,1498 # 800083f8 <states.0+0x148>
    80002e26:	ffffd097          	auipc	ra,0xffffd
    80002e2a:	766080e7          	jalr	1894(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e2e:	6cbc                	ld	a5,88(s1)
    80002e30:	577d                	li	a4,-1
    80002e32:	fbb8                	sd	a4,112(a5)
  }
}
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	64a2                	ld	s1,8(sp)
    80002e3a:	6902                	ld	s2,0(sp)
    80002e3c:	6105                	addi	sp,sp,32
    80002e3e:	8082                	ret

0000000080002e40 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e40:	1101                	addi	sp,sp,-32
    80002e42:	ec06                	sd	ra,24(sp)
    80002e44:	e822                	sd	s0,16(sp)
    80002e46:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e48:	fec40593          	addi	a1,s0,-20
    80002e4c:	4501                	li	a0,0
    80002e4e:	00000097          	auipc	ra,0x0
    80002e52:	f12080e7          	jalr	-238(ra) # 80002d60 <argint>
    return -1;
    80002e56:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e58:	00054963          	bltz	a0,80002e6a <sys_exit+0x2a>
  exit(n);
    80002e5c:	fec42503          	lw	a0,-20(s0)
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	4ca080e7          	jalr	1226(ra) # 8000232a <exit>
  return 0;  // not reached
    80002e68:	4781                	li	a5,0
}
    80002e6a:	853e                	mv	a0,a5
    80002e6c:	60e2                	ld	ra,24(sp)
    80002e6e:	6442                	ld	s0,16(sp)
    80002e70:	6105                	addi	sp,sp,32
    80002e72:	8082                	ret

0000000080002e74 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e74:	1141                	addi	sp,sp,-16
    80002e76:	e406                	sd	ra,8(sp)
    80002e78:	e022                	sd	s0,0(sp)
    80002e7a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	de0080e7          	jalr	-544(ra) # 80001c5c <myproc>
}
    80002e84:	5d08                	lw	a0,56(a0)
    80002e86:	60a2                	ld	ra,8(sp)
    80002e88:	6402                	ld	s0,0(sp)
    80002e8a:	0141                	addi	sp,sp,16
    80002e8c:	8082                	ret

0000000080002e8e <sys_fork>:

uint64
sys_fork(void)
{
    80002e8e:	1141                	addi	sp,sp,-16
    80002e90:	e406                	sd	ra,8(sp)
    80002e92:	e022                	sd	s0,0(sp)
    80002e94:	0800                	addi	s0,sp,16
  return fork();
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	186080e7          	jalr	390(ra) # 8000201c <fork>
}
    80002e9e:	60a2                	ld	ra,8(sp)
    80002ea0:	6402                	ld	s0,0(sp)
    80002ea2:	0141                	addi	sp,sp,16
    80002ea4:	8082                	ret

0000000080002ea6 <sys_wait>:

uint64
sys_wait(void)
{
    80002ea6:	1101                	addi	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002eae:	fe840593          	addi	a1,s0,-24
    80002eb2:	4501                	li	a0,0
    80002eb4:	00000097          	auipc	ra,0x0
    80002eb8:	ece080e7          	jalr	-306(ra) # 80002d82 <argaddr>
    80002ebc:	87aa                	mv	a5,a0
    return -1;
    80002ebe:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ec0:	0007c863          	bltz	a5,80002ed0 <sys_wait+0x2a>
  return wait(p);
    80002ec4:	fe843503          	ld	a0,-24(s0)
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	626080e7          	jalr	1574(ra) # 800024ee <wait>
}
    80002ed0:	60e2                	ld	ra,24(sp)
    80002ed2:	6442                	ld	s0,16(sp)
    80002ed4:	6105                	addi	sp,sp,32
    80002ed6:	8082                	ret

0000000080002ed8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ed8:	7179                	addi	sp,sp,-48
    80002eda:	f406                	sd	ra,40(sp)
    80002edc:	f022                	sd	s0,32(sp)
    80002ede:	ec26                	sd	s1,24(sp)
    80002ee0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ee2:	fdc40593          	addi	a1,s0,-36
    80002ee6:	4501                	li	a0,0
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	e78080e7          	jalr	-392(ra) # 80002d60 <argint>
    return -1;
    80002ef0:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002ef2:	00054f63          	bltz	a0,80002f10 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	d66080e7          	jalr	-666(ra) # 80001c5c <myproc>
    80002efe:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f00:	fdc42503          	lw	a0,-36(s0)
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	0a4080e7          	jalr	164(ra) # 80001fa8 <growproc>
    80002f0c:	00054863          	bltz	a0,80002f1c <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002f10:	8526                	mv	a0,s1
    80002f12:	70a2                	ld	ra,40(sp)
    80002f14:	7402                	ld	s0,32(sp)
    80002f16:	64e2                	ld	s1,24(sp)
    80002f18:	6145                	addi	sp,sp,48
    80002f1a:	8082                	ret
    return -1;
    80002f1c:	54fd                	li	s1,-1
    80002f1e:	bfcd                	j	80002f10 <sys_sbrk+0x38>

0000000080002f20 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f20:	7139                	addi	sp,sp,-64
    80002f22:	fc06                	sd	ra,56(sp)
    80002f24:	f822                	sd	s0,48(sp)
    80002f26:	f426                	sd	s1,40(sp)
    80002f28:	f04a                	sd	s2,32(sp)
    80002f2a:	ec4e                	sd	s3,24(sp)
    80002f2c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f2e:	fcc40593          	addi	a1,s0,-52
    80002f32:	4501                	li	a0,0
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	e2c080e7          	jalr	-468(ra) # 80002d60 <argint>
    return -1;
    80002f3c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f3e:	06054563          	bltz	a0,80002fa8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f42:	00235517          	auipc	a0,0x235
    80002f46:	83e50513          	addi	a0,a0,-1986 # 80237780 <tickslock>
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	e00080e7          	jalr	-512(ra) # 80000d4a <acquire>
  ticks0 = ticks;
    80002f52:	00006917          	auipc	s2,0x6
    80002f56:	0ce92903          	lw	s2,206(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f5a:	fcc42783          	lw	a5,-52(s0)
    80002f5e:	cf85                	beqz	a5,80002f96 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f60:	00235997          	auipc	s3,0x235
    80002f64:	82098993          	addi	s3,s3,-2016 # 80237780 <tickslock>
    80002f68:	00006497          	auipc	s1,0x6
    80002f6c:	0b848493          	addi	s1,s1,184 # 80009020 <ticks>
    if(myproc()->killed){
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	cec080e7          	jalr	-788(ra) # 80001c5c <myproc>
    80002f78:	591c                	lw	a5,48(a0)
    80002f7a:	ef9d                	bnez	a5,80002fb8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f7c:	85ce                	mv	a1,s3
    80002f7e:	8526                	mv	a0,s1
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	4f0080e7          	jalr	1264(ra) # 80002470 <sleep>
  while(ticks - ticks0 < n){
    80002f88:	409c                	lw	a5,0(s1)
    80002f8a:	412787bb          	subw	a5,a5,s2
    80002f8e:	fcc42703          	lw	a4,-52(s0)
    80002f92:	fce7efe3          	bltu	a5,a4,80002f70 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f96:	00234517          	auipc	a0,0x234
    80002f9a:	7ea50513          	addi	a0,a0,2026 # 80237780 <tickslock>
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	e60080e7          	jalr	-416(ra) # 80000dfe <release>
  return 0;
    80002fa6:	4781                	li	a5,0
}
    80002fa8:	853e                	mv	a0,a5
    80002faa:	70e2                	ld	ra,56(sp)
    80002fac:	7442                	ld	s0,48(sp)
    80002fae:	74a2                	ld	s1,40(sp)
    80002fb0:	7902                	ld	s2,32(sp)
    80002fb2:	69e2                	ld	s3,24(sp)
    80002fb4:	6121                	addi	sp,sp,64
    80002fb6:	8082                	ret
      release(&tickslock);
    80002fb8:	00234517          	auipc	a0,0x234
    80002fbc:	7c850513          	addi	a0,a0,1992 # 80237780 <tickslock>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	e3e080e7          	jalr	-450(ra) # 80000dfe <release>
      return -1;
    80002fc8:	57fd                	li	a5,-1
    80002fca:	bff9                	j	80002fa8 <sys_sleep+0x88>

0000000080002fcc <sys_kill>:

uint64
sys_kill(void)
{
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fd4:	fec40593          	addi	a1,s0,-20
    80002fd8:	4501                	li	a0,0
    80002fda:	00000097          	auipc	ra,0x0
    80002fde:	d86080e7          	jalr	-634(ra) # 80002d60 <argint>
    80002fe2:	87aa                	mv	a5,a0
    return -1;
    80002fe4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fe6:	0007c863          	bltz	a5,80002ff6 <sys_kill+0x2a>
  return kill(pid);
    80002fea:	fec42503          	lw	a0,-20(s0)
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	66c080e7          	jalr	1644(ra) # 8000265a <kill>
}
    80002ff6:	60e2                	ld	ra,24(sp)
    80002ff8:	6442                	ld	s0,16(sp)
    80002ffa:	6105                	addi	sp,sp,32
    80002ffc:	8082                	ret

0000000080002ffe <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	e426                	sd	s1,8(sp)
    80003006:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003008:	00234517          	auipc	a0,0x234
    8000300c:	77850513          	addi	a0,a0,1912 # 80237780 <tickslock>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	d3a080e7          	jalr	-710(ra) # 80000d4a <acquire>
  xticks = ticks;
    80003018:	00006497          	auipc	s1,0x6
    8000301c:	0084a483          	lw	s1,8(s1) # 80009020 <ticks>
  release(&tickslock);
    80003020:	00234517          	auipc	a0,0x234
    80003024:	76050513          	addi	a0,a0,1888 # 80237780 <tickslock>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	dd6080e7          	jalr	-554(ra) # 80000dfe <release>
  return xticks;
}
    80003030:	02049513          	slli	a0,s1,0x20
    80003034:	9101                	srli	a0,a0,0x20
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	64a2                	ld	s1,8(sp)
    8000303c:	6105                	addi	sp,sp,32
    8000303e:	8082                	ret

0000000080003040 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003040:	7179                	addi	sp,sp,-48
    80003042:	f406                	sd	ra,40(sp)
    80003044:	f022                	sd	s0,32(sp)
    80003046:	ec26                	sd	s1,24(sp)
    80003048:	e84a                	sd	s2,16(sp)
    8000304a:	e44e                	sd	s3,8(sp)
    8000304c:	e052                	sd	s4,0(sp)
    8000304e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003050:	00005597          	auipc	a1,0x5
    80003054:	49058593          	addi	a1,a1,1168 # 800084e0 <syscalls+0xb0>
    80003058:	00234517          	auipc	a0,0x234
    8000305c:	74050513          	addi	a0,a0,1856 # 80237798 <bcache>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	c5a080e7          	jalr	-934(ra) # 80000cba <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003068:	0023c797          	auipc	a5,0x23c
    8000306c:	73078793          	addi	a5,a5,1840 # 8023f798 <bcache+0x8000>
    80003070:	0023d717          	auipc	a4,0x23d
    80003074:	99070713          	addi	a4,a4,-1648 # 8023fa00 <bcache+0x8268>
    80003078:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000307c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003080:	00234497          	auipc	s1,0x234
    80003084:	73048493          	addi	s1,s1,1840 # 802377b0 <bcache+0x18>
    b->next = bcache.head.next;
    80003088:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000308a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000308c:	00005a17          	auipc	s4,0x5
    80003090:	45ca0a13          	addi	s4,s4,1116 # 800084e8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003094:	2b893783          	ld	a5,696(s2)
    80003098:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000309a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000309e:	85d2                	mv	a1,s4
    800030a0:	01048513          	addi	a0,s1,16
    800030a4:	00001097          	auipc	ra,0x1
    800030a8:	4b0080e7          	jalr	1200(ra) # 80004554 <initsleeplock>
    bcache.head.next->prev = b;
    800030ac:	2b893783          	ld	a5,696(s2)
    800030b0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030b2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b6:	45848493          	addi	s1,s1,1112
    800030ba:	fd349de3          	bne	s1,s3,80003094 <binit+0x54>
  }
}
    800030be:	70a2                	ld	ra,40(sp)
    800030c0:	7402                	ld	s0,32(sp)
    800030c2:	64e2                	ld	s1,24(sp)
    800030c4:	6942                	ld	s2,16(sp)
    800030c6:	69a2                	ld	s3,8(sp)
    800030c8:	6a02                	ld	s4,0(sp)
    800030ca:	6145                	addi	sp,sp,48
    800030cc:	8082                	ret

00000000800030ce <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030ce:	7179                	addi	sp,sp,-48
    800030d0:	f406                	sd	ra,40(sp)
    800030d2:	f022                	sd	s0,32(sp)
    800030d4:	ec26                	sd	s1,24(sp)
    800030d6:	e84a                	sd	s2,16(sp)
    800030d8:	e44e                	sd	s3,8(sp)
    800030da:	1800                	addi	s0,sp,48
    800030dc:	892a                	mv	s2,a0
    800030de:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030e0:	00234517          	auipc	a0,0x234
    800030e4:	6b850513          	addi	a0,a0,1720 # 80237798 <bcache>
    800030e8:	ffffe097          	auipc	ra,0xffffe
    800030ec:	c62080e7          	jalr	-926(ra) # 80000d4a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030f0:	0023d497          	auipc	s1,0x23d
    800030f4:	9604b483          	ld	s1,-1696(s1) # 8023fa50 <bcache+0x82b8>
    800030f8:	0023d797          	auipc	a5,0x23d
    800030fc:	90878793          	addi	a5,a5,-1784 # 8023fa00 <bcache+0x8268>
    80003100:	02f48f63          	beq	s1,a5,8000313e <bread+0x70>
    80003104:	873e                	mv	a4,a5
    80003106:	a021                	j	8000310e <bread+0x40>
    80003108:	68a4                	ld	s1,80(s1)
    8000310a:	02e48a63          	beq	s1,a4,8000313e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000310e:	449c                	lw	a5,8(s1)
    80003110:	ff279ce3          	bne	a5,s2,80003108 <bread+0x3a>
    80003114:	44dc                	lw	a5,12(s1)
    80003116:	ff3799e3          	bne	a5,s3,80003108 <bread+0x3a>
      b->refcnt++;
    8000311a:	40bc                	lw	a5,64(s1)
    8000311c:	2785                	addiw	a5,a5,1
    8000311e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003120:	00234517          	auipc	a0,0x234
    80003124:	67850513          	addi	a0,a0,1656 # 80237798 <bcache>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	cd6080e7          	jalr	-810(ra) # 80000dfe <release>
      acquiresleep(&b->lock);
    80003130:	01048513          	addi	a0,s1,16
    80003134:	00001097          	auipc	ra,0x1
    80003138:	45a080e7          	jalr	1114(ra) # 8000458e <acquiresleep>
      return b;
    8000313c:	a8b9                	j	8000319a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000313e:	0023d497          	auipc	s1,0x23d
    80003142:	90a4b483          	ld	s1,-1782(s1) # 8023fa48 <bcache+0x82b0>
    80003146:	0023d797          	auipc	a5,0x23d
    8000314a:	8ba78793          	addi	a5,a5,-1862 # 8023fa00 <bcache+0x8268>
    8000314e:	00f48863          	beq	s1,a5,8000315e <bread+0x90>
    80003152:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003154:	40bc                	lw	a5,64(s1)
    80003156:	cf81                	beqz	a5,8000316e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003158:	64a4                	ld	s1,72(s1)
    8000315a:	fee49de3          	bne	s1,a4,80003154 <bread+0x86>
  panic("bget: no buffers");
    8000315e:	00005517          	auipc	a0,0x5
    80003162:	39250513          	addi	a0,a0,914 # 800084f0 <syscalls+0xc0>
    80003166:	ffffd097          	auipc	ra,0xffffd
    8000316a:	3dc080e7          	jalr	988(ra) # 80000542 <panic>
      b->dev = dev;
    8000316e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003172:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003176:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000317a:	4785                	li	a5,1
    8000317c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000317e:	00234517          	auipc	a0,0x234
    80003182:	61a50513          	addi	a0,a0,1562 # 80237798 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	c78080e7          	jalr	-904(ra) # 80000dfe <release>
      acquiresleep(&b->lock);
    8000318e:	01048513          	addi	a0,s1,16
    80003192:	00001097          	auipc	ra,0x1
    80003196:	3fc080e7          	jalr	1020(ra) # 8000458e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000319a:	409c                	lw	a5,0(s1)
    8000319c:	cb89                	beqz	a5,800031ae <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000319e:	8526                	mv	a0,s1
    800031a0:	70a2                	ld	ra,40(sp)
    800031a2:	7402                	ld	s0,32(sp)
    800031a4:	64e2                	ld	s1,24(sp)
    800031a6:	6942                	ld	s2,16(sp)
    800031a8:	69a2                	ld	s3,8(sp)
    800031aa:	6145                	addi	sp,sp,48
    800031ac:	8082                	ret
    virtio_disk_rw(b, 0);
    800031ae:	4581                	li	a1,0
    800031b0:	8526                	mv	a0,s1
    800031b2:	00003097          	auipc	ra,0x3
    800031b6:	f2a080e7          	jalr	-214(ra) # 800060dc <virtio_disk_rw>
    b->valid = 1;
    800031ba:	4785                	li	a5,1
    800031bc:	c09c                	sw	a5,0(s1)
  return b;
    800031be:	b7c5                	j	8000319e <bread+0xd0>

00000000800031c0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	1000                	addi	s0,sp,32
    800031ca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031cc:	0541                	addi	a0,a0,16
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	45a080e7          	jalr	1114(ra) # 80004628 <holdingsleep>
    800031d6:	cd01                	beqz	a0,800031ee <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031d8:	4585                	li	a1,1
    800031da:	8526                	mv	a0,s1
    800031dc:	00003097          	auipc	ra,0x3
    800031e0:	f00080e7          	jalr	-256(ra) # 800060dc <virtio_disk_rw>
}
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	64a2                	ld	s1,8(sp)
    800031ea:	6105                	addi	sp,sp,32
    800031ec:	8082                	ret
    panic("bwrite");
    800031ee:	00005517          	auipc	a0,0x5
    800031f2:	31a50513          	addi	a0,a0,794 # 80008508 <syscalls+0xd8>
    800031f6:	ffffd097          	auipc	ra,0xffffd
    800031fa:	34c080e7          	jalr	844(ra) # 80000542 <panic>

00000000800031fe <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031fe:	1101                	addi	sp,sp,-32
    80003200:	ec06                	sd	ra,24(sp)
    80003202:	e822                	sd	s0,16(sp)
    80003204:	e426                	sd	s1,8(sp)
    80003206:	e04a                	sd	s2,0(sp)
    80003208:	1000                	addi	s0,sp,32
    8000320a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000320c:	01050913          	addi	s2,a0,16
    80003210:	854a                	mv	a0,s2
    80003212:	00001097          	auipc	ra,0x1
    80003216:	416080e7          	jalr	1046(ra) # 80004628 <holdingsleep>
    8000321a:	c92d                	beqz	a0,8000328c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000321c:	854a                	mv	a0,s2
    8000321e:	00001097          	auipc	ra,0x1
    80003222:	3c6080e7          	jalr	966(ra) # 800045e4 <releasesleep>

  acquire(&bcache.lock);
    80003226:	00234517          	auipc	a0,0x234
    8000322a:	57250513          	addi	a0,a0,1394 # 80237798 <bcache>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	b1c080e7          	jalr	-1252(ra) # 80000d4a <acquire>
  b->refcnt--;
    80003236:	40bc                	lw	a5,64(s1)
    80003238:	37fd                	addiw	a5,a5,-1
    8000323a:	0007871b          	sext.w	a4,a5
    8000323e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003240:	eb05                	bnez	a4,80003270 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003242:	68bc                	ld	a5,80(s1)
    80003244:	64b8                	ld	a4,72(s1)
    80003246:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003248:	64bc                	ld	a5,72(s1)
    8000324a:	68b8                	ld	a4,80(s1)
    8000324c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000324e:	0023c797          	auipc	a5,0x23c
    80003252:	54a78793          	addi	a5,a5,1354 # 8023f798 <bcache+0x8000>
    80003256:	2b87b703          	ld	a4,696(a5)
    8000325a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000325c:	0023c717          	auipc	a4,0x23c
    80003260:	7a470713          	addi	a4,a4,1956 # 8023fa00 <bcache+0x8268>
    80003264:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003266:	2b87b703          	ld	a4,696(a5)
    8000326a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000326c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003270:	00234517          	auipc	a0,0x234
    80003274:	52850513          	addi	a0,a0,1320 # 80237798 <bcache>
    80003278:	ffffe097          	auipc	ra,0xffffe
    8000327c:	b86080e7          	jalr	-1146(ra) # 80000dfe <release>
}
    80003280:	60e2                	ld	ra,24(sp)
    80003282:	6442                	ld	s0,16(sp)
    80003284:	64a2                	ld	s1,8(sp)
    80003286:	6902                	ld	s2,0(sp)
    80003288:	6105                	addi	sp,sp,32
    8000328a:	8082                	ret
    panic("brelse");
    8000328c:	00005517          	auipc	a0,0x5
    80003290:	28450513          	addi	a0,a0,644 # 80008510 <syscalls+0xe0>
    80003294:	ffffd097          	auipc	ra,0xffffd
    80003298:	2ae080e7          	jalr	686(ra) # 80000542 <panic>

000000008000329c <bpin>:

void
bpin(struct buf *b) {
    8000329c:	1101                	addi	sp,sp,-32
    8000329e:	ec06                	sd	ra,24(sp)
    800032a0:	e822                	sd	s0,16(sp)
    800032a2:	e426                	sd	s1,8(sp)
    800032a4:	1000                	addi	s0,sp,32
    800032a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032a8:	00234517          	auipc	a0,0x234
    800032ac:	4f050513          	addi	a0,a0,1264 # 80237798 <bcache>
    800032b0:	ffffe097          	auipc	ra,0xffffe
    800032b4:	a9a080e7          	jalr	-1382(ra) # 80000d4a <acquire>
  b->refcnt++;
    800032b8:	40bc                	lw	a5,64(s1)
    800032ba:	2785                	addiw	a5,a5,1
    800032bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032be:	00234517          	auipc	a0,0x234
    800032c2:	4da50513          	addi	a0,a0,1242 # 80237798 <bcache>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	b38080e7          	jalr	-1224(ra) # 80000dfe <release>
}
    800032ce:	60e2                	ld	ra,24(sp)
    800032d0:	6442                	ld	s0,16(sp)
    800032d2:	64a2                	ld	s1,8(sp)
    800032d4:	6105                	addi	sp,sp,32
    800032d6:	8082                	ret

00000000800032d8 <bunpin>:

void
bunpin(struct buf *b) {
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	e426                	sd	s1,8(sp)
    800032e0:	1000                	addi	s0,sp,32
    800032e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e4:	00234517          	auipc	a0,0x234
    800032e8:	4b450513          	addi	a0,a0,1204 # 80237798 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	a5e080e7          	jalr	-1442(ra) # 80000d4a <acquire>
  b->refcnt--;
    800032f4:	40bc                	lw	a5,64(s1)
    800032f6:	37fd                	addiw	a5,a5,-1
    800032f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032fa:	00234517          	auipc	a0,0x234
    800032fe:	49e50513          	addi	a0,a0,1182 # 80237798 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	afc080e7          	jalr	-1284(ra) # 80000dfe <release>
}
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	64a2                	ld	s1,8(sp)
    80003310:	6105                	addi	sp,sp,32
    80003312:	8082                	ret

0000000080003314 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003314:	1101                	addi	sp,sp,-32
    80003316:	ec06                	sd	ra,24(sp)
    80003318:	e822                	sd	s0,16(sp)
    8000331a:	e426                	sd	s1,8(sp)
    8000331c:	e04a                	sd	s2,0(sp)
    8000331e:	1000                	addi	s0,sp,32
    80003320:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003322:	00d5d59b          	srliw	a1,a1,0xd
    80003326:	0023d797          	auipc	a5,0x23d
    8000332a:	b4e7a783          	lw	a5,-1202(a5) # 8023fe74 <sb+0x1c>
    8000332e:	9dbd                	addw	a1,a1,a5
    80003330:	00000097          	auipc	ra,0x0
    80003334:	d9e080e7          	jalr	-610(ra) # 800030ce <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003338:	0074f713          	andi	a4,s1,7
    8000333c:	4785                	li	a5,1
    8000333e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003342:	14ce                	slli	s1,s1,0x33
    80003344:	90d9                	srli	s1,s1,0x36
    80003346:	00950733          	add	a4,a0,s1
    8000334a:	05874703          	lbu	a4,88(a4)
    8000334e:	00e7f6b3          	and	a3,a5,a4
    80003352:	c69d                	beqz	a3,80003380 <bfree+0x6c>
    80003354:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003356:	94aa                	add	s1,s1,a0
    80003358:	fff7c793          	not	a5,a5
    8000335c:	8ff9                	and	a5,a5,a4
    8000335e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003362:	00001097          	auipc	ra,0x1
    80003366:	104080e7          	jalr	260(ra) # 80004466 <log_write>
  brelse(bp);
    8000336a:	854a                	mv	a0,s2
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	e92080e7          	jalr	-366(ra) # 800031fe <brelse>
}
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6902                	ld	s2,0(sp)
    8000337c:	6105                	addi	sp,sp,32
    8000337e:	8082                	ret
    panic("freeing free block");
    80003380:	00005517          	auipc	a0,0x5
    80003384:	19850513          	addi	a0,a0,408 # 80008518 <syscalls+0xe8>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	1ba080e7          	jalr	442(ra) # 80000542 <panic>

0000000080003390 <balloc>:
{
    80003390:	711d                	addi	sp,sp,-96
    80003392:	ec86                	sd	ra,88(sp)
    80003394:	e8a2                	sd	s0,80(sp)
    80003396:	e4a6                	sd	s1,72(sp)
    80003398:	e0ca                	sd	s2,64(sp)
    8000339a:	fc4e                	sd	s3,56(sp)
    8000339c:	f852                	sd	s4,48(sp)
    8000339e:	f456                	sd	s5,40(sp)
    800033a0:	f05a                	sd	s6,32(sp)
    800033a2:	ec5e                	sd	s7,24(sp)
    800033a4:	e862                	sd	s8,16(sp)
    800033a6:	e466                	sd	s9,8(sp)
    800033a8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033aa:	0023d797          	auipc	a5,0x23d
    800033ae:	ab27a783          	lw	a5,-1358(a5) # 8023fe5c <sb+0x4>
    800033b2:	cbd1                	beqz	a5,80003446 <balloc+0xb6>
    800033b4:	8baa                	mv	s7,a0
    800033b6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033b8:	0023db17          	auipc	s6,0x23d
    800033bc:	aa0b0b13          	addi	s6,s6,-1376 # 8023fe58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033c2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033c6:	6c89                	lui	s9,0x2
    800033c8:	a831                	j	800033e4 <balloc+0x54>
    brelse(bp);
    800033ca:	854a                	mv	a0,s2
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	e32080e7          	jalr	-462(ra) # 800031fe <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033d4:	015c87bb          	addw	a5,s9,s5
    800033d8:	00078a9b          	sext.w	s5,a5
    800033dc:	004b2703          	lw	a4,4(s6)
    800033e0:	06eaf363          	bgeu	s5,a4,80003446 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033e4:	41fad79b          	sraiw	a5,s5,0x1f
    800033e8:	0137d79b          	srliw	a5,a5,0x13
    800033ec:	015787bb          	addw	a5,a5,s5
    800033f0:	40d7d79b          	sraiw	a5,a5,0xd
    800033f4:	01cb2583          	lw	a1,28(s6)
    800033f8:	9dbd                	addw	a1,a1,a5
    800033fa:	855e                	mv	a0,s7
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	cd2080e7          	jalr	-814(ra) # 800030ce <bread>
    80003404:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003406:	004b2503          	lw	a0,4(s6)
    8000340a:	000a849b          	sext.w	s1,s5
    8000340e:	8662                	mv	a2,s8
    80003410:	faa4fde3          	bgeu	s1,a0,800033ca <balloc+0x3a>
      m = 1 << (bi % 8);
    80003414:	41f6579b          	sraiw	a5,a2,0x1f
    80003418:	01d7d69b          	srliw	a3,a5,0x1d
    8000341c:	00c6873b          	addw	a4,a3,a2
    80003420:	00777793          	andi	a5,a4,7
    80003424:	9f95                	subw	a5,a5,a3
    80003426:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000342a:	4037571b          	sraiw	a4,a4,0x3
    8000342e:	00e906b3          	add	a3,s2,a4
    80003432:	0586c683          	lbu	a3,88(a3)
    80003436:	00d7f5b3          	and	a1,a5,a3
    8000343a:	cd91                	beqz	a1,80003456 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000343c:	2605                	addiw	a2,a2,1
    8000343e:	2485                	addiw	s1,s1,1
    80003440:	fd4618e3          	bne	a2,s4,80003410 <balloc+0x80>
    80003444:	b759                	j	800033ca <balloc+0x3a>
  panic("balloc: out of blocks");
    80003446:	00005517          	auipc	a0,0x5
    8000344a:	0ea50513          	addi	a0,a0,234 # 80008530 <syscalls+0x100>
    8000344e:	ffffd097          	auipc	ra,0xffffd
    80003452:	0f4080e7          	jalr	244(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003456:	974a                	add	a4,a4,s2
    80003458:	8fd5                	or	a5,a5,a3
    8000345a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000345e:	854a                	mv	a0,s2
    80003460:	00001097          	auipc	ra,0x1
    80003464:	006080e7          	jalr	6(ra) # 80004466 <log_write>
        brelse(bp);
    80003468:	854a                	mv	a0,s2
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	d94080e7          	jalr	-620(ra) # 800031fe <brelse>
  bp = bread(dev, bno);
    80003472:	85a6                	mv	a1,s1
    80003474:	855e                	mv	a0,s7
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	c58080e7          	jalr	-936(ra) # 800030ce <bread>
    8000347e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003480:	40000613          	li	a2,1024
    80003484:	4581                	li	a1,0
    80003486:	05850513          	addi	a0,a0,88
    8000348a:	ffffe097          	auipc	ra,0xffffe
    8000348e:	9bc080e7          	jalr	-1604(ra) # 80000e46 <memset>
  log_write(bp);
    80003492:	854a                	mv	a0,s2
    80003494:	00001097          	auipc	ra,0x1
    80003498:	fd2080e7          	jalr	-46(ra) # 80004466 <log_write>
  brelse(bp);
    8000349c:	854a                	mv	a0,s2
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	d60080e7          	jalr	-672(ra) # 800031fe <brelse>
}
    800034a6:	8526                	mv	a0,s1
    800034a8:	60e6                	ld	ra,88(sp)
    800034aa:	6446                	ld	s0,80(sp)
    800034ac:	64a6                	ld	s1,72(sp)
    800034ae:	6906                	ld	s2,64(sp)
    800034b0:	79e2                	ld	s3,56(sp)
    800034b2:	7a42                	ld	s4,48(sp)
    800034b4:	7aa2                	ld	s5,40(sp)
    800034b6:	7b02                	ld	s6,32(sp)
    800034b8:	6be2                	ld	s7,24(sp)
    800034ba:	6c42                	ld	s8,16(sp)
    800034bc:	6ca2                	ld	s9,8(sp)
    800034be:	6125                	addi	sp,sp,96
    800034c0:	8082                	ret

00000000800034c2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034c2:	7179                	addi	sp,sp,-48
    800034c4:	f406                	sd	ra,40(sp)
    800034c6:	f022                	sd	s0,32(sp)
    800034c8:	ec26                	sd	s1,24(sp)
    800034ca:	e84a                	sd	s2,16(sp)
    800034cc:	e44e                	sd	s3,8(sp)
    800034ce:	e052                	sd	s4,0(sp)
    800034d0:	1800                	addi	s0,sp,48
    800034d2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034d4:	47ad                	li	a5,11
    800034d6:	04b7fe63          	bgeu	a5,a1,80003532 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034da:	ff45849b          	addiw	s1,a1,-12
    800034de:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034e2:	0ff00793          	li	a5,255
    800034e6:	0ae7e363          	bltu	a5,a4,8000358c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034ea:	08052583          	lw	a1,128(a0)
    800034ee:	c5ad                	beqz	a1,80003558 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034f0:	00092503          	lw	a0,0(s2)
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	bda080e7          	jalr	-1062(ra) # 800030ce <bread>
    800034fc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034fe:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003502:	02049593          	slli	a1,s1,0x20
    80003506:	9181                	srli	a1,a1,0x20
    80003508:	058a                	slli	a1,a1,0x2
    8000350a:	00b784b3          	add	s1,a5,a1
    8000350e:	0004a983          	lw	s3,0(s1)
    80003512:	04098d63          	beqz	s3,8000356c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003516:	8552                	mv	a0,s4
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	ce6080e7          	jalr	-794(ra) # 800031fe <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003520:	854e                	mv	a0,s3
    80003522:	70a2                	ld	ra,40(sp)
    80003524:	7402                	ld	s0,32(sp)
    80003526:	64e2                	ld	s1,24(sp)
    80003528:	6942                	ld	s2,16(sp)
    8000352a:	69a2                	ld	s3,8(sp)
    8000352c:	6a02                	ld	s4,0(sp)
    8000352e:	6145                	addi	sp,sp,48
    80003530:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003532:	02059493          	slli	s1,a1,0x20
    80003536:	9081                	srli	s1,s1,0x20
    80003538:	048a                	slli	s1,s1,0x2
    8000353a:	94aa                	add	s1,s1,a0
    8000353c:	0504a983          	lw	s3,80(s1)
    80003540:	fe0990e3          	bnez	s3,80003520 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003544:	4108                	lw	a0,0(a0)
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	e4a080e7          	jalr	-438(ra) # 80003390 <balloc>
    8000354e:	0005099b          	sext.w	s3,a0
    80003552:	0534a823          	sw	s3,80(s1)
    80003556:	b7e9                	j	80003520 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003558:	4108                	lw	a0,0(a0)
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	e36080e7          	jalr	-458(ra) # 80003390 <balloc>
    80003562:	0005059b          	sext.w	a1,a0
    80003566:	08b92023          	sw	a1,128(s2)
    8000356a:	b759                	j	800034f0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000356c:	00092503          	lw	a0,0(s2)
    80003570:	00000097          	auipc	ra,0x0
    80003574:	e20080e7          	jalr	-480(ra) # 80003390 <balloc>
    80003578:	0005099b          	sext.w	s3,a0
    8000357c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003580:	8552                	mv	a0,s4
    80003582:	00001097          	auipc	ra,0x1
    80003586:	ee4080e7          	jalr	-284(ra) # 80004466 <log_write>
    8000358a:	b771                	j	80003516 <bmap+0x54>
  panic("bmap: out of range");
    8000358c:	00005517          	auipc	a0,0x5
    80003590:	fbc50513          	addi	a0,a0,-68 # 80008548 <syscalls+0x118>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	fae080e7          	jalr	-82(ra) # 80000542 <panic>

000000008000359c <iget>:
{
    8000359c:	7179                	addi	sp,sp,-48
    8000359e:	f406                	sd	ra,40(sp)
    800035a0:	f022                	sd	s0,32(sp)
    800035a2:	ec26                	sd	s1,24(sp)
    800035a4:	e84a                	sd	s2,16(sp)
    800035a6:	e44e                	sd	s3,8(sp)
    800035a8:	e052                	sd	s4,0(sp)
    800035aa:	1800                	addi	s0,sp,48
    800035ac:	89aa                	mv	s3,a0
    800035ae:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035b0:	0023d517          	auipc	a0,0x23d
    800035b4:	8c850513          	addi	a0,a0,-1848 # 8023fe78 <icache>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	792080e7          	jalr	1938(ra) # 80000d4a <acquire>
  empty = 0;
    800035c0:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035c2:	0023d497          	auipc	s1,0x23d
    800035c6:	8ce48493          	addi	s1,s1,-1842 # 8023fe90 <icache+0x18>
    800035ca:	0023e697          	auipc	a3,0x23e
    800035ce:	35668693          	addi	a3,a3,854 # 80241920 <log>
    800035d2:	a039                	j	800035e0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d4:	02090b63          	beqz	s2,8000360a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035d8:	08848493          	addi	s1,s1,136
    800035dc:	02d48a63          	beq	s1,a3,80003610 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035e0:	449c                	lw	a5,8(s1)
    800035e2:	fef059e3          	blez	a5,800035d4 <iget+0x38>
    800035e6:	4098                	lw	a4,0(s1)
    800035e8:	ff3716e3          	bne	a4,s3,800035d4 <iget+0x38>
    800035ec:	40d8                	lw	a4,4(s1)
    800035ee:	ff4713e3          	bne	a4,s4,800035d4 <iget+0x38>
      ip->ref++;
    800035f2:	2785                	addiw	a5,a5,1
    800035f4:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800035f6:	0023d517          	auipc	a0,0x23d
    800035fa:	88250513          	addi	a0,a0,-1918 # 8023fe78 <icache>
    800035fe:	ffffe097          	auipc	ra,0xffffe
    80003602:	800080e7          	jalr	-2048(ra) # 80000dfe <release>
      return ip;
    80003606:	8926                	mv	s2,s1
    80003608:	a03d                	j	80003636 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000360a:	f7f9                	bnez	a5,800035d8 <iget+0x3c>
    8000360c:	8926                	mv	s2,s1
    8000360e:	b7e9                	j	800035d8 <iget+0x3c>
  if(empty == 0)
    80003610:	02090c63          	beqz	s2,80003648 <iget+0xac>
  ip->dev = dev;
    80003614:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003618:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000361c:	4785                	li	a5,1
    8000361e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003622:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003626:	0023d517          	auipc	a0,0x23d
    8000362a:	85250513          	addi	a0,a0,-1966 # 8023fe78 <icache>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	7d0080e7          	jalr	2000(ra) # 80000dfe <release>
}
    80003636:	854a                	mv	a0,s2
    80003638:	70a2                	ld	ra,40(sp)
    8000363a:	7402                	ld	s0,32(sp)
    8000363c:	64e2                	ld	s1,24(sp)
    8000363e:	6942                	ld	s2,16(sp)
    80003640:	69a2                	ld	s3,8(sp)
    80003642:	6a02                	ld	s4,0(sp)
    80003644:	6145                	addi	sp,sp,48
    80003646:	8082                	ret
    panic("iget: no inodes");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	f1850513          	addi	a0,a0,-232 # 80008560 <syscalls+0x130>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	ef2080e7          	jalr	-270(ra) # 80000542 <panic>

0000000080003658 <fsinit>:
fsinit(int dev) {
    80003658:	7179                	addi	sp,sp,-48
    8000365a:	f406                	sd	ra,40(sp)
    8000365c:	f022                	sd	s0,32(sp)
    8000365e:	ec26                	sd	s1,24(sp)
    80003660:	e84a                	sd	s2,16(sp)
    80003662:	e44e                	sd	s3,8(sp)
    80003664:	1800                	addi	s0,sp,48
    80003666:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003668:	4585                	li	a1,1
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	a64080e7          	jalr	-1436(ra) # 800030ce <bread>
    80003672:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003674:	0023c997          	auipc	s3,0x23c
    80003678:	7e498993          	addi	s3,s3,2020 # 8023fe58 <sb>
    8000367c:	02000613          	li	a2,32
    80003680:	05850593          	addi	a1,a0,88
    80003684:	854e                	mv	a0,s3
    80003686:	ffffe097          	auipc	ra,0xffffe
    8000368a:	81c080e7          	jalr	-2020(ra) # 80000ea2 <memmove>
  brelse(bp);
    8000368e:	8526                	mv	a0,s1
    80003690:	00000097          	auipc	ra,0x0
    80003694:	b6e080e7          	jalr	-1170(ra) # 800031fe <brelse>
  if(sb.magic != FSMAGIC)
    80003698:	0009a703          	lw	a4,0(s3)
    8000369c:	102037b7          	lui	a5,0x10203
    800036a0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036a4:	02f71263          	bne	a4,a5,800036c8 <fsinit+0x70>
  initlog(dev, &sb);
    800036a8:	0023c597          	auipc	a1,0x23c
    800036ac:	7b058593          	addi	a1,a1,1968 # 8023fe58 <sb>
    800036b0:	854a                	mv	a0,s2
    800036b2:	00001097          	auipc	ra,0x1
    800036b6:	b3c080e7          	jalr	-1220(ra) # 800041ee <initlog>
}
    800036ba:	70a2                	ld	ra,40(sp)
    800036bc:	7402                	ld	s0,32(sp)
    800036be:	64e2                	ld	s1,24(sp)
    800036c0:	6942                	ld	s2,16(sp)
    800036c2:	69a2                	ld	s3,8(sp)
    800036c4:	6145                	addi	sp,sp,48
    800036c6:	8082                	ret
    panic("invalid file system");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	ea850513          	addi	a0,a0,-344 # 80008570 <syscalls+0x140>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	e72080e7          	jalr	-398(ra) # 80000542 <panic>

00000000800036d8 <iinit>:
{
    800036d8:	7179                	addi	sp,sp,-48
    800036da:	f406                	sd	ra,40(sp)
    800036dc:	f022                	sd	s0,32(sp)
    800036de:	ec26                	sd	s1,24(sp)
    800036e0:	e84a                	sd	s2,16(sp)
    800036e2:	e44e                	sd	s3,8(sp)
    800036e4:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800036e6:	00005597          	auipc	a1,0x5
    800036ea:	ea258593          	addi	a1,a1,-350 # 80008588 <syscalls+0x158>
    800036ee:	0023c517          	auipc	a0,0x23c
    800036f2:	78a50513          	addi	a0,a0,1930 # 8023fe78 <icache>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	5c4080e7          	jalr	1476(ra) # 80000cba <initlock>
  for(i = 0; i < NINODE; i++) {
    800036fe:	0023c497          	auipc	s1,0x23c
    80003702:	7a248493          	addi	s1,s1,1954 # 8023fea0 <icache+0x28>
    80003706:	0023e997          	auipc	s3,0x23e
    8000370a:	22a98993          	addi	s3,s3,554 # 80241930 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000370e:	00005917          	auipc	s2,0x5
    80003712:	e8290913          	addi	s2,s2,-382 # 80008590 <syscalls+0x160>
    80003716:	85ca                	mv	a1,s2
    80003718:	8526                	mv	a0,s1
    8000371a:	00001097          	auipc	ra,0x1
    8000371e:	e3a080e7          	jalr	-454(ra) # 80004554 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003722:	08848493          	addi	s1,s1,136
    80003726:	ff3498e3          	bne	s1,s3,80003716 <iinit+0x3e>
}
    8000372a:	70a2                	ld	ra,40(sp)
    8000372c:	7402                	ld	s0,32(sp)
    8000372e:	64e2                	ld	s1,24(sp)
    80003730:	6942                	ld	s2,16(sp)
    80003732:	69a2                	ld	s3,8(sp)
    80003734:	6145                	addi	sp,sp,48
    80003736:	8082                	ret

0000000080003738 <ialloc>:
{
    80003738:	715d                	addi	sp,sp,-80
    8000373a:	e486                	sd	ra,72(sp)
    8000373c:	e0a2                	sd	s0,64(sp)
    8000373e:	fc26                	sd	s1,56(sp)
    80003740:	f84a                	sd	s2,48(sp)
    80003742:	f44e                	sd	s3,40(sp)
    80003744:	f052                	sd	s4,32(sp)
    80003746:	ec56                	sd	s5,24(sp)
    80003748:	e85a                	sd	s6,16(sp)
    8000374a:	e45e                	sd	s7,8(sp)
    8000374c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000374e:	0023c717          	auipc	a4,0x23c
    80003752:	71672703          	lw	a4,1814(a4) # 8023fe64 <sb+0xc>
    80003756:	4785                	li	a5,1
    80003758:	04e7fa63          	bgeu	a5,a4,800037ac <ialloc+0x74>
    8000375c:	8aaa                	mv	s5,a0
    8000375e:	8bae                	mv	s7,a1
    80003760:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003762:	0023ca17          	auipc	s4,0x23c
    80003766:	6f6a0a13          	addi	s4,s4,1782 # 8023fe58 <sb>
    8000376a:	00048b1b          	sext.w	s6,s1
    8000376e:	0044d793          	srli	a5,s1,0x4
    80003772:	018a2583          	lw	a1,24(s4)
    80003776:	9dbd                	addw	a1,a1,a5
    80003778:	8556                	mv	a0,s5
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	954080e7          	jalr	-1708(ra) # 800030ce <bread>
    80003782:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003784:	05850993          	addi	s3,a0,88
    80003788:	00f4f793          	andi	a5,s1,15
    8000378c:	079a                	slli	a5,a5,0x6
    8000378e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003790:	00099783          	lh	a5,0(s3)
    80003794:	c785                	beqz	a5,800037bc <ialloc+0x84>
    brelse(bp);
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	a68080e7          	jalr	-1432(ra) # 800031fe <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000379e:	0485                	addi	s1,s1,1
    800037a0:	00ca2703          	lw	a4,12(s4)
    800037a4:	0004879b          	sext.w	a5,s1
    800037a8:	fce7e1e3          	bltu	a5,a4,8000376a <ialloc+0x32>
  panic("ialloc: no inodes");
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	dec50513          	addi	a0,a0,-532 # 80008598 <syscalls+0x168>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	d8e080e7          	jalr	-626(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800037bc:	04000613          	li	a2,64
    800037c0:	4581                	li	a1,0
    800037c2:	854e                	mv	a0,s3
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	682080e7          	jalr	1666(ra) # 80000e46 <memset>
      dip->type = type;
    800037cc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037d0:	854a                	mv	a0,s2
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	c94080e7          	jalr	-876(ra) # 80004466 <log_write>
      brelse(bp);
    800037da:	854a                	mv	a0,s2
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	a22080e7          	jalr	-1502(ra) # 800031fe <brelse>
      return iget(dev, inum);
    800037e4:	85da                	mv	a1,s6
    800037e6:	8556                	mv	a0,s5
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	db4080e7          	jalr	-588(ra) # 8000359c <iget>
}
    800037f0:	60a6                	ld	ra,72(sp)
    800037f2:	6406                	ld	s0,64(sp)
    800037f4:	74e2                	ld	s1,56(sp)
    800037f6:	7942                	ld	s2,48(sp)
    800037f8:	79a2                	ld	s3,40(sp)
    800037fa:	7a02                	ld	s4,32(sp)
    800037fc:	6ae2                	ld	s5,24(sp)
    800037fe:	6b42                	ld	s6,16(sp)
    80003800:	6ba2                	ld	s7,8(sp)
    80003802:	6161                	addi	sp,sp,80
    80003804:	8082                	ret

0000000080003806 <iupdate>:
{
    80003806:	1101                	addi	sp,sp,-32
    80003808:	ec06                	sd	ra,24(sp)
    8000380a:	e822                	sd	s0,16(sp)
    8000380c:	e426                	sd	s1,8(sp)
    8000380e:	e04a                	sd	s2,0(sp)
    80003810:	1000                	addi	s0,sp,32
    80003812:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003814:	415c                	lw	a5,4(a0)
    80003816:	0047d79b          	srliw	a5,a5,0x4
    8000381a:	0023c597          	auipc	a1,0x23c
    8000381e:	6565a583          	lw	a1,1622(a1) # 8023fe70 <sb+0x18>
    80003822:	9dbd                	addw	a1,a1,a5
    80003824:	4108                	lw	a0,0(a0)
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	8a8080e7          	jalr	-1880(ra) # 800030ce <bread>
    8000382e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003830:	05850793          	addi	a5,a0,88
    80003834:	40c8                	lw	a0,4(s1)
    80003836:	893d                	andi	a0,a0,15
    80003838:	051a                	slli	a0,a0,0x6
    8000383a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000383c:	04449703          	lh	a4,68(s1)
    80003840:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003844:	04649703          	lh	a4,70(s1)
    80003848:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000384c:	04849703          	lh	a4,72(s1)
    80003850:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003854:	04a49703          	lh	a4,74(s1)
    80003858:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000385c:	44f8                	lw	a4,76(s1)
    8000385e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003860:	03400613          	li	a2,52
    80003864:	05048593          	addi	a1,s1,80
    80003868:	0531                	addi	a0,a0,12
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	638080e7          	jalr	1592(ra) # 80000ea2 <memmove>
  log_write(bp);
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	bf2080e7          	jalr	-1038(ra) # 80004466 <log_write>
  brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	980080e7          	jalr	-1664(ra) # 800031fe <brelse>
}
    80003886:	60e2                	ld	ra,24(sp)
    80003888:	6442                	ld	s0,16(sp)
    8000388a:	64a2                	ld	s1,8(sp)
    8000388c:	6902                	ld	s2,0(sp)
    8000388e:	6105                	addi	sp,sp,32
    80003890:	8082                	ret

0000000080003892 <idup>:
{
    80003892:	1101                	addi	sp,sp,-32
    80003894:	ec06                	sd	ra,24(sp)
    80003896:	e822                	sd	s0,16(sp)
    80003898:	e426                	sd	s1,8(sp)
    8000389a:	1000                	addi	s0,sp,32
    8000389c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000389e:	0023c517          	auipc	a0,0x23c
    800038a2:	5da50513          	addi	a0,a0,1498 # 8023fe78 <icache>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	4a4080e7          	jalr	1188(ra) # 80000d4a <acquire>
  ip->ref++;
    800038ae:	449c                	lw	a5,8(s1)
    800038b0:	2785                	addiw	a5,a5,1
    800038b2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038b4:	0023c517          	auipc	a0,0x23c
    800038b8:	5c450513          	addi	a0,a0,1476 # 8023fe78 <icache>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	542080e7          	jalr	1346(ra) # 80000dfe <release>
}
    800038c4:	8526                	mv	a0,s1
    800038c6:	60e2                	ld	ra,24(sp)
    800038c8:	6442                	ld	s0,16(sp)
    800038ca:	64a2                	ld	s1,8(sp)
    800038cc:	6105                	addi	sp,sp,32
    800038ce:	8082                	ret

00000000800038d0 <ilock>:
{
    800038d0:	1101                	addi	sp,sp,-32
    800038d2:	ec06                	sd	ra,24(sp)
    800038d4:	e822                	sd	s0,16(sp)
    800038d6:	e426                	sd	s1,8(sp)
    800038d8:	e04a                	sd	s2,0(sp)
    800038da:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038dc:	c115                	beqz	a0,80003900 <ilock+0x30>
    800038de:	84aa                	mv	s1,a0
    800038e0:	451c                	lw	a5,8(a0)
    800038e2:	00f05f63          	blez	a5,80003900 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038e6:	0541                	addi	a0,a0,16
    800038e8:	00001097          	auipc	ra,0x1
    800038ec:	ca6080e7          	jalr	-858(ra) # 8000458e <acquiresleep>
  if(ip->valid == 0){
    800038f0:	40bc                	lw	a5,64(s1)
    800038f2:	cf99                	beqz	a5,80003910 <ilock+0x40>
}
    800038f4:	60e2                	ld	ra,24(sp)
    800038f6:	6442                	ld	s0,16(sp)
    800038f8:	64a2                	ld	s1,8(sp)
    800038fa:	6902                	ld	s2,0(sp)
    800038fc:	6105                	addi	sp,sp,32
    800038fe:	8082                	ret
    panic("ilock");
    80003900:	00005517          	auipc	a0,0x5
    80003904:	cb050513          	addi	a0,a0,-848 # 800085b0 <syscalls+0x180>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	c3a080e7          	jalr	-966(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003910:	40dc                	lw	a5,4(s1)
    80003912:	0047d79b          	srliw	a5,a5,0x4
    80003916:	0023c597          	auipc	a1,0x23c
    8000391a:	55a5a583          	lw	a1,1370(a1) # 8023fe70 <sb+0x18>
    8000391e:	9dbd                	addw	a1,a1,a5
    80003920:	4088                	lw	a0,0(s1)
    80003922:	fffff097          	auipc	ra,0xfffff
    80003926:	7ac080e7          	jalr	1964(ra) # 800030ce <bread>
    8000392a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000392c:	05850593          	addi	a1,a0,88
    80003930:	40dc                	lw	a5,4(s1)
    80003932:	8bbd                	andi	a5,a5,15
    80003934:	079a                	slli	a5,a5,0x6
    80003936:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003938:	00059783          	lh	a5,0(a1)
    8000393c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003940:	00259783          	lh	a5,2(a1)
    80003944:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003948:	00459783          	lh	a5,4(a1)
    8000394c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003950:	00659783          	lh	a5,6(a1)
    80003954:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003958:	459c                	lw	a5,8(a1)
    8000395a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000395c:	03400613          	li	a2,52
    80003960:	05b1                	addi	a1,a1,12
    80003962:	05048513          	addi	a0,s1,80
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	53c080e7          	jalr	1340(ra) # 80000ea2 <memmove>
    brelse(bp);
    8000396e:	854a                	mv	a0,s2
    80003970:	00000097          	auipc	ra,0x0
    80003974:	88e080e7          	jalr	-1906(ra) # 800031fe <brelse>
    ip->valid = 1;
    80003978:	4785                	li	a5,1
    8000397a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000397c:	04449783          	lh	a5,68(s1)
    80003980:	fbb5                	bnez	a5,800038f4 <ilock+0x24>
      panic("ilock: no type");
    80003982:	00005517          	auipc	a0,0x5
    80003986:	c3650513          	addi	a0,a0,-970 # 800085b8 <syscalls+0x188>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	bb8080e7          	jalr	-1096(ra) # 80000542 <panic>

0000000080003992 <iunlock>:
{
    80003992:	1101                	addi	sp,sp,-32
    80003994:	ec06                	sd	ra,24(sp)
    80003996:	e822                	sd	s0,16(sp)
    80003998:	e426                	sd	s1,8(sp)
    8000399a:	e04a                	sd	s2,0(sp)
    8000399c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000399e:	c905                	beqz	a0,800039ce <iunlock+0x3c>
    800039a0:	84aa                	mv	s1,a0
    800039a2:	01050913          	addi	s2,a0,16
    800039a6:	854a                	mv	a0,s2
    800039a8:	00001097          	auipc	ra,0x1
    800039ac:	c80080e7          	jalr	-896(ra) # 80004628 <holdingsleep>
    800039b0:	cd19                	beqz	a0,800039ce <iunlock+0x3c>
    800039b2:	449c                	lw	a5,8(s1)
    800039b4:	00f05d63          	blez	a5,800039ce <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039b8:	854a                	mv	a0,s2
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	c2a080e7          	jalr	-982(ra) # 800045e4 <releasesleep>
}
    800039c2:	60e2                	ld	ra,24(sp)
    800039c4:	6442                	ld	s0,16(sp)
    800039c6:	64a2                	ld	s1,8(sp)
    800039c8:	6902                	ld	s2,0(sp)
    800039ca:	6105                	addi	sp,sp,32
    800039cc:	8082                	ret
    panic("iunlock");
    800039ce:	00005517          	auipc	a0,0x5
    800039d2:	bfa50513          	addi	a0,a0,-1030 # 800085c8 <syscalls+0x198>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	b6c080e7          	jalr	-1172(ra) # 80000542 <panic>

00000000800039de <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039de:	7179                	addi	sp,sp,-48
    800039e0:	f406                	sd	ra,40(sp)
    800039e2:	f022                	sd	s0,32(sp)
    800039e4:	ec26                	sd	s1,24(sp)
    800039e6:	e84a                	sd	s2,16(sp)
    800039e8:	e44e                	sd	s3,8(sp)
    800039ea:	e052                	sd	s4,0(sp)
    800039ec:	1800                	addi	s0,sp,48
    800039ee:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039f0:	05050493          	addi	s1,a0,80
    800039f4:	08050913          	addi	s2,a0,128
    800039f8:	a021                	j	80003a00 <itrunc+0x22>
    800039fa:	0491                	addi	s1,s1,4
    800039fc:	01248d63          	beq	s1,s2,80003a16 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a00:	408c                	lw	a1,0(s1)
    80003a02:	dde5                	beqz	a1,800039fa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a04:	0009a503          	lw	a0,0(s3)
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	90c080e7          	jalr	-1780(ra) # 80003314 <bfree>
      ip->addrs[i] = 0;
    80003a10:	0004a023          	sw	zero,0(s1)
    80003a14:	b7dd                	j	800039fa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a16:	0809a583          	lw	a1,128(s3)
    80003a1a:	e185                	bnez	a1,80003a3a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a1c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a20:	854e                	mv	a0,s3
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	de4080e7          	jalr	-540(ra) # 80003806 <iupdate>
}
    80003a2a:	70a2                	ld	ra,40(sp)
    80003a2c:	7402                	ld	s0,32(sp)
    80003a2e:	64e2                	ld	s1,24(sp)
    80003a30:	6942                	ld	s2,16(sp)
    80003a32:	69a2                	ld	s3,8(sp)
    80003a34:	6a02                	ld	s4,0(sp)
    80003a36:	6145                	addi	sp,sp,48
    80003a38:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a3a:	0009a503          	lw	a0,0(s3)
    80003a3e:	fffff097          	auipc	ra,0xfffff
    80003a42:	690080e7          	jalr	1680(ra) # 800030ce <bread>
    80003a46:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a48:	05850493          	addi	s1,a0,88
    80003a4c:	45850913          	addi	s2,a0,1112
    80003a50:	a021                	j	80003a58 <itrunc+0x7a>
    80003a52:	0491                	addi	s1,s1,4
    80003a54:	01248b63          	beq	s1,s2,80003a6a <itrunc+0x8c>
      if(a[j])
    80003a58:	408c                	lw	a1,0(s1)
    80003a5a:	dde5                	beqz	a1,80003a52 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a5c:	0009a503          	lw	a0,0(s3)
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	8b4080e7          	jalr	-1868(ra) # 80003314 <bfree>
    80003a68:	b7ed                	j	80003a52 <itrunc+0x74>
    brelse(bp);
    80003a6a:	8552                	mv	a0,s4
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	792080e7          	jalr	1938(ra) # 800031fe <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a74:	0809a583          	lw	a1,128(s3)
    80003a78:	0009a503          	lw	a0,0(s3)
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	898080e7          	jalr	-1896(ra) # 80003314 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a84:	0809a023          	sw	zero,128(s3)
    80003a88:	bf51                	j	80003a1c <itrunc+0x3e>

0000000080003a8a <iput>:
{
    80003a8a:	1101                	addi	sp,sp,-32
    80003a8c:	ec06                	sd	ra,24(sp)
    80003a8e:	e822                	sd	s0,16(sp)
    80003a90:	e426                	sd	s1,8(sp)
    80003a92:	e04a                	sd	s2,0(sp)
    80003a94:	1000                	addi	s0,sp,32
    80003a96:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a98:	0023c517          	auipc	a0,0x23c
    80003a9c:	3e050513          	addi	a0,a0,992 # 8023fe78 <icache>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	2aa080e7          	jalr	682(ra) # 80000d4a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aa8:	4498                	lw	a4,8(s1)
    80003aaa:	4785                	li	a5,1
    80003aac:	02f70363          	beq	a4,a5,80003ad2 <iput+0x48>
  ip->ref--;
    80003ab0:	449c                	lw	a5,8(s1)
    80003ab2:	37fd                	addiw	a5,a5,-1
    80003ab4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ab6:	0023c517          	auipc	a0,0x23c
    80003aba:	3c250513          	addi	a0,a0,962 # 8023fe78 <icache>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	340080e7          	jalr	832(ra) # 80000dfe <release>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6902                	ld	s2,0(sp)
    80003ace:	6105                	addi	sp,sp,32
    80003ad0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad2:	40bc                	lw	a5,64(s1)
    80003ad4:	dff1                	beqz	a5,80003ab0 <iput+0x26>
    80003ad6:	04a49783          	lh	a5,74(s1)
    80003ada:	fbf9                	bnez	a5,80003ab0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003adc:	01048913          	addi	s2,s1,16
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00001097          	auipc	ra,0x1
    80003ae6:	aac080e7          	jalr	-1364(ra) # 8000458e <acquiresleep>
    release(&icache.lock);
    80003aea:	0023c517          	auipc	a0,0x23c
    80003aee:	38e50513          	addi	a0,a0,910 # 8023fe78 <icache>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	30c080e7          	jalr	780(ra) # 80000dfe <release>
    itrunc(ip);
    80003afa:	8526                	mv	a0,s1
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	ee2080e7          	jalr	-286(ra) # 800039de <itrunc>
    ip->type = 0;
    80003b04:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	cfc080e7          	jalr	-772(ra) # 80003806 <iupdate>
    ip->valid = 0;
    80003b12:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b16:	854a                	mv	a0,s2
    80003b18:	00001097          	auipc	ra,0x1
    80003b1c:	acc080e7          	jalr	-1332(ra) # 800045e4 <releasesleep>
    acquire(&icache.lock);
    80003b20:	0023c517          	auipc	a0,0x23c
    80003b24:	35850513          	addi	a0,a0,856 # 8023fe78 <icache>
    80003b28:	ffffd097          	auipc	ra,0xffffd
    80003b2c:	222080e7          	jalr	546(ra) # 80000d4a <acquire>
    80003b30:	b741                	j	80003ab0 <iput+0x26>

0000000080003b32 <iunlockput>:
{
    80003b32:	1101                	addi	sp,sp,-32
    80003b34:	ec06                	sd	ra,24(sp)
    80003b36:	e822                	sd	s0,16(sp)
    80003b38:	e426                	sd	s1,8(sp)
    80003b3a:	1000                	addi	s0,sp,32
    80003b3c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	e54080e7          	jalr	-428(ra) # 80003992 <iunlock>
  iput(ip);
    80003b46:	8526                	mv	a0,s1
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	f42080e7          	jalr	-190(ra) # 80003a8a <iput>
}
    80003b50:	60e2                	ld	ra,24(sp)
    80003b52:	6442                	ld	s0,16(sp)
    80003b54:	64a2                	ld	s1,8(sp)
    80003b56:	6105                	addi	sp,sp,32
    80003b58:	8082                	ret

0000000080003b5a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b5a:	1141                	addi	sp,sp,-16
    80003b5c:	e422                	sd	s0,8(sp)
    80003b5e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b60:	411c                	lw	a5,0(a0)
    80003b62:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b64:	415c                	lw	a5,4(a0)
    80003b66:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b68:	04451783          	lh	a5,68(a0)
    80003b6c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b70:	04a51783          	lh	a5,74(a0)
    80003b74:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b78:	04c56783          	lwu	a5,76(a0)
    80003b7c:	e99c                	sd	a5,16(a1)
}
    80003b7e:	6422                	ld	s0,8(sp)
    80003b80:	0141                	addi	sp,sp,16
    80003b82:	8082                	ret

0000000080003b84 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b84:	457c                	lw	a5,76(a0)
    80003b86:	0ed7e963          	bltu	a5,a3,80003c78 <readi+0xf4>
{
    80003b8a:	7159                	addi	sp,sp,-112
    80003b8c:	f486                	sd	ra,104(sp)
    80003b8e:	f0a2                	sd	s0,96(sp)
    80003b90:	eca6                	sd	s1,88(sp)
    80003b92:	e8ca                	sd	s2,80(sp)
    80003b94:	e4ce                	sd	s3,72(sp)
    80003b96:	e0d2                	sd	s4,64(sp)
    80003b98:	fc56                	sd	s5,56(sp)
    80003b9a:	f85a                	sd	s6,48(sp)
    80003b9c:	f45e                	sd	s7,40(sp)
    80003b9e:	f062                	sd	s8,32(sp)
    80003ba0:	ec66                	sd	s9,24(sp)
    80003ba2:	e86a                	sd	s10,16(sp)
    80003ba4:	e46e                	sd	s11,8(sp)
    80003ba6:	1880                	addi	s0,sp,112
    80003ba8:	8baa                	mv	s7,a0
    80003baa:	8c2e                	mv	s8,a1
    80003bac:	8ab2                	mv	s5,a2
    80003bae:	84b6                	mv	s1,a3
    80003bb0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bb2:	9f35                	addw	a4,a4,a3
    return 0;
    80003bb4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bb6:	0ad76063          	bltu	a4,a3,80003c56 <readi+0xd2>
  if(off + n > ip->size)
    80003bba:	00e7f463          	bgeu	a5,a4,80003bc2 <readi+0x3e>
    n = ip->size - off;
    80003bbe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc2:	0a0b0963          	beqz	s6,80003c74 <readi+0xf0>
    80003bc6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bcc:	5cfd                	li	s9,-1
    80003bce:	a82d                	j	80003c08 <readi+0x84>
    80003bd0:	020a1d93          	slli	s11,s4,0x20
    80003bd4:	020ddd93          	srli	s11,s11,0x20
    80003bd8:	05890793          	addi	a5,s2,88
    80003bdc:	86ee                	mv	a3,s11
    80003bde:	963e                	add	a2,a2,a5
    80003be0:	85d6                	mv	a1,s5
    80003be2:	8562                	mv	a0,s8
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	ae6080e7          	jalr	-1306(ra) # 800026ca <either_copyout>
    80003bec:	05950d63          	beq	a0,s9,80003c46 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bf0:	854a                	mv	a0,s2
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	60c080e7          	jalr	1548(ra) # 800031fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bfa:	013a09bb          	addw	s3,s4,s3
    80003bfe:	009a04bb          	addw	s1,s4,s1
    80003c02:	9aee                	add	s5,s5,s11
    80003c04:	0569f763          	bgeu	s3,s6,80003c52 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c08:	000ba903          	lw	s2,0(s7)
    80003c0c:	00a4d59b          	srliw	a1,s1,0xa
    80003c10:	855e                	mv	a0,s7
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	8b0080e7          	jalr	-1872(ra) # 800034c2 <bmap>
    80003c1a:	0005059b          	sext.w	a1,a0
    80003c1e:	854a                	mv	a0,s2
    80003c20:	fffff097          	auipc	ra,0xfffff
    80003c24:	4ae080e7          	jalr	1198(ra) # 800030ce <bread>
    80003c28:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2a:	3ff4f613          	andi	a2,s1,1023
    80003c2e:	40cd07bb          	subw	a5,s10,a2
    80003c32:	413b073b          	subw	a4,s6,s3
    80003c36:	8a3e                	mv	s4,a5
    80003c38:	2781                	sext.w	a5,a5
    80003c3a:	0007069b          	sext.w	a3,a4
    80003c3e:	f8f6f9e3          	bgeu	a3,a5,80003bd0 <readi+0x4c>
    80003c42:	8a3a                	mv	s4,a4
    80003c44:	b771                	j	80003bd0 <readi+0x4c>
      brelse(bp);
    80003c46:	854a                	mv	a0,s2
    80003c48:	fffff097          	auipc	ra,0xfffff
    80003c4c:	5b6080e7          	jalr	1462(ra) # 800031fe <brelse>
      tot = -1;
    80003c50:	59fd                	li	s3,-1
  }
  return tot;
    80003c52:	0009851b          	sext.w	a0,s3
}
    80003c56:	70a6                	ld	ra,104(sp)
    80003c58:	7406                	ld	s0,96(sp)
    80003c5a:	64e6                	ld	s1,88(sp)
    80003c5c:	6946                	ld	s2,80(sp)
    80003c5e:	69a6                	ld	s3,72(sp)
    80003c60:	6a06                	ld	s4,64(sp)
    80003c62:	7ae2                	ld	s5,56(sp)
    80003c64:	7b42                	ld	s6,48(sp)
    80003c66:	7ba2                	ld	s7,40(sp)
    80003c68:	7c02                	ld	s8,32(sp)
    80003c6a:	6ce2                	ld	s9,24(sp)
    80003c6c:	6d42                	ld	s10,16(sp)
    80003c6e:	6da2                	ld	s11,8(sp)
    80003c70:	6165                	addi	sp,sp,112
    80003c72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c74:	89da                	mv	s3,s6
    80003c76:	bff1                	j	80003c52 <readi+0xce>
    return 0;
    80003c78:	4501                	li	a0,0
}
    80003c7a:	8082                	ret

0000000080003c7c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c7c:	457c                	lw	a5,76(a0)
    80003c7e:	10d7e763          	bltu	a5,a3,80003d8c <writei+0x110>
{
    80003c82:	7159                	addi	sp,sp,-112
    80003c84:	f486                	sd	ra,104(sp)
    80003c86:	f0a2                	sd	s0,96(sp)
    80003c88:	eca6                	sd	s1,88(sp)
    80003c8a:	e8ca                	sd	s2,80(sp)
    80003c8c:	e4ce                	sd	s3,72(sp)
    80003c8e:	e0d2                	sd	s4,64(sp)
    80003c90:	fc56                	sd	s5,56(sp)
    80003c92:	f85a                	sd	s6,48(sp)
    80003c94:	f45e                	sd	s7,40(sp)
    80003c96:	f062                	sd	s8,32(sp)
    80003c98:	ec66                	sd	s9,24(sp)
    80003c9a:	e86a                	sd	s10,16(sp)
    80003c9c:	e46e                	sd	s11,8(sp)
    80003c9e:	1880                	addi	s0,sp,112
    80003ca0:	8baa                	mv	s7,a0
    80003ca2:	8c2e                	mv	s8,a1
    80003ca4:	8ab2                	mv	s5,a2
    80003ca6:	8936                	mv	s2,a3
    80003ca8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003caa:	00e687bb          	addw	a5,a3,a4
    80003cae:	0ed7e163          	bltu	a5,a3,80003d90 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cb2:	00043737          	lui	a4,0x43
    80003cb6:	0cf76f63          	bltu	a4,a5,80003d94 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cba:	0a0b0863          	beqz	s6,80003d6a <writei+0xee>
    80003cbe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cc4:	5cfd                	li	s9,-1
    80003cc6:	a091                	j	80003d0a <writei+0x8e>
    80003cc8:	02099d93          	slli	s11,s3,0x20
    80003ccc:	020ddd93          	srli	s11,s11,0x20
    80003cd0:	05848793          	addi	a5,s1,88
    80003cd4:	86ee                	mv	a3,s11
    80003cd6:	8656                	mv	a2,s5
    80003cd8:	85e2                	mv	a1,s8
    80003cda:	953e                	add	a0,a0,a5
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	a44080e7          	jalr	-1468(ra) # 80002720 <either_copyin>
    80003ce4:	07950263          	beq	a0,s9,80003d48 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003ce8:	8526                	mv	a0,s1
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	77c080e7          	jalr	1916(ra) # 80004466 <log_write>
    brelse(bp);
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	fffff097          	auipc	ra,0xfffff
    80003cf8:	50a080e7          	jalr	1290(ra) # 800031fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cfc:	01498a3b          	addw	s4,s3,s4
    80003d00:	0129893b          	addw	s2,s3,s2
    80003d04:	9aee                	add	s5,s5,s11
    80003d06:	056a7763          	bgeu	s4,s6,80003d54 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d0a:	000ba483          	lw	s1,0(s7)
    80003d0e:	00a9559b          	srliw	a1,s2,0xa
    80003d12:	855e                	mv	a0,s7
    80003d14:	fffff097          	auipc	ra,0xfffff
    80003d18:	7ae080e7          	jalr	1966(ra) # 800034c2 <bmap>
    80003d1c:	0005059b          	sext.w	a1,a0
    80003d20:	8526                	mv	a0,s1
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	3ac080e7          	jalr	940(ra) # 800030ce <bread>
    80003d2a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2c:	3ff97513          	andi	a0,s2,1023
    80003d30:	40ad07bb          	subw	a5,s10,a0
    80003d34:	414b073b          	subw	a4,s6,s4
    80003d38:	89be                	mv	s3,a5
    80003d3a:	2781                	sext.w	a5,a5
    80003d3c:	0007069b          	sext.w	a3,a4
    80003d40:	f8f6f4e3          	bgeu	a3,a5,80003cc8 <writei+0x4c>
    80003d44:	89ba                	mv	s3,a4
    80003d46:	b749                	j	80003cc8 <writei+0x4c>
      brelse(bp);
    80003d48:	8526                	mv	a0,s1
    80003d4a:	fffff097          	auipc	ra,0xfffff
    80003d4e:	4b4080e7          	jalr	1204(ra) # 800031fe <brelse>
      n = -1;
    80003d52:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003d54:	04cba783          	lw	a5,76(s7)
    80003d58:	0127f463          	bgeu	a5,s2,80003d60 <writei+0xe4>
      ip->size = off;
    80003d5c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d60:	855e                	mv	a0,s7
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	aa4080e7          	jalr	-1372(ra) # 80003806 <iupdate>
  }

  return n;
    80003d6a:	000b051b          	sext.w	a0,s6
}
    80003d6e:	70a6                	ld	ra,104(sp)
    80003d70:	7406                	ld	s0,96(sp)
    80003d72:	64e6                	ld	s1,88(sp)
    80003d74:	6946                	ld	s2,80(sp)
    80003d76:	69a6                	ld	s3,72(sp)
    80003d78:	6a06                	ld	s4,64(sp)
    80003d7a:	7ae2                	ld	s5,56(sp)
    80003d7c:	7b42                	ld	s6,48(sp)
    80003d7e:	7ba2                	ld	s7,40(sp)
    80003d80:	7c02                	ld	s8,32(sp)
    80003d82:	6ce2                	ld	s9,24(sp)
    80003d84:	6d42                	ld	s10,16(sp)
    80003d86:	6da2                	ld	s11,8(sp)
    80003d88:	6165                	addi	sp,sp,112
    80003d8a:	8082                	ret
    return -1;
    80003d8c:	557d                	li	a0,-1
}
    80003d8e:	8082                	ret
    return -1;
    80003d90:	557d                	li	a0,-1
    80003d92:	bff1                	j	80003d6e <writei+0xf2>
    return -1;
    80003d94:	557d                	li	a0,-1
    80003d96:	bfe1                	j	80003d6e <writei+0xf2>

0000000080003d98 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d98:	1141                	addi	sp,sp,-16
    80003d9a:	e406                	sd	ra,8(sp)
    80003d9c:	e022                	sd	s0,0(sp)
    80003d9e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003da0:	4639                	li	a2,14
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	17c080e7          	jalr	380(ra) # 80000f1e <strncmp>
}
    80003daa:	60a2                	ld	ra,8(sp)
    80003dac:	6402                	ld	s0,0(sp)
    80003dae:	0141                	addi	sp,sp,16
    80003db0:	8082                	ret

0000000080003db2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003db2:	7139                	addi	sp,sp,-64
    80003db4:	fc06                	sd	ra,56(sp)
    80003db6:	f822                	sd	s0,48(sp)
    80003db8:	f426                	sd	s1,40(sp)
    80003dba:	f04a                	sd	s2,32(sp)
    80003dbc:	ec4e                	sd	s3,24(sp)
    80003dbe:	e852                	sd	s4,16(sp)
    80003dc0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dc2:	04451703          	lh	a4,68(a0)
    80003dc6:	4785                	li	a5,1
    80003dc8:	00f71a63          	bne	a4,a5,80003ddc <dirlookup+0x2a>
    80003dcc:	892a                	mv	s2,a0
    80003dce:	89ae                	mv	s3,a1
    80003dd0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd2:	457c                	lw	a5,76(a0)
    80003dd4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dd6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd8:	e79d                	bnez	a5,80003e06 <dirlookup+0x54>
    80003dda:	a8a5                	j	80003e52 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ddc:	00004517          	auipc	a0,0x4
    80003de0:	7f450513          	addi	a0,a0,2036 # 800085d0 <syscalls+0x1a0>
    80003de4:	ffffc097          	auipc	ra,0xffffc
    80003de8:	75e080e7          	jalr	1886(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003dec:	00004517          	auipc	a0,0x4
    80003df0:	7fc50513          	addi	a0,a0,2044 # 800085e8 <syscalls+0x1b8>
    80003df4:	ffffc097          	auipc	ra,0xffffc
    80003df8:	74e080e7          	jalr	1870(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfc:	24c1                	addiw	s1,s1,16
    80003dfe:	04c92783          	lw	a5,76(s2)
    80003e02:	04f4f763          	bgeu	s1,a5,80003e50 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e06:	4741                	li	a4,16
    80003e08:	86a6                	mv	a3,s1
    80003e0a:	fc040613          	addi	a2,s0,-64
    80003e0e:	4581                	li	a1,0
    80003e10:	854a                	mv	a0,s2
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	d72080e7          	jalr	-654(ra) # 80003b84 <readi>
    80003e1a:	47c1                	li	a5,16
    80003e1c:	fcf518e3          	bne	a0,a5,80003dec <dirlookup+0x3a>
    if(de.inum == 0)
    80003e20:	fc045783          	lhu	a5,-64(s0)
    80003e24:	dfe1                	beqz	a5,80003dfc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e26:	fc240593          	addi	a1,s0,-62
    80003e2a:	854e                	mv	a0,s3
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	f6c080e7          	jalr	-148(ra) # 80003d98 <namecmp>
    80003e34:	f561                	bnez	a0,80003dfc <dirlookup+0x4a>
      if(poff)
    80003e36:	000a0463          	beqz	s4,80003e3e <dirlookup+0x8c>
        *poff = off;
    80003e3a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e3e:	fc045583          	lhu	a1,-64(s0)
    80003e42:	00092503          	lw	a0,0(s2)
    80003e46:	fffff097          	auipc	ra,0xfffff
    80003e4a:	756080e7          	jalr	1878(ra) # 8000359c <iget>
    80003e4e:	a011                	j	80003e52 <dirlookup+0xa0>
  return 0;
    80003e50:	4501                	li	a0,0
}
    80003e52:	70e2                	ld	ra,56(sp)
    80003e54:	7442                	ld	s0,48(sp)
    80003e56:	74a2                	ld	s1,40(sp)
    80003e58:	7902                	ld	s2,32(sp)
    80003e5a:	69e2                	ld	s3,24(sp)
    80003e5c:	6a42                	ld	s4,16(sp)
    80003e5e:	6121                	addi	sp,sp,64
    80003e60:	8082                	ret

0000000080003e62 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e62:	711d                	addi	sp,sp,-96
    80003e64:	ec86                	sd	ra,88(sp)
    80003e66:	e8a2                	sd	s0,80(sp)
    80003e68:	e4a6                	sd	s1,72(sp)
    80003e6a:	e0ca                	sd	s2,64(sp)
    80003e6c:	fc4e                	sd	s3,56(sp)
    80003e6e:	f852                	sd	s4,48(sp)
    80003e70:	f456                	sd	s5,40(sp)
    80003e72:	f05a                	sd	s6,32(sp)
    80003e74:	ec5e                	sd	s7,24(sp)
    80003e76:	e862                	sd	s8,16(sp)
    80003e78:	e466                	sd	s9,8(sp)
    80003e7a:	1080                	addi	s0,sp,96
    80003e7c:	84aa                	mv	s1,a0
    80003e7e:	8aae                	mv	s5,a1
    80003e80:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e82:	00054703          	lbu	a4,0(a0)
    80003e86:	02f00793          	li	a5,47
    80003e8a:	02f70363          	beq	a4,a5,80003eb0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e8e:	ffffe097          	auipc	ra,0xffffe
    80003e92:	dce080e7          	jalr	-562(ra) # 80001c5c <myproc>
    80003e96:	15053503          	ld	a0,336(a0)
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	9f8080e7          	jalr	-1544(ra) # 80003892 <idup>
    80003ea2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ea4:	02f00913          	li	s2,47
  len = path - s;
    80003ea8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003eaa:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eac:	4b85                	li	s7,1
    80003eae:	a865                	j	80003f66 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003eb0:	4585                	li	a1,1
    80003eb2:	4505                	li	a0,1
    80003eb4:	fffff097          	auipc	ra,0xfffff
    80003eb8:	6e8080e7          	jalr	1768(ra) # 8000359c <iget>
    80003ebc:	89aa                	mv	s3,a0
    80003ebe:	b7dd                	j	80003ea4 <namex+0x42>
      iunlockput(ip);
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	c70080e7          	jalr	-912(ra) # 80003b32 <iunlockput>
      return 0;
    80003eca:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ecc:	854e                	mv	a0,s3
    80003ece:	60e6                	ld	ra,88(sp)
    80003ed0:	6446                	ld	s0,80(sp)
    80003ed2:	64a6                	ld	s1,72(sp)
    80003ed4:	6906                	ld	s2,64(sp)
    80003ed6:	79e2                	ld	s3,56(sp)
    80003ed8:	7a42                	ld	s4,48(sp)
    80003eda:	7aa2                	ld	s5,40(sp)
    80003edc:	7b02                	ld	s6,32(sp)
    80003ede:	6be2                	ld	s7,24(sp)
    80003ee0:	6c42                	ld	s8,16(sp)
    80003ee2:	6ca2                	ld	s9,8(sp)
    80003ee4:	6125                	addi	sp,sp,96
    80003ee6:	8082                	ret
      iunlock(ip);
    80003ee8:	854e                	mv	a0,s3
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	aa8080e7          	jalr	-1368(ra) # 80003992 <iunlock>
      return ip;
    80003ef2:	bfe9                	j	80003ecc <namex+0x6a>
      iunlockput(ip);
    80003ef4:	854e                	mv	a0,s3
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	c3c080e7          	jalr	-964(ra) # 80003b32 <iunlockput>
      return 0;
    80003efe:	89e6                	mv	s3,s9
    80003f00:	b7f1                	j	80003ecc <namex+0x6a>
  len = path - s;
    80003f02:	40b48633          	sub	a2,s1,a1
    80003f06:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f0a:	099c5463          	bge	s8,s9,80003f92 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f0e:	4639                	li	a2,14
    80003f10:	8552                	mv	a0,s4
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	f90080e7          	jalr	-112(ra) # 80000ea2 <memmove>
  while(*path == '/')
    80003f1a:	0004c783          	lbu	a5,0(s1)
    80003f1e:	01279763          	bne	a5,s2,80003f2c <namex+0xca>
    path++;
    80003f22:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f24:	0004c783          	lbu	a5,0(s1)
    80003f28:	ff278de3          	beq	a5,s2,80003f22 <namex+0xc0>
    ilock(ip);
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	9a2080e7          	jalr	-1630(ra) # 800038d0 <ilock>
    if(ip->type != T_DIR){
    80003f36:	04499783          	lh	a5,68(s3)
    80003f3a:	f97793e3          	bne	a5,s7,80003ec0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f3e:	000a8563          	beqz	s5,80003f48 <namex+0xe6>
    80003f42:	0004c783          	lbu	a5,0(s1)
    80003f46:	d3cd                	beqz	a5,80003ee8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f48:	865a                	mv	a2,s6
    80003f4a:	85d2                	mv	a1,s4
    80003f4c:	854e                	mv	a0,s3
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	e64080e7          	jalr	-412(ra) # 80003db2 <dirlookup>
    80003f56:	8caa                	mv	s9,a0
    80003f58:	dd51                	beqz	a0,80003ef4 <namex+0x92>
    iunlockput(ip);
    80003f5a:	854e                	mv	a0,s3
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	bd6080e7          	jalr	-1066(ra) # 80003b32 <iunlockput>
    ip = next;
    80003f64:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f66:	0004c783          	lbu	a5,0(s1)
    80003f6a:	05279763          	bne	a5,s2,80003fb8 <namex+0x156>
    path++;
    80003f6e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f70:	0004c783          	lbu	a5,0(s1)
    80003f74:	ff278de3          	beq	a5,s2,80003f6e <namex+0x10c>
  if(*path == 0)
    80003f78:	c79d                	beqz	a5,80003fa6 <namex+0x144>
    path++;
    80003f7a:	85a6                	mv	a1,s1
  len = path - s;
    80003f7c:	8cda                	mv	s9,s6
    80003f7e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f80:	01278963          	beq	a5,s2,80003f92 <namex+0x130>
    80003f84:	dfbd                	beqz	a5,80003f02 <namex+0xa0>
    path++;
    80003f86:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f88:	0004c783          	lbu	a5,0(s1)
    80003f8c:	ff279ce3          	bne	a5,s2,80003f84 <namex+0x122>
    80003f90:	bf8d                	j	80003f02 <namex+0xa0>
    memmove(name, s, len);
    80003f92:	2601                	sext.w	a2,a2
    80003f94:	8552                	mv	a0,s4
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	f0c080e7          	jalr	-244(ra) # 80000ea2 <memmove>
    name[len] = 0;
    80003f9e:	9cd2                	add	s9,s9,s4
    80003fa0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fa4:	bf9d                	j	80003f1a <namex+0xb8>
  if(nameiparent){
    80003fa6:	f20a83e3          	beqz	s5,80003ecc <namex+0x6a>
    iput(ip);
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	ade080e7          	jalr	-1314(ra) # 80003a8a <iput>
    return 0;
    80003fb4:	4981                	li	s3,0
    80003fb6:	bf19                	j	80003ecc <namex+0x6a>
  if(*path == 0)
    80003fb8:	d7fd                	beqz	a5,80003fa6 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fba:	0004c783          	lbu	a5,0(s1)
    80003fbe:	85a6                	mv	a1,s1
    80003fc0:	b7d1                	j	80003f84 <namex+0x122>

0000000080003fc2 <dirlink>:
{
    80003fc2:	7139                	addi	sp,sp,-64
    80003fc4:	fc06                	sd	ra,56(sp)
    80003fc6:	f822                	sd	s0,48(sp)
    80003fc8:	f426                	sd	s1,40(sp)
    80003fca:	f04a                	sd	s2,32(sp)
    80003fcc:	ec4e                	sd	s3,24(sp)
    80003fce:	e852                	sd	s4,16(sp)
    80003fd0:	0080                	addi	s0,sp,64
    80003fd2:	892a                	mv	s2,a0
    80003fd4:	8a2e                	mv	s4,a1
    80003fd6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fd8:	4601                	li	a2,0
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	dd8080e7          	jalr	-552(ra) # 80003db2 <dirlookup>
    80003fe2:	e93d                	bnez	a0,80004058 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe4:	04c92483          	lw	s1,76(s2)
    80003fe8:	c49d                	beqz	s1,80004016 <dirlink+0x54>
    80003fea:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fec:	4741                	li	a4,16
    80003fee:	86a6                	mv	a3,s1
    80003ff0:	fc040613          	addi	a2,s0,-64
    80003ff4:	4581                	li	a1,0
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	b8c080e7          	jalr	-1140(ra) # 80003b84 <readi>
    80004000:	47c1                	li	a5,16
    80004002:	06f51163          	bne	a0,a5,80004064 <dirlink+0xa2>
    if(de.inum == 0)
    80004006:	fc045783          	lhu	a5,-64(s0)
    8000400a:	c791                	beqz	a5,80004016 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400c:	24c1                	addiw	s1,s1,16
    8000400e:	04c92783          	lw	a5,76(s2)
    80004012:	fcf4ede3          	bltu	s1,a5,80003fec <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004016:	4639                	li	a2,14
    80004018:	85d2                	mv	a1,s4
    8000401a:	fc240513          	addi	a0,s0,-62
    8000401e:	ffffd097          	auipc	ra,0xffffd
    80004022:	f3c080e7          	jalr	-196(ra) # 80000f5a <strncpy>
  de.inum = inum;
    80004026:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402a:	4741                	li	a4,16
    8000402c:	86a6                	mv	a3,s1
    8000402e:	fc040613          	addi	a2,s0,-64
    80004032:	4581                	li	a1,0
    80004034:	854a                	mv	a0,s2
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	c46080e7          	jalr	-954(ra) # 80003c7c <writei>
    8000403e:	872a                	mv	a4,a0
    80004040:	47c1                	li	a5,16
  return 0;
    80004042:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004044:	02f71863          	bne	a4,a5,80004074 <dirlink+0xb2>
}
    80004048:	70e2                	ld	ra,56(sp)
    8000404a:	7442                	ld	s0,48(sp)
    8000404c:	74a2                	ld	s1,40(sp)
    8000404e:	7902                	ld	s2,32(sp)
    80004050:	69e2                	ld	s3,24(sp)
    80004052:	6a42                	ld	s4,16(sp)
    80004054:	6121                	addi	sp,sp,64
    80004056:	8082                	ret
    iput(ip);
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	a32080e7          	jalr	-1486(ra) # 80003a8a <iput>
    return -1;
    80004060:	557d                	li	a0,-1
    80004062:	b7dd                	j	80004048 <dirlink+0x86>
      panic("dirlink read");
    80004064:	00004517          	auipc	a0,0x4
    80004068:	59450513          	addi	a0,a0,1428 # 800085f8 <syscalls+0x1c8>
    8000406c:	ffffc097          	auipc	ra,0xffffc
    80004070:	4d6080e7          	jalr	1238(ra) # 80000542 <panic>
    panic("dirlink");
    80004074:	00004517          	auipc	a0,0x4
    80004078:	6a450513          	addi	a0,a0,1700 # 80008718 <syscalls+0x2e8>
    8000407c:	ffffc097          	auipc	ra,0xffffc
    80004080:	4c6080e7          	jalr	1222(ra) # 80000542 <panic>

0000000080004084 <namei>:

struct inode*
namei(char *path)
{
    80004084:	1101                	addi	sp,sp,-32
    80004086:	ec06                	sd	ra,24(sp)
    80004088:	e822                	sd	s0,16(sp)
    8000408a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000408c:	fe040613          	addi	a2,s0,-32
    80004090:	4581                	li	a1,0
    80004092:	00000097          	auipc	ra,0x0
    80004096:	dd0080e7          	jalr	-560(ra) # 80003e62 <namex>
}
    8000409a:	60e2                	ld	ra,24(sp)
    8000409c:	6442                	ld	s0,16(sp)
    8000409e:	6105                	addi	sp,sp,32
    800040a0:	8082                	ret

00000000800040a2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040a2:	1141                	addi	sp,sp,-16
    800040a4:	e406                	sd	ra,8(sp)
    800040a6:	e022                	sd	s0,0(sp)
    800040a8:	0800                	addi	s0,sp,16
    800040aa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040ac:	4585                	li	a1,1
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	db4080e7          	jalr	-588(ra) # 80003e62 <namex>
}
    800040b6:	60a2                	ld	ra,8(sp)
    800040b8:	6402                	ld	s0,0(sp)
    800040ba:	0141                	addi	sp,sp,16
    800040bc:	8082                	ret

00000000800040be <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040be:	1101                	addi	sp,sp,-32
    800040c0:	ec06                	sd	ra,24(sp)
    800040c2:	e822                	sd	s0,16(sp)
    800040c4:	e426                	sd	s1,8(sp)
    800040c6:	e04a                	sd	s2,0(sp)
    800040c8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040ca:	0023e917          	auipc	s2,0x23e
    800040ce:	85690913          	addi	s2,s2,-1962 # 80241920 <log>
    800040d2:	01892583          	lw	a1,24(s2)
    800040d6:	02892503          	lw	a0,40(s2)
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	ff4080e7          	jalr	-12(ra) # 800030ce <bread>
    800040e2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040e4:	02c92683          	lw	a3,44(s2)
    800040e8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040ea:	02d05763          	blez	a3,80004118 <write_head+0x5a>
    800040ee:	0023e797          	auipc	a5,0x23e
    800040f2:	86278793          	addi	a5,a5,-1950 # 80241950 <log+0x30>
    800040f6:	05c50713          	addi	a4,a0,92
    800040fa:	36fd                	addiw	a3,a3,-1
    800040fc:	1682                	slli	a3,a3,0x20
    800040fe:	9281                	srli	a3,a3,0x20
    80004100:	068a                	slli	a3,a3,0x2
    80004102:	0023e617          	auipc	a2,0x23e
    80004106:	85260613          	addi	a2,a2,-1966 # 80241954 <log+0x34>
    8000410a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000410c:	4390                	lw	a2,0(a5)
    8000410e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004110:	0791                	addi	a5,a5,4
    80004112:	0711                	addi	a4,a4,4
    80004114:	fed79ce3          	bne	a5,a3,8000410c <write_head+0x4e>
  }
  bwrite(buf);
    80004118:	8526                	mv	a0,s1
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	0a6080e7          	jalr	166(ra) # 800031c0 <bwrite>
  brelse(buf);
    80004122:	8526                	mv	a0,s1
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	0da080e7          	jalr	218(ra) # 800031fe <brelse>
}
    8000412c:	60e2                	ld	ra,24(sp)
    8000412e:	6442                	ld	s0,16(sp)
    80004130:	64a2                	ld	s1,8(sp)
    80004132:	6902                	ld	s2,0(sp)
    80004134:	6105                	addi	sp,sp,32
    80004136:	8082                	ret

0000000080004138 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004138:	0023e797          	auipc	a5,0x23e
    8000413c:	8147a783          	lw	a5,-2028(a5) # 8024194c <log+0x2c>
    80004140:	0af05663          	blez	a5,800041ec <install_trans+0xb4>
{
    80004144:	7139                	addi	sp,sp,-64
    80004146:	fc06                	sd	ra,56(sp)
    80004148:	f822                	sd	s0,48(sp)
    8000414a:	f426                	sd	s1,40(sp)
    8000414c:	f04a                	sd	s2,32(sp)
    8000414e:	ec4e                	sd	s3,24(sp)
    80004150:	e852                	sd	s4,16(sp)
    80004152:	e456                	sd	s5,8(sp)
    80004154:	0080                	addi	s0,sp,64
    80004156:	0023da97          	auipc	s5,0x23d
    8000415a:	7faa8a93          	addi	s5,s5,2042 # 80241950 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000415e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004160:	0023d997          	auipc	s3,0x23d
    80004164:	7c098993          	addi	s3,s3,1984 # 80241920 <log>
    80004168:	0189a583          	lw	a1,24(s3)
    8000416c:	014585bb          	addw	a1,a1,s4
    80004170:	2585                	addiw	a1,a1,1
    80004172:	0289a503          	lw	a0,40(s3)
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	f58080e7          	jalr	-168(ra) # 800030ce <bread>
    8000417e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004180:	000aa583          	lw	a1,0(s5)
    80004184:	0289a503          	lw	a0,40(s3)
    80004188:	fffff097          	auipc	ra,0xfffff
    8000418c:	f46080e7          	jalr	-186(ra) # 800030ce <bread>
    80004190:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004192:	40000613          	li	a2,1024
    80004196:	05890593          	addi	a1,s2,88
    8000419a:	05850513          	addi	a0,a0,88
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	d04080e7          	jalr	-764(ra) # 80000ea2 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041a6:	8526                	mv	a0,s1
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	018080e7          	jalr	24(ra) # 800031c0 <bwrite>
    bunpin(dbuf);
    800041b0:	8526                	mv	a0,s1
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	126080e7          	jalr	294(ra) # 800032d8 <bunpin>
    brelse(lbuf);
    800041ba:	854a                	mv	a0,s2
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	042080e7          	jalr	66(ra) # 800031fe <brelse>
    brelse(dbuf);
    800041c4:	8526                	mv	a0,s1
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	038080e7          	jalr	56(ra) # 800031fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ce:	2a05                	addiw	s4,s4,1
    800041d0:	0a91                	addi	s5,s5,4
    800041d2:	02c9a783          	lw	a5,44(s3)
    800041d6:	f8fa49e3          	blt	s4,a5,80004168 <install_trans+0x30>
}
    800041da:	70e2                	ld	ra,56(sp)
    800041dc:	7442                	ld	s0,48(sp)
    800041de:	74a2                	ld	s1,40(sp)
    800041e0:	7902                	ld	s2,32(sp)
    800041e2:	69e2                	ld	s3,24(sp)
    800041e4:	6a42                	ld	s4,16(sp)
    800041e6:	6aa2                	ld	s5,8(sp)
    800041e8:	6121                	addi	sp,sp,64
    800041ea:	8082                	ret
    800041ec:	8082                	ret

00000000800041ee <initlog>:
{
    800041ee:	7179                	addi	sp,sp,-48
    800041f0:	f406                	sd	ra,40(sp)
    800041f2:	f022                	sd	s0,32(sp)
    800041f4:	ec26                	sd	s1,24(sp)
    800041f6:	e84a                	sd	s2,16(sp)
    800041f8:	e44e                	sd	s3,8(sp)
    800041fa:	1800                	addi	s0,sp,48
    800041fc:	892a                	mv	s2,a0
    800041fe:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004200:	0023d497          	auipc	s1,0x23d
    80004204:	72048493          	addi	s1,s1,1824 # 80241920 <log>
    80004208:	00004597          	auipc	a1,0x4
    8000420c:	40058593          	addi	a1,a1,1024 # 80008608 <syscalls+0x1d8>
    80004210:	8526                	mv	a0,s1
    80004212:	ffffd097          	auipc	ra,0xffffd
    80004216:	aa8080e7          	jalr	-1368(ra) # 80000cba <initlock>
  log.start = sb->logstart;
    8000421a:	0149a583          	lw	a1,20(s3)
    8000421e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004220:	0109a783          	lw	a5,16(s3)
    80004224:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004226:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000422a:	854a                	mv	a0,s2
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	ea2080e7          	jalr	-350(ra) # 800030ce <bread>
  log.lh.n = lh->n;
    80004234:	4d34                	lw	a3,88(a0)
    80004236:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004238:	02d05563          	blez	a3,80004262 <initlog+0x74>
    8000423c:	05c50793          	addi	a5,a0,92
    80004240:	0023d717          	auipc	a4,0x23d
    80004244:	71070713          	addi	a4,a4,1808 # 80241950 <log+0x30>
    80004248:	36fd                	addiw	a3,a3,-1
    8000424a:	1682                	slli	a3,a3,0x20
    8000424c:	9281                	srli	a3,a3,0x20
    8000424e:	068a                	slli	a3,a3,0x2
    80004250:	06050613          	addi	a2,a0,96
    80004254:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004256:	4390                	lw	a2,0(a5)
    80004258:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000425a:	0791                	addi	a5,a5,4
    8000425c:	0711                	addi	a4,a4,4
    8000425e:	fed79ce3          	bne	a5,a3,80004256 <initlog+0x68>
  brelse(buf);
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	f9c080e7          	jalr	-100(ra) # 800031fe <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	ece080e7          	jalr	-306(ra) # 80004138 <install_trans>
  log.lh.n = 0;
    80004272:	0023d797          	auipc	a5,0x23d
    80004276:	6c07ad23          	sw	zero,1754(a5) # 8024194c <log+0x2c>
  write_head(); // clear the log
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	e44080e7          	jalr	-444(ra) # 800040be <write_head>
}
    80004282:	70a2                	ld	ra,40(sp)
    80004284:	7402                	ld	s0,32(sp)
    80004286:	64e2                	ld	s1,24(sp)
    80004288:	6942                	ld	s2,16(sp)
    8000428a:	69a2                	ld	s3,8(sp)
    8000428c:	6145                	addi	sp,sp,48
    8000428e:	8082                	ret

0000000080004290 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004290:	1101                	addi	sp,sp,-32
    80004292:	ec06                	sd	ra,24(sp)
    80004294:	e822                	sd	s0,16(sp)
    80004296:	e426                	sd	s1,8(sp)
    80004298:	e04a                	sd	s2,0(sp)
    8000429a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000429c:	0023d517          	auipc	a0,0x23d
    800042a0:	68450513          	addi	a0,a0,1668 # 80241920 <log>
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	aa6080e7          	jalr	-1370(ra) # 80000d4a <acquire>
  while(1){
    if(log.committing){
    800042ac:	0023d497          	auipc	s1,0x23d
    800042b0:	67448493          	addi	s1,s1,1652 # 80241920 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042b4:	4979                	li	s2,30
    800042b6:	a039                	j	800042c4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042b8:	85a6                	mv	a1,s1
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffe097          	auipc	ra,0xffffe
    800042c0:	1b4080e7          	jalr	436(ra) # 80002470 <sleep>
    if(log.committing){
    800042c4:	50dc                	lw	a5,36(s1)
    800042c6:	fbed                	bnez	a5,800042b8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042c8:	509c                	lw	a5,32(s1)
    800042ca:	0017871b          	addiw	a4,a5,1
    800042ce:	0007069b          	sext.w	a3,a4
    800042d2:	0027179b          	slliw	a5,a4,0x2
    800042d6:	9fb9                	addw	a5,a5,a4
    800042d8:	0017979b          	slliw	a5,a5,0x1
    800042dc:	54d8                	lw	a4,44(s1)
    800042de:	9fb9                	addw	a5,a5,a4
    800042e0:	00f95963          	bge	s2,a5,800042f2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042e4:	85a6                	mv	a1,s1
    800042e6:	8526                	mv	a0,s1
    800042e8:	ffffe097          	auipc	ra,0xffffe
    800042ec:	188080e7          	jalr	392(ra) # 80002470 <sleep>
    800042f0:	bfd1                	j	800042c4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042f2:	0023d517          	auipc	a0,0x23d
    800042f6:	62e50513          	addi	a0,a0,1582 # 80241920 <log>
    800042fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	b02080e7          	jalr	-1278(ra) # 80000dfe <release>
      break;
    }
  }
}
    80004304:	60e2                	ld	ra,24(sp)
    80004306:	6442                	ld	s0,16(sp)
    80004308:	64a2                	ld	s1,8(sp)
    8000430a:	6902                	ld	s2,0(sp)
    8000430c:	6105                	addi	sp,sp,32
    8000430e:	8082                	ret

0000000080004310 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004310:	7139                	addi	sp,sp,-64
    80004312:	fc06                	sd	ra,56(sp)
    80004314:	f822                	sd	s0,48(sp)
    80004316:	f426                	sd	s1,40(sp)
    80004318:	f04a                	sd	s2,32(sp)
    8000431a:	ec4e                	sd	s3,24(sp)
    8000431c:	e852                	sd	s4,16(sp)
    8000431e:	e456                	sd	s5,8(sp)
    80004320:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004322:	0023d497          	auipc	s1,0x23d
    80004326:	5fe48493          	addi	s1,s1,1534 # 80241920 <log>
    8000432a:	8526                	mv	a0,s1
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	a1e080e7          	jalr	-1506(ra) # 80000d4a <acquire>
  log.outstanding -= 1;
    80004334:	509c                	lw	a5,32(s1)
    80004336:	37fd                	addiw	a5,a5,-1
    80004338:	0007891b          	sext.w	s2,a5
    8000433c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000433e:	50dc                	lw	a5,36(s1)
    80004340:	e7b9                	bnez	a5,8000438e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004342:	04091e63          	bnez	s2,8000439e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004346:	0023d497          	auipc	s1,0x23d
    8000434a:	5da48493          	addi	s1,s1,1498 # 80241920 <log>
    8000434e:	4785                	li	a5,1
    80004350:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004352:	8526                	mv	a0,s1
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	aaa080e7          	jalr	-1366(ra) # 80000dfe <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000435c:	54dc                	lw	a5,44(s1)
    8000435e:	06f04763          	bgtz	a5,800043cc <end_op+0xbc>
    acquire(&log.lock);
    80004362:	0023d497          	auipc	s1,0x23d
    80004366:	5be48493          	addi	s1,s1,1470 # 80241920 <log>
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	9de080e7          	jalr	-1570(ra) # 80000d4a <acquire>
    log.committing = 0;
    80004374:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004378:	8526                	mv	a0,s1
    8000437a:	ffffe097          	auipc	ra,0xffffe
    8000437e:	276080e7          	jalr	630(ra) # 800025f0 <wakeup>
    release(&log.lock);
    80004382:	8526                	mv	a0,s1
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	a7a080e7          	jalr	-1414(ra) # 80000dfe <release>
}
    8000438c:	a03d                	j	800043ba <end_op+0xaa>
    panic("log.committing");
    8000438e:	00004517          	auipc	a0,0x4
    80004392:	28250513          	addi	a0,a0,642 # 80008610 <syscalls+0x1e0>
    80004396:	ffffc097          	auipc	ra,0xffffc
    8000439a:	1ac080e7          	jalr	428(ra) # 80000542 <panic>
    wakeup(&log);
    8000439e:	0023d497          	auipc	s1,0x23d
    800043a2:	58248493          	addi	s1,s1,1410 # 80241920 <log>
    800043a6:	8526                	mv	a0,s1
    800043a8:	ffffe097          	auipc	ra,0xffffe
    800043ac:	248080e7          	jalr	584(ra) # 800025f0 <wakeup>
  release(&log.lock);
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	a4c080e7          	jalr	-1460(ra) # 80000dfe <release>
}
    800043ba:	70e2                	ld	ra,56(sp)
    800043bc:	7442                	ld	s0,48(sp)
    800043be:	74a2                	ld	s1,40(sp)
    800043c0:	7902                	ld	s2,32(sp)
    800043c2:	69e2                	ld	s3,24(sp)
    800043c4:	6a42                	ld	s4,16(sp)
    800043c6:	6aa2                	ld	s5,8(sp)
    800043c8:	6121                	addi	sp,sp,64
    800043ca:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043cc:	0023da97          	auipc	s5,0x23d
    800043d0:	584a8a93          	addi	s5,s5,1412 # 80241950 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043d4:	0023da17          	auipc	s4,0x23d
    800043d8:	54ca0a13          	addi	s4,s4,1356 # 80241920 <log>
    800043dc:	018a2583          	lw	a1,24(s4)
    800043e0:	012585bb          	addw	a1,a1,s2
    800043e4:	2585                	addiw	a1,a1,1
    800043e6:	028a2503          	lw	a0,40(s4)
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	ce4080e7          	jalr	-796(ra) # 800030ce <bread>
    800043f2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043f4:	000aa583          	lw	a1,0(s5)
    800043f8:	028a2503          	lw	a0,40(s4)
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	cd2080e7          	jalr	-814(ra) # 800030ce <bread>
    80004404:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004406:	40000613          	li	a2,1024
    8000440a:	05850593          	addi	a1,a0,88
    8000440e:	05848513          	addi	a0,s1,88
    80004412:	ffffd097          	auipc	ra,0xffffd
    80004416:	a90080e7          	jalr	-1392(ra) # 80000ea2 <memmove>
    bwrite(to);  // write the log
    8000441a:	8526                	mv	a0,s1
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	da4080e7          	jalr	-604(ra) # 800031c0 <bwrite>
    brelse(from);
    80004424:	854e                	mv	a0,s3
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	dd8080e7          	jalr	-552(ra) # 800031fe <brelse>
    brelse(to);
    8000442e:	8526                	mv	a0,s1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	dce080e7          	jalr	-562(ra) # 800031fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004438:	2905                	addiw	s2,s2,1
    8000443a:	0a91                	addi	s5,s5,4
    8000443c:	02ca2783          	lw	a5,44(s4)
    80004440:	f8f94ee3          	blt	s2,a5,800043dc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004444:	00000097          	auipc	ra,0x0
    80004448:	c7a080e7          	jalr	-902(ra) # 800040be <write_head>
    install_trans(); // Now install writes to home locations
    8000444c:	00000097          	auipc	ra,0x0
    80004450:	cec080e7          	jalr	-788(ra) # 80004138 <install_trans>
    log.lh.n = 0;
    80004454:	0023d797          	auipc	a5,0x23d
    80004458:	4e07ac23          	sw	zero,1272(a5) # 8024194c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	c62080e7          	jalr	-926(ra) # 800040be <write_head>
    80004464:	bdfd                	j	80004362 <end_op+0x52>

0000000080004466 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004466:	1101                	addi	sp,sp,-32
    80004468:	ec06                	sd	ra,24(sp)
    8000446a:	e822                	sd	s0,16(sp)
    8000446c:	e426                	sd	s1,8(sp)
    8000446e:	e04a                	sd	s2,0(sp)
    80004470:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004472:	0023d717          	auipc	a4,0x23d
    80004476:	4da72703          	lw	a4,1242(a4) # 8024194c <log+0x2c>
    8000447a:	47f5                	li	a5,29
    8000447c:	08e7c063          	blt	a5,a4,800044fc <log_write+0x96>
    80004480:	84aa                	mv	s1,a0
    80004482:	0023d797          	auipc	a5,0x23d
    80004486:	4ba7a783          	lw	a5,1210(a5) # 8024193c <log+0x1c>
    8000448a:	37fd                	addiw	a5,a5,-1
    8000448c:	06f75863          	bge	a4,a5,800044fc <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004490:	0023d797          	auipc	a5,0x23d
    80004494:	4b07a783          	lw	a5,1200(a5) # 80241940 <log+0x20>
    80004498:	06f05a63          	blez	a5,8000450c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000449c:	0023d917          	auipc	s2,0x23d
    800044a0:	48490913          	addi	s2,s2,1156 # 80241920 <log>
    800044a4:	854a                	mv	a0,s2
    800044a6:	ffffd097          	auipc	ra,0xffffd
    800044aa:	8a4080e7          	jalr	-1884(ra) # 80000d4a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800044ae:	02c92603          	lw	a2,44(s2)
    800044b2:	06c05563          	blez	a2,8000451c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044b6:	44cc                	lw	a1,12(s1)
    800044b8:	0023d717          	auipc	a4,0x23d
    800044bc:	49870713          	addi	a4,a4,1176 # 80241950 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044c0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044c2:	4314                	lw	a3,0(a4)
    800044c4:	04b68d63          	beq	a3,a1,8000451e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800044c8:	2785                	addiw	a5,a5,1
    800044ca:	0711                	addi	a4,a4,4
    800044cc:	fec79be3          	bne	a5,a2,800044c2 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044d0:	0621                	addi	a2,a2,8
    800044d2:	060a                	slli	a2,a2,0x2
    800044d4:	0023d797          	auipc	a5,0x23d
    800044d8:	44c78793          	addi	a5,a5,1100 # 80241920 <log>
    800044dc:	963e                	add	a2,a2,a5
    800044de:	44dc                	lw	a5,12(s1)
    800044e0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044e2:	8526                	mv	a0,s1
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	db8080e7          	jalr	-584(ra) # 8000329c <bpin>
    log.lh.n++;
    800044ec:	0023d717          	auipc	a4,0x23d
    800044f0:	43470713          	addi	a4,a4,1076 # 80241920 <log>
    800044f4:	575c                	lw	a5,44(a4)
    800044f6:	2785                	addiw	a5,a5,1
    800044f8:	d75c                	sw	a5,44(a4)
    800044fa:	a83d                	j	80004538 <log_write+0xd2>
    panic("too big a transaction");
    800044fc:	00004517          	auipc	a0,0x4
    80004500:	12450513          	addi	a0,a0,292 # 80008620 <syscalls+0x1f0>
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	03e080e7          	jalr	62(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    8000450c:	00004517          	auipc	a0,0x4
    80004510:	12c50513          	addi	a0,a0,300 # 80008638 <syscalls+0x208>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	02e080e7          	jalr	46(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000451c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000451e:	00878713          	addi	a4,a5,8
    80004522:	00271693          	slli	a3,a4,0x2
    80004526:	0023d717          	auipc	a4,0x23d
    8000452a:	3fa70713          	addi	a4,a4,1018 # 80241920 <log>
    8000452e:	9736                	add	a4,a4,a3
    80004530:	44d4                	lw	a3,12(s1)
    80004532:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004534:	faf607e3          	beq	a2,a5,800044e2 <log_write+0x7c>
  }
  release(&log.lock);
    80004538:	0023d517          	auipc	a0,0x23d
    8000453c:	3e850513          	addi	a0,a0,1000 # 80241920 <log>
    80004540:	ffffd097          	auipc	ra,0xffffd
    80004544:	8be080e7          	jalr	-1858(ra) # 80000dfe <release>
}
    80004548:	60e2                	ld	ra,24(sp)
    8000454a:	6442                	ld	s0,16(sp)
    8000454c:	64a2                	ld	s1,8(sp)
    8000454e:	6902                	ld	s2,0(sp)
    80004550:	6105                	addi	sp,sp,32
    80004552:	8082                	ret

0000000080004554 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004554:	1101                	addi	sp,sp,-32
    80004556:	ec06                	sd	ra,24(sp)
    80004558:	e822                	sd	s0,16(sp)
    8000455a:	e426                	sd	s1,8(sp)
    8000455c:	e04a                	sd	s2,0(sp)
    8000455e:	1000                	addi	s0,sp,32
    80004560:	84aa                	mv	s1,a0
    80004562:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004564:	00004597          	auipc	a1,0x4
    80004568:	0f458593          	addi	a1,a1,244 # 80008658 <syscalls+0x228>
    8000456c:	0521                	addi	a0,a0,8
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	74c080e7          	jalr	1868(ra) # 80000cba <initlock>
  lk->name = name;
    80004576:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000457a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000457e:	0204a423          	sw	zero,40(s1)
}
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6902                	ld	s2,0(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret

000000008000458e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	e04a                	sd	s2,0(sp)
    80004598:	1000                	addi	s0,sp,32
    8000459a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000459c:	00850913          	addi	s2,a0,8
    800045a0:	854a                	mv	a0,s2
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	7a8080e7          	jalr	1960(ra) # 80000d4a <acquire>
  while (lk->locked) {
    800045aa:	409c                	lw	a5,0(s1)
    800045ac:	cb89                	beqz	a5,800045be <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045ae:	85ca                	mv	a1,s2
    800045b0:	8526                	mv	a0,s1
    800045b2:	ffffe097          	auipc	ra,0xffffe
    800045b6:	ebe080e7          	jalr	-322(ra) # 80002470 <sleep>
  while (lk->locked) {
    800045ba:	409c                	lw	a5,0(s1)
    800045bc:	fbed                	bnez	a5,800045ae <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045be:	4785                	li	a5,1
    800045c0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045c2:	ffffd097          	auipc	ra,0xffffd
    800045c6:	69a080e7          	jalr	1690(ra) # 80001c5c <myproc>
    800045ca:	5d1c                	lw	a5,56(a0)
    800045cc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045ce:	854a                	mv	a0,s2
    800045d0:	ffffd097          	auipc	ra,0xffffd
    800045d4:	82e080e7          	jalr	-2002(ra) # 80000dfe <release>
}
    800045d8:	60e2                	ld	ra,24(sp)
    800045da:	6442                	ld	s0,16(sp)
    800045dc:	64a2                	ld	s1,8(sp)
    800045de:	6902                	ld	s2,0(sp)
    800045e0:	6105                	addi	sp,sp,32
    800045e2:	8082                	ret

00000000800045e4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045e4:	1101                	addi	sp,sp,-32
    800045e6:	ec06                	sd	ra,24(sp)
    800045e8:	e822                	sd	s0,16(sp)
    800045ea:	e426                	sd	s1,8(sp)
    800045ec:	e04a                	sd	s2,0(sp)
    800045ee:	1000                	addi	s0,sp,32
    800045f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045f2:	00850913          	addi	s2,a0,8
    800045f6:	854a                	mv	a0,s2
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	752080e7          	jalr	1874(ra) # 80000d4a <acquire>
  lk->locked = 0;
    80004600:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004604:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004608:	8526                	mv	a0,s1
    8000460a:	ffffe097          	auipc	ra,0xffffe
    8000460e:	fe6080e7          	jalr	-26(ra) # 800025f0 <wakeup>
  release(&lk->lk);
    80004612:	854a                	mv	a0,s2
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	7ea080e7          	jalr	2026(ra) # 80000dfe <release>
}
    8000461c:	60e2                	ld	ra,24(sp)
    8000461e:	6442                	ld	s0,16(sp)
    80004620:	64a2                	ld	s1,8(sp)
    80004622:	6902                	ld	s2,0(sp)
    80004624:	6105                	addi	sp,sp,32
    80004626:	8082                	ret

0000000080004628 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004628:	7179                	addi	sp,sp,-48
    8000462a:	f406                	sd	ra,40(sp)
    8000462c:	f022                	sd	s0,32(sp)
    8000462e:	ec26                	sd	s1,24(sp)
    80004630:	e84a                	sd	s2,16(sp)
    80004632:	e44e                	sd	s3,8(sp)
    80004634:	1800                	addi	s0,sp,48
    80004636:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004638:	00850913          	addi	s2,a0,8
    8000463c:	854a                	mv	a0,s2
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	70c080e7          	jalr	1804(ra) # 80000d4a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004646:	409c                	lw	a5,0(s1)
    80004648:	ef99                	bnez	a5,80004666 <holdingsleep+0x3e>
    8000464a:	4481                	li	s1,0
  release(&lk->lk);
    8000464c:	854a                	mv	a0,s2
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	7b0080e7          	jalr	1968(ra) # 80000dfe <release>
  return r;
}
    80004656:	8526                	mv	a0,s1
    80004658:	70a2                	ld	ra,40(sp)
    8000465a:	7402                	ld	s0,32(sp)
    8000465c:	64e2                	ld	s1,24(sp)
    8000465e:	6942                	ld	s2,16(sp)
    80004660:	69a2                	ld	s3,8(sp)
    80004662:	6145                	addi	sp,sp,48
    80004664:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004666:	0284a983          	lw	s3,40(s1)
    8000466a:	ffffd097          	auipc	ra,0xffffd
    8000466e:	5f2080e7          	jalr	1522(ra) # 80001c5c <myproc>
    80004672:	5d04                	lw	s1,56(a0)
    80004674:	413484b3          	sub	s1,s1,s3
    80004678:	0014b493          	seqz	s1,s1
    8000467c:	bfc1                	j	8000464c <holdingsleep+0x24>

000000008000467e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000467e:	1141                	addi	sp,sp,-16
    80004680:	e406                	sd	ra,8(sp)
    80004682:	e022                	sd	s0,0(sp)
    80004684:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004686:	00004597          	auipc	a1,0x4
    8000468a:	fe258593          	addi	a1,a1,-30 # 80008668 <syscalls+0x238>
    8000468e:	0023d517          	auipc	a0,0x23d
    80004692:	3da50513          	addi	a0,a0,986 # 80241a68 <ftable>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	624080e7          	jalr	1572(ra) # 80000cba <initlock>
}
    8000469e:	60a2                	ld	ra,8(sp)
    800046a0:	6402                	ld	s0,0(sp)
    800046a2:	0141                	addi	sp,sp,16
    800046a4:	8082                	ret

00000000800046a6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046a6:	1101                	addi	sp,sp,-32
    800046a8:	ec06                	sd	ra,24(sp)
    800046aa:	e822                	sd	s0,16(sp)
    800046ac:	e426                	sd	s1,8(sp)
    800046ae:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046b0:	0023d517          	auipc	a0,0x23d
    800046b4:	3b850513          	addi	a0,a0,952 # 80241a68 <ftable>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	692080e7          	jalr	1682(ra) # 80000d4a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046c0:	0023d497          	auipc	s1,0x23d
    800046c4:	3c048493          	addi	s1,s1,960 # 80241a80 <ftable+0x18>
    800046c8:	0023e717          	auipc	a4,0x23e
    800046cc:	35870713          	addi	a4,a4,856 # 80242a20 <ftable+0xfb8>
    if(f->ref == 0){
    800046d0:	40dc                	lw	a5,4(s1)
    800046d2:	cf99                	beqz	a5,800046f0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d4:	02848493          	addi	s1,s1,40
    800046d8:	fee49ce3          	bne	s1,a4,800046d0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046dc:	0023d517          	auipc	a0,0x23d
    800046e0:	38c50513          	addi	a0,a0,908 # 80241a68 <ftable>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	71a080e7          	jalr	1818(ra) # 80000dfe <release>
  return 0;
    800046ec:	4481                	li	s1,0
    800046ee:	a819                	j	80004704 <filealloc+0x5e>
      f->ref = 1;
    800046f0:	4785                	li	a5,1
    800046f2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046f4:	0023d517          	auipc	a0,0x23d
    800046f8:	37450513          	addi	a0,a0,884 # 80241a68 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	702080e7          	jalr	1794(ra) # 80000dfe <release>
}
    80004704:	8526                	mv	a0,s1
    80004706:	60e2                	ld	ra,24(sp)
    80004708:	6442                	ld	s0,16(sp)
    8000470a:	64a2                	ld	s1,8(sp)
    8000470c:	6105                	addi	sp,sp,32
    8000470e:	8082                	ret

0000000080004710 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004710:	1101                	addi	sp,sp,-32
    80004712:	ec06                	sd	ra,24(sp)
    80004714:	e822                	sd	s0,16(sp)
    80004716:	e426                	sd	s1,8(sp)
    80004718:	1000                	addi	s0,sp,32
    8000471a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000471c:	0023d517          	auipc	a0,0x23d
    80004720:	34c50513          	addi	a0,a0,844 # 80241a68 <ftable>
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	626080e7          	jalr	1574(ra) # 80000d4a <acquire>
  if(f->ref < 1)
    8000472c:	40dc                	lw	a5,4(s1)
    8000472e:	02f05263          	blez	a5,80004752 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004732:	2785                	addiw	a5,a5,1
    80004734:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004736:	0023d517          	auipc	a0,0x23d
    8000473a:	33250513          	addi	a0,a0,818 # 80241a68 <ftable>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	6c0080e7          	jalr	1728(ra) # 80000dfe <release>
  return f;
}
    80004746:	8526                	mv	a0,s1
    80004748:	60e2                	ld	ra,24(sp)
    8000474a:	6442                	ld	s0,16(sp)
    8000474c:	64a2                	ld	s1,8(sp)
    8000474e:	6105                	addi	sp,sp,32
    80004750:	8082                	ret
    panic("filedup");
    80004752:	00004517          	auipc	a0,0x4
    80004756:	f1e50513          	addi	a0,a0,-226 # 80008670 <syscalls+0x240>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	de8080e7          	jalr	-536(ra) # 80000542 <panic>

0000000080004762 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004762:	7139                	addi	sp,sp,-64
    80004764:	fc06                	sd	ra,56(sp)
    80004766:	f822                	sd	s0,48(sp)
    80004768:	f426                	sd	s1,40(sp)
    8000476a:	f04a                	sd	s2,32(sp)
    8000476c:	ec4e                	sd	s3,24(sp)
    8000476e:	e852                	sd	s4,16(sp)
    80004770:	e456                	sd	s5,8(sp)
    80004772:	0080                	addi	s0,sp,64
    80004774:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004776:	0023d517          	auipc	a0,0x23d
    8000477a:	2f250513          	addi	a0,a0,754 # 80241a68 <ftable>
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	5cc080e7          	jalr	1484(ra) # 80000d4a <acquire>
  if(f->ref < 1)
    80004786:	40dc                	lw	a5,4(s1)
    80004788:	06f05163          	blez	a5,800047ea <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000478c:	37fd                	addiw	a5,a5,-1
    8000478e:	0007871b          	sext.w	a4,a5
    80004792:	c0dc                	sw	a5,4(s1)
    80004794:	06e04363          	bgtz	a4,800047fa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004798:	0004a903          	lw	s2,0(s1)
    8000479c:	0094ca83          	lbu	s5,9(s1)
    800047a0:	0104ba03          	ld	s4,16(s1)
    800047a4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047a8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047ac:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047b0:	0023d517          	auipc	a0,0x23d
    800047b4:	2b850513          	addi	a0,a0,696 # 80241a68 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	646080e7          	jalr	1606(ra) # 80000dfe <release>

  if(ff.type == FD_PIPE){
    800047c0:	4785                	li	a5,1
    800047c2:	04f90d63          	beq	s2,a5,8000481c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047c6:	3979                	addiw	s2,s2,-2
    800047c8:	4785                	li	a5,1
    800047ca:	0527e063          	bltu	a5,s2,8000480a <fileclose+0xa8>
    begin_op();
    800047ce:	00000097          	auipc	ra,0x0
    800047d2:	ac2080e7          	jalr	-1342(ra) # 80004290 <begin_op>
    iput(ff.ip);
    800047d6:	854e                	mv	a0,s3
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	2b2080e7          	jalr	690(ra) # 80003a8a <iput>
    end_op();
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	b30080e7          	jalr	-1232(ra) # 80004310 <end_op>
    800047e8:	a00d                	j	8000480a <fileclose+0xa8>
    panic("fileclose");
    800047ea:	00004517          	auipc	a0,0x4
    800047ee:	e8e50513          	addi	a0,a0,-370 # 80008678 <syscalls+0x248>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	d50080e7          	jalr	-688(ra) # 80000542 <panic>
    release(&ftable.lock);
    800047fa:	0023d517          	auipc	a0,0x23d
    800047fe:	26e50513          	addi	a0,a0,622 # 80241a68 <ftable>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	5fc080e7          	jalr	1532(ra) # 80000dfe <release>
  }
}
    8000480a:	70e2                	ld	ra,56(sp)
    8000480c:	7442                	ld	s0,48(sp)
    8000480e:	74a2                	ld	s1,40(sp)
    80004810:	7902                	ld	s2,32(sp)
    80004812:	69e2                	ld	s3,24(sp)
    80004814:	6a42                	ld	s4,16(sp)
    80004816:	6aa2                	ld	s5,8(sp)
    80004818:	6121                	addi	sp,sp,64
    8000481a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000481c:	85d6                	mv	a1,s5
    8000481e:	8552                	mv	a0,s4
    80004820:	00000097          	auipc	ra,0x0
    80004824:	372080e7          	jalr	882(ra) # 80004b92 <pipeclose>
    80004828:	b7cd                	j	8000480a <fileclose+0xa8>

000000008000482a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000482a:	715d                	addi	sp,sp,-80
    8000482c:	e486                	sd	ra,72(sp)
    8000482e:	e0a2                	sd	s0,64(sp)
    80004830:	fc26                	sd	s1,56(sp)
    80004832:	f84a                	sd	s2,48(sp)
    80004834:	f44e                	sd	s3,40(sp)
    80004836:	0880                	addi	s0,sp,80
    80004838:	84aa                	mv	s1,a0
    8000483a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000483c:	ffffd097          	auipc	ra,0xffffd
    80004840:	420080e7          	jalr	1056(ra) # 80001c5c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004844:	409c                	lw	a5,0(s1)
    80004846:	37f9                	addiw	a5,a5,-2
    80004848:	4705                	li	a4,1
    8000484a:	04f76763          	bltu	a4,a5,80004898 <filestat+0x6e>
    8000484e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004850:	6c88                	ld	a0,24(s1)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	07e080e7          	jalr	126(ra) # 800038d0 <ilock>
    stati(f->ip, &st);
    8000485a:	fb840593          	addi	a1,s0,-72
    8000485e:	6c88                	ld	a0,24(s1)
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	2fa080e7          	jalr	762(ra) # 80003b5a <stati>
    iunlock(f->ip);
    80004868:	6c88                	ld	a0,24(s1)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	128080e7          	jalr	296(ra) # 80003992 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004872:	46e1                	li	a3,24
    80004874:	fb840613          	addi	a2,s0,-72
    80004878:	85ce                	mv	a1,s3
    8000487a:	05093503          	ld	a0,80(s2)
    8000487e:	ffffd097          	auipc	ra,0xffffd
    80004882:	1ec080e7          	jalr	492(ra) # 80001a6a <copyout>
    80004886:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000488a:	60a6                	ld	ra,72(sp)
    8000488c:	6406                	ld	s0,64(sp)
    8000488e:	74e2                	ld	s1,56(sp)
    80004890:	7942                	ld	s2,48(sp)
    80004892:	79a2                	ld	s3,40(sp)
    80004894:	6161                	addi	sp,sp,80
    80004896:	8082                	ret
  return -1;
    80004898:	557d                	li	a0,-1
    8000489a:	bfc5                	j	8000488a <filestat+0x60>

000000008000489c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000489c:	7179                	addi	sp,sp,-48
    8000489e:	f406                	sd	ra,40(sp)
    800048a0:	f022                	sd	s0,32(sp)
    800048a2:	ec26                	sd	s1,24(sp)
    800048a4:	e84a                	sd	s2,16(sp)
    800048a6:	e44e                	sd	s3,8(sp)
    800048a8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048aa:	00854783          	lbu	a5,8(a0)
    800048ae:	c3d5                	beqz	a5,80004952 <fileread+0xb6>
    800048b0:	84aa                	mv	s1,a0
    800048b2:	89ae                	mv	s3,a1
    800048b4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048b6:	411c                	lw	a5,0(a0)
    800048b8:	4705                	li	a4,1
    800048ba:	04e78963          	beq	a5,a4,8000490c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048be:	470d                	li	a4,3
    800048c0:	04e78d63          	beq	a5,a4,8000491a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048c4:	4709                	li	a4,2
    800048c6:	06e79e63          	bne	a5,a4,80004942 <fileread+0xa6>
    ilock(f->ip);
    800048ca:	6d08                	ld	a0,24(a0)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	004080e7          	jalr	4(ra) # 800038d0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048d4:	874a                	mv	a4,s2
    800048d6:	5094                	lw	a3,32(s1)
    800048d8:	864e                	mv	a2,s3
    800048da:	4585                	li	a1,1
    800048dc:	6c88                	ld	a0,24(s1)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	2a6080e7          	jalr	678(ra) # 80003b84 <readi>
    800048e6:	892a                	mv	s2,a0
    800048e8:	00a05563          	blez	a0,800048f2 <fileread+0x56>
      f->off += r;
    800048ec:	509c                	lw	a5,32(s1)
    800048ee:	9fa9                	addw	a5,a5,a0
    800048f0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048f2:	6c88                	ld	a0,24(s1)
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	09e080e7          	jalr	158(ra) # 80003992 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048fc:	854a                	mv	a0,s2
    800048fe:	70a2                	ld	ra,40(sp)
    80004900:	7402                	ld	s0,32(sp)
    80004902:	64e2                	ld	s1,24(sp)
    80004904:	6942                	ld	s2,16(sp)
    80004906:	69a2                	ld	s3,8(sp)
    80004908:	6145                	addi	sp,sp,48
    8000490a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000490c:	6908                	ld	a0,16(a0)
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	3f4080e7          	jalr	1012(ra) # 80004d02 <piperead>
    80004916:	892a                	mv	s2,a0
    80004918:	b7d5                	j	800048fc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000491a:	02451783          	lh	a5,36(a0)
    8000491e:	03079693          	slli	a3,a5,0x30
    80004922:	92c1                	srli	a3,a3,0x30
    80004924:	4725                	li	a4,9
    80004926:	02d76863          	bltu	a4,a3,80004956 <fileread+0xba>
    8000492a:	0792                	slli	a5,a5,0x4
    8000492c:	0023d717          	auipc	a4,0x23d
    80004930:	09c70713          	addi	a4,a4,156 # 802419c8 <devsw>
    80004934:	97ba                	add	a5,a5,a4
    80004936:	639c                	ld	a5,0(a5)
    80004938:	c38d                	beqz	a5,8000495a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000493a:	4505                	li	a0,1
    8000493c:	9782                	jalr	a5
    8000493e:	892a                	mv	s2,a0
    80004940:	bf75                	j	800048fc <fileread+0x60>
    panic("fileread");
    80004942:	00004517          	auipc	a0,0x4
    80004946:	d4650513          	addi	a0,a0,-698 # 80008688 <syscalls+0x258>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	bf8080e7          	jalr	-1032(ra) # 80000542 <panic>
    return -1;
    80004952:	597d                	li	s2,-1
    80004954:	b765                	j	800048fc <fileread+0x60>
      return -1;
    80004956:	597d                	li	s2,-1
    80004958:	b755                	j	800048fc <fileread+0x60>
    8000495a:	597d                	li	s2,-1
    8000495c:	b745                	j	800048fc <fileread+0x60>

000000008000495e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000495e:	00954783          	lbu	a5,9(a0)
    80004962:	14078563          	beqz	a5,80004aac <filewrite+0x14e>
{
    80004966:	715d                	addi	sp,sp,-80
    80004968:	e486                	sd	ra,72(sp)
    8000496a:	e0a2                	sd	s0,64(sp)
    8000496c:	fc26                	sd	s1,56(sp)
    8000496e:	f84a                	sd	s2,48(sp)
    80004970:	f44e                	sd	s3,40(sp)
    80004972:	f052                	sd	s4,32(sp)
    80004974:	ec56                	sd	s5,24(sp)
    80004976:	e85a                	sd	s6,16(sp)
    80004978:	e45e                	sd	s7,8(sp)
    8000497a:	e062                	sd	s8,0(sp)
    8000497c:	0880                	addi	s0,sp,80
    8000497e:	892a                	mv	s2,a0
    80004980:	8aae                	mv	s5,a1
    80004982:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004984:	411c                	lw	a5,0(a0)
    80004986:	4705                	li	a4,1
    80004988:	02e78263          	beq	a5,a4,800049ac <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000498c:	470d                	li	a4,3
    8000498e:	02e78563          	beq	a5,a4,800049b8 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004992:	4709                	li	a4,2
    80004994:	10e79463          	bne	a5,a4,80004a9c <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004998:	0ec05e63          	blez	a2,80004a94 <filewrite+0x136>
    int i = 0;
    8000499c:	4981                	li	s3,0
    8000499e:	6b05                	lui	s6,0x1
    800049a0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049a4:	6b85                	lui	s7,0x1
    800049a6:	c00b8b9b          	addiw	s7,s7,-1024
    800049aa:	a851                	j	80004a3e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800049ac:	6908                	ld	a0,16(a0)
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	254080e7          	jalr	596(ra) # 80004c02 <pipewrite>
    800049b6:	a85d                	j	80004a6c <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049b8:	02451783          	lh	a5,36(a0)
    800049bc:	03079693          	slli	a3,a5,0x30
    800049c0:	92c1                	srli	a3,a3,0x30
    800049c2:	4725                	li	a4,9
    800049c4:	0ed76663          	bltu	a4,a3,80004ab0 <filewrite+0x152>
    800049c8:	0792                	slli	a5,a5,0x4
    800049ca:	0023d717          	auipc	a4,0x23d
    800049ce:	ffe70713          	addi	a4,a4,-2 # 802419c8 <devsw>
    800049d2:	97ba                	add	a5,a5,a4
    800049d4:	679c                	ld	a5,8(a5)
    800049d6:	cff9                	beqz	a5,80004ab4 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800049d8:	4505                	li	a0,1
    800049da:	9782                	jalr	a5
    800049dc:	a841                	j	80004a6c <filewrite+0x10e>
    800049de:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049e2:	00000097          	auipc	ra,0x0
    800049e6:	8ae080e7          	jalr	-1874(ra) # 80004290 <begin_op>
      ilock(f->ip);
    800049ea:	01893503          	ld	a0,24(s2)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	ee2080e7          	jalr	-286(ra) # 800038d0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049f6:	8762                	mv	a4,s8
    800049f8:	02092683          	lw	a3,32(s2)
    800049fc:	01598633          	add	a2,s3,s5
    80004a00:	4585                	li	a1,1
    80004a02:	01893503          	ld	a0,24(s2)
    80004a06:	fffff097          	auipc	ra,0xfffff
    80004a0a:	276080e7          	jalr	630(ra) # 80003c7c <writei>
    80004a0e:	84aa                	mv	s1,a0
    80004a10:	02a05f63          	blez	a0,80004a4e <filewrite+0xf0>
        f->off += r;
    80004a14:	02092783          	lw	a5,32(s2)
    80004a18:	9fa9                	addw	a5,a5,a0
    80004a1a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a1e:	01893503          	ld	a0,24(s2)
    80004a22:	fffff097          	auipc	ra,0xfffff
    80004a26:	f70080e7          	jalr	-144(ra) # 80003992 <iunlock>
      end_op();
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	8e6080e7          	jalr	-1818(ra) # 80004310 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a32:	049c1963          	bne	s8,s1,80004a84 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a36:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a3a:	0349d663          	bge	s3,s4,80004a66 <filewrite+0x108>
      int n1 = n - i;
    80004a3e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a42:	84be                	mv	s1,a5
    80004a44:	2781                	sext.w	a5,a5
    80004a46:	f8fb5ce3          	bge	s6,a5,800049de <filewrite+0x80>
    80004a4a:	84de                	mv	s1,s7
    80004a4c:	bf49                	j	800049de <filewrite+0x80>
      iunlock(f->ip);
    80004a4e:	01893503          	ld	a0,24(s2)
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	f40080e7          	jalr	-192(ra) # 80003992 <iunlock>
      end_op();
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	8b6080e7          	jalr	-1866(ra) # 80004310 <end_op>
      if(r < 0)
    80004a62:	fc04d8e3          	bgez	s1,80004a32 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a66:	8552                	mv	a0,s4
    80004a68:	033a1863          	bne	s4,s3,80004a98 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a6c:	60a6                	ld	ra,72(sp)
    80004a6e:	6406                	ld	s0,64(sp)
    80004a70:	74e2                	ld	s1,56(sp)
    80004a72:	7942                	ld	s2,48(sp)
    80004a74:	79a2                	ld	s3,40(sp)
    80004a76:	7a02                	ld	s4,32(sp)
    80004a78:	6ae2                	ld	s5,24(sp)
    80004a7a:	6b42                	ld	s6,16(sp)
    80004a7c:	6ba2                	ld	s7,8(sp)
    80004a7e:	6c02                	ld	s8,0(sp)
    80004a80:	6161                	addi	sp,sp,80
    80004a82:	8082                	ret
        panic("short filewrite");
    80004a84:	00004517          	auipc	a0,0x4
    80004a88:	c1450513          	addi	a0,a0,-1004 # 80008698 <syscalls+0x268>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	ab6080e7          	jalr	-1354(ra) # 80000542 <panic>
    int i = 0;
    80004a94:	4981                	li	s3,0
    80004a96:	bfc1                	j	80004a66 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a98:	557d                	li	a0,-1
    80004a9a:	bfc9                	j	80004a6c <filewrite+0x10e>
    panic("filewrite");
    80004a9c:	00004517          	auipc	a0,0x4
    80004aa0:	c0c50513          	addi	a0,a0,-1012 # 800086a8 <syscalls+0x278>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	a9e080e7          	jalr	-1378(ra) # 80000542 <panic>
    return -1;
    80004aac:	557d                	li	a0,-1
}
    80004aae:	8082                	ret
      return -1;
    80004ab0:	557d                	li	a0,-1
    80004ab2:	bf6d                	j	80004a6c <filewrite+0x10e>
    80004ab4:	557d                	li	a0,-1
    80004ab6:	bf5d                	j	80004a6c <filewrite+0x10e>

0000000080004ab8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ab8:	7179                	addi	sp,sp,-48
    80004aba:	f406                	sd	ra,40(sp)
    80004abc:	f022                	sd	s0,32(sp)
    80004abe:	ec26                	sd	s1,24(sp)
    80004ac0:	e84a                	sd	s2,16(sp)
    80004ac2:	e44e                	sd	s3,8(sp)
    80004ac4:	e052                	sd	s4,0(sp)
    80004ac6:	1800                	addi	s0,sp,48
    80004ac8:	84aa                	mv	s1,a0
    80004aca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004acc:	0005b023          	sd	zero,0(a1)
    80004ad0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	bd2080e7          	jalr	-1070(ra) # 800046a6 <filealloc>
    80004adc:	e088                	sd	a0,0(s1)
    80004ade:	c551                	beqz	a0,80004b6a <pipealloc+0xb2>
    80004ae0:	00000097          	auipc	ra,0x0
    80004ae4:	bc6080e7          	jalr	-1082(ra) # 800046a6 <filealloc>
    80004ae8:	00aa3023          	sd	a0,0(s4)
    80004aec:	c92d                	beqz	a0,80004b5e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	0ac080e7          	jalr	172(ra) # 80000b9a <kalloc>
    80004af6:	892a                	mv	s2,a0
    80004af8:	c125                	beqz	a0,80004b58 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004afa:	4985                	li	s3,1
    80004afc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b00:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b04:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b08:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b0c:	00004597          	auipc	a1,0x4
    80004b10:	bac58593          	addi	a1,a1,-1108 # 800086b8 <syscalls+0x288>
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	1a6080e7          	jalr	422(ra) # 80000cba <initlock>
  (*f0)->type = FD_PIPE;
    80004b1c:	609c                	ld	a5,0(s1)
    80004b1e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b22:	609c                	ld	a5,0(s1)
    80004b24:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b28:	609c                	ld	a5,0(s1)
    80004b2a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b2e:	609c                	ld	a5,0(s1)
    80004b30:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b34:	000a3783          	ld	a5,0(s4)
    80004b38:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b3c:	000a3783          	ld	a5,0(s4)
    80004b40:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b44:	000a3783          	ld	a5,0(s4)
    80004b48:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b4c:	000a3783          	ld	a5,0(s4)
    80004b50:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b54:	4501                	li	a0,0
    80004b56:	a025                	j	80004b7e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b58:	6088                	ld	a0,0(s1)
    80004b5a:	e501                	bnez	a0,80004b62 <pipealloc+0xaa>
    80004b5c:	a039                	j	80004b6a <pipealloc+0xb2>
    80004b5e:	6088                	ld	a0,0(s1)
    80004b60:	c51d                	beqz	a0,80004b8e <pipealloc+0xd6>
    fileclose(*f0);
    80004b62:	00000097          	auipc	ra,0x0
    80004b66:	c00080e7          	jalr	-1024(ra) # 80004762 <fileclose>
  if(*f1)
    80004b6a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b6e:	557d                	li	a0,-1
  if(*f1)
    80004b70:	c799                	beqz	a5,80004b7e <pipealloc+0xc6>
    fileclose(*f1);
    80004b72:	853e                	mv	a0,a5
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	bee080e7          	jalr	-1042(ra) # 80004762 <fileclose>
  return -1;
    80004b7c:	557d                	li	a0,-1
}
    80004b7e:	70a2                	ld	ra,40(sp)
    80004b80:	7402                	ld	s0,32(sp)
    80004b82:	64e2                	ld	s1,24(sp)
    80004b84:	6942                	ld	s2,16(sp)
    80004b86:	69a2                	ld	s3,8(sp)
    80004b88:	6a02                	ld	s4,0(sp)
    80004b8a:	6145                	addi	sp,sp,48
    80004b8c:	8082                	ret
  return -1;
    80004b8e:	557d                	li	a0,-1
    80004b90:	b7fd                	j	80004b7e <pipealloc+0xc6>

0000000080004b92 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b92:	1101                	addi	sp,sp,-32
    80004b94:	ec06                	sd	ra,24(sp)
    80004b96:	e822                	sd	s0,16(sp)
    80004b98:	e426                	sd	s1,8(sp)
    80004b9a:	e04a                	sd	s2,0(sp)
    80004b9c:	1000                	addi	s0,sp,32
    80004b9e:	84aa                	mv	s1,a0
    80004ba0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	1a8080e7          	jalr	424(ra) # 80000d4a <acquire>
  if(writable){
    80004baa:	02090d63          	beqz	s2,80004be4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bb2:	21848513          	addi	a0,s1,536
    80004bb6:	ffffe097          	auipc	ra,0xffffe
    80004bba:	a3a080e7          	jalr	-1478(ra) # 800025f0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bbe:	2204b783          	ld	a5,544(s1)
    80004bc2:	eb95                	bnez	a5,80004bf6 <pipeclose+0x64>
    release(&pi->lock);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	238080e7          	jalr	568(ra) # 80000dfe <release>
    kfree((char*)pi);
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	e42080e7          	jalr	-446(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004bd8:	60e2                	ld	ra,24(sp)
    80004bda:	6442                	ld	s0,16(sp)
    80004bdc:	64a2                	ld	s1,8(sp)
    80004bde:	6902                	ld	s2,0(sp)
    80004be0:	6105                	addi	sp,sp,32
    80004be2:	8082                	ret
    pi->readopen = 0;
    80004be4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004be8:	21c48513          	addi	a0,s1,540
    80004bec:	ffffe097          	auipc	ra,0xffffe
    80004bf0:	a04080e7          	jalr	-1532(ra) # 800025f0 <wakeup>
    80004bf4:	b7e9                	j	80004bbe <pipeclose+0x2c>
    release(&pi->lock);
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	206080e7          	jalr	518(ra) # 80000dfe <release>
}
    80004c00:	bfe1                	j	80004bd8 <pipeclose+0x46>

0000000080004c02 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c02:	711d                	addi	sp,sp,-96
    80004c04:	ec86                	sd	ra,88(sp)
    80004c06:	e8a2                	sd	s0,80(sp)
    80004c08:	e4a6                	sd	s1,72(sp)
    80004c0a:	e0ca                	sd	s2,64(sp)
    80004c0c:	fc4e                	sd	s3,56(sp)
    80004c0e:	f852                	sd	s4,48(sp)
    80004c10:	f456                	sd	s5,40(sp)
    80004c12:	f05a                	sd	s6,32(sp)
    80004c14:	ec5e                	sd	s7,24(sp)
    80004c16:	e862                	sd	s8,16(sp)
    80004c18:	1080                	addi	s0,sp,96
    80004c1a:	84aa                	mv	s1,a0
    80004c1c:	8b2e                	mv	s6,a1
    80004c1e:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	03c080e7          	jalr	60(ra) # 80001c5c <myproc>
    80004c28:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	11e080e7          	jalr	286(ra) # 80000d4a <acquire>
  for(i = 0; i < n; i++){
    80004c34:	09505763          	blez	s5,80004cc2 <pipewrite+0xc0>
    80004c38:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c3a:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c3e:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c42:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c44:	2184a783          	lw	a5,536(s1)
    80004c48:	21c4a703          	lw	a4,540(s1)
    80004c4c:	2007879b          	addiw	a5,a5,512
    80004c50:	02f71b63          	bne	a4,a5,80004c86 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004c54:	2204a783          	lw	a5,544(s1)
    80004c58:	c3d1                	beqz	a5,80004cdc <pipewrite+0xda>
    80004c5a:	03092783          	lw	a5,48(s2)
    80004c5e:	efbd                	bnez	a5,80004cdc <pipewrite+0xda>
      wakeup(&pi->nread);
    80004c60:	8552                	mv	a0,s4
    80004c62:	ffffe097          	auipc	ra,0xffffe
    80004c66:	98e080e7          	jalr	-1650(ra) # 800025f0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c6a:	85a6                	mv	a1,s1
    80004c6c:	854e                	mv	a0,s3
    80004c6e:	ffffe097          	auipc	ra,0xffffe
    80004c72:	802080e7          	jalr	-2046(ra) # 80002470 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c76:	2184a783          	lw	a5,536(s1)
    80004c7a:	21c4a703          	lw	a4,540(s1)
    80004c7e:	2007879b          	addiw	a5,a5,512
    80004c82:	fcf709e3          	beq	a4,a5,80004c54 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c86:	4685                	li	a3,1
    80004c88:	865a                	mv	a2,s6
    80004c8a:	faf40593          	addi	a1,s0,-81
    80004c8e:	05093503          	ld	a0,80(s2)
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	b80080e7          	jalr	-1152(ra) # 80001812 <copyin>
    80004c9a:	03850563          	beq	a0,s8,80004cc4 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c9e:	21c4a783          	lw	a5,540(s1)
    80004ca2:	0017871b          	addiw	a4,a5,1
    80004ca6:	20e4ae23          	sw	a4,540(s1)
    80004caa:	1ff7f793          	andi	a5,a5,511
    80004cae:	97a6                	add	a5,a5,s1
    80004cb0:	faf44703          	lbu	a4,-81(s0)
    80004cb4:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004cb8:	2b85                	addiw	s7,s7,1
    80004cba:	0b05                	addi	s6,s6,1
    80004cbc:	f97a94e3          	bne	s5,s7,80004c44 <pipewrite+0x42>
    80004cc0:	a011                	j	80004cc4 <pipewrite+0xc2>
    80004cc2:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004cc4:	21848513          	addi	a0,s1,536
    80004cc8:	ffffe097          	auipc	ra,0xffffe
    80004ccc:	928080e7          	jalr	-1752(ra) # 800025f0 <wakeup>
  release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	12c080e7          	jalr	300(ra) # 80000dfe <release>
  return i;
    80004cda:	a039                	j	80004ce8 <pipewrite+0xe6>
        release(&pi->lock);
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	120080e7          	jalr	288(ra) # 80000dfe <release>
        return -1;
    80004ce6:	5bfd                	li	s7,-1
}
    80004ce8:	855e                	mv	a0,s7
    80004cea:	60e6                	ld	ra,88(sp)
    80004cec:	6446                	ld	s0,80(sp)
    80004cee:	64a6                	ld	s1,72(sp)
    80004cf0:	6906                	ld	s2,64(sp)
    80004cf2:	79e2                	ld	s3,56(sp)
    80004cf4:	7a42                	ld	s4,48(sp)
    80004cf6:	7aa2                	ld	s5,40(sp)
    80004cf8:	7b02                	ld	s6,32(sp)
    80004cfa:	6be2                	ld	s7,24(sp)
    80004cfc:	6c42                	ld	s8,16(sp)
    80004cfe:	6125                	addi	sp,sp,96
    80004d00:	8082                	ret

0000000080004d02 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d02:	715d                	addi	sp,sp,-80
    80004d04:	e486                	sd	ra,72(sp)
    80004d06:	e0a2                	sd	s0,64(sp)
    80004d08:	fc26                	sd	s1,56(sp)
    80004d0a:	f84a                	sd	s2,48(sp)
    80004d0c:	f44e                	sd	s3,40(sp)
    80004d0e:	f052                	sd	s4,32(sp)
    80004d10:	ec56                	sd	s5,24(sp)
    80004d12:	e85a                	sd	s6,16(sp)
    80004d14:	0880                	addi	s0,sp,80
    80004d16:	84aa                	mv	s1,a0
    80004d18:	892e                	mv	s2,a1
    80004d1a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	f40080e7          	jalr	-192(ra) # 80001c5c <myproc>
    80004d24:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d26:	8526                	mv	a0,s1
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	022080e7          	jalr	34(ra) # 80000d4a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d30:	2184a703          	lw	a4,536(s1)
    80004d34:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d38:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d3c:	02f71463          	bne	a4,a5,80004d64 <piperead+0x62>
    80004d40:	2244a783          	lw	a5,548(s1)
    80004d44:	c385                	beqz	a5,80004d64 <piperead+0x62>
    if(pr->killed){
    80004d46:	030a2783          	lw	a5,48(s4)
    80004d4a:	ebc1                	bnez	a5,80004dda <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d4c:	85a6                	mv	a1,s1
    80004d4e:	854e                	mv	a0,s3
    80004d50:	ffffd097          	auipc	ra,0xffffd
    80004d54:	720080e7          	jalr	1824(ra) # 80002470 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d58:	2184a703          	lw	a4,536(s1)
    80004d5c:	21c4a783          	lw	a5,540(s1)
    80004d60:	fef700e3          	beq	a4,a5,80004d40 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d64:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d66:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d68:	05505363          	blez	s5,80004dae <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004d6c:	2184a783          	lw	a5,536(s1)
    80004d70:	21c4a703          	lw	a4,540(s1)
    80004d74:	02f70d63          	beq	a4,a5,80004dae <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d78:	0017871b          	addiw	a4,a5,1
    80004d7c:	20e4ac23          	sw	a4,536(s1)
    80004d80:	1ff7f793          	andi	a5,a5,511
    80004d84:	97a6                	add	a5,a5,s1
    80004d86:	0187c783          	lbu	a5,24(a5)
    80004d8a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d8e:	4685                	li	a3,1
    80004d90:	fbf40613          	addi	a2,s0,-65
    80004d94:	85ca                	mv	a1,s2
    80004d96:	050a3503          	ld	a0,80(s4)
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	cd0080e7          	jalr	-816(ra) # 80001a6a <copyout>
    80004da2:	01650663          	beq	a0,s6,80004dae <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004da6:	2985                	addiw	s3,s3,1
    80004da8:	0905                	addi	s2,s2,1
    80004daa:	fd3a91e3          	bne	s5,s3,80004d6c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dae:	21c48513          	addi	a0,s1,540
    80004db2:	ffffe097          	auipc	ra,0xffffe
    80004db6:	83e080e7          	jalr	-1986(ra) # 800025f0 <wakeup>
  release(&pi->lock);
    80004dba:	8526                	mv	a0,s1
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	042080e7          	jalr	66(ra) # 80000dfe <release>
  return i;
}
    80004dc4:	854e                	mv	a0,s3
    80004dc6:	60a6                	ld	ra,72(sp)
    80004dc8:	6406                	ld	s0,64(sp)
    80004dca:	74e2                	ld	s1,56(sp)
    80004dcc:	7942                	ld	s2,48(sp)
    80004dce:	79a2                	ld	s3,40(sp)
    80004dd0:	7a02                	ld	s4,32(sp)
    80004dd2:	6ae2                	ld	s5,24(sp)
    80004dd4:	6b42                	ld	s6,16(sp)
    80004dd6:	6161                	addi	sp,sp,80
    80004dd8:	8082                	ret
      release(&pi->lock);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	022080e7          	jalr	34(ra) # 80000dfe <release>
      return -1;
    80004de4:	59fd                	li	s3,-1
    80004de6:	bff9                	j	80004dc4 <piperead+0xc2>

0000000080004de8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004de8:	de010113          	addi	sp,sp,-544
    80004dec:	20113c23          	sd	ra,536(sp)
    80004df0:	20813823          	sd	s0,528(sp)
    80004df4:	20913423          	sd	s1,520(sp)
    80004df8:	21213023          	sd	s2,512(sp)
    80004dfc:	ffce                	sd	s3,504(sp)
    80004dfe:	fbd2                	sd	s4,496(sp)
    80004e00:	f7d6                	sd	s5,488(sp)
    80004e02:	f3da                	sd	s6,480(sp)
    80004e04:	efde                	sd	s7,472(sp)
    80004e06:	ebe2                	sd	s8,464(sp)
    80004e08:	e7e6                	sd	s9,456(sp)
    80004e0a:	e3ea                	sd	s10,448(sp)
    80004e0c:	ff6e                	sd	s11,440(sp)
    80004e0e:	1400                	addi	s0,sp,544
    80004e10:	892a                	mv	s2,a0
    80004e12:	dea43423          	sd	a0,-536(s0)
    80004e16:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e1a:	ffffd097          	auipc	ra,0xffffd
    80004e1e:	e42080e7          	jalr	-446(ra) # 80001c5c <myproc>
    80004e22:	84aa                	mv	s1,a0

  begin_op();
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	46c080e7          	jalr	1132(ra) # 80004290 <begin_op>

  if((ip = namei(path)) == 0){
    80004e2c:	854a                	mv	a0,s2
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	256080e7          	jalr	598(ra) # 80004084 <namei>
    80004e36:	c93d                	beqz	a0,80004eac <exec+0xc4>
    80004e38:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	a96080e7          	jalr	-1386(ra) # 800038d0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e42:	04000713          	li	a4,64
    80004e46:	4681                	li	a3,0
    80004e48:	e4840613          	addi	a2,s0,-440
    80004e4c:	4581                	li	a1,0
    80004e4e:	8556                	mv	a0,s5
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	d34080e7          	jalr	-716(ra) # 80003b84 <readi>
    80004e58:	04000793          	li	a5,64
    80004e5c:	00f51a63          	bne	a0,a5,80004e70 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e60:	e4842703          	lw	a4,-440(s0)
    80004e64:	464c47b7          	lui	a5,0x464c4
    80004e68:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e6c:	04f70663          	beq	a4,a5,80004eb8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e70:	8556                	mv	a0,s5
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	cc0080e7          	jalr	-832(ra) # 80003b32 <iunlockput>
    end_op();
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	496080e7          	jalr	1174(ra) # 80004310 <end_op>
  }
  return -1;
    80004e82:	557d                	li	a0,-1
}
    80004e84:	21813083          	ld	ra,536(sp)
    80004e88:	21013403          	ld	s0,528(sp)
    80004e8c:	20813483          	ld	s1,520(sp)
    80004e90:	20013903          	ld	s2,512(sp)
    80004e94:	79fe                	ld	s3,504(sp)
    80004e96:	7a5e                	ld	s4,496(sp)
    80004e98:	7abe                	ld	s5,488(sp)
    80004e9a:	7b1e                	ld	s6,480(sp)
    80004e9c:	6bfe                	ld	s7,472(sp)
    80004e9e:	6c5e                	ld	s8,464(sp)
    80004ea0:	6cbe                	ld	s9,456(sp)
    80004ea2:	6d1e                	ld	s10,448(sp)
    80004ea4:	7dfa                	ld	s11,440(sp)
    80004ea6:	22010113          	addi	sp,sp,544
    80004eaa:	8082                	ret
    end_op();
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	464080e7          	jalr	1124(ra) # 80004310 <end_op>
    return -1;
    80004eb4:	557d                	li	a0,-1
    80004eb6:	b7f9                	j	80004e84 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eb8:	8526                	mv	a0,s1
    80004eba:	ffffd097          	auipc	ra,0xffffd
    80004ebe:	e66080e7          	jalr	-410(ra) # 80001d20 <proc_pagetable>
    80004ec2:	8b2a                	mv	s6,a0
    80004ec4:	d555                	beqz	a0,80004e70 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ec6:	e6842783          	lw	a5,-408(s0)
    80004eca:	e8045703          	lhu	a4,-384(s0)
    80004ece:	c735                	beqz	a4,80004f3a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ed0:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed2:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ed6:	6a05                	lui	s4,0x1
    80004ed8:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004edc:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004ee0:	6d85                	lui	s11,0x1
    80004ee2:	7d7d                	lui	s10,0xfffff
    80004ee4:	ac1d                	j	8000511a <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ee6:	00003517          	auipc	a0,0x3
    80004eea:	7da50513          	addi	a0,a0,2010 # 800086c0 <syscalls+0x290>
    80004eee:	ffffb097          	auipc	ra,0xffffb
    80004ef2:	654080e7          	jalr	1620(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ef6:	874a                	mv	a4,s2
    80004ef8:	009c86bb          	addw	a3,s9,s1
    80004efc:	4581                	li	a1,0
    80004efe:	8556                	mv	a0,s5
    80004f00:	fffff097          	auipc	ra,0xfffff
    80004f04:	c84080e7          	jalr	-892(ra) # 80003b84 <readi>
    80004f08:	2501                	sext.w	a0,a0
    80004f0a:	1aa91863          	bne	s2,a0,800050ba <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004f0e:	009d84bb          	addw	s1,s11,s1
    80004f12:	013d09bb          	addw	s3,s10,s3
    80004f16:	1f74f263          	bgeu	s1,s7,800050fa <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004f1a:	02049593          	slli	a1,s1,0x20
    80004f1e:	9181                	srli	a1,a1,0x20
    80004f20:	95e2                	add	a1,a1,s8
    80004f22:	855a                	mv	a0,s6
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	2b0080e7          	jalr	688(ra) # 800011d4 <walkaddr>
    80004f2c:	862a                	mv	a2,a0
    if(pa == 0)
    80004f2e:	dd45                	beqz	a0,80004ee6 <exec+0xfe>
      n = PGSIZE;
    80004f30:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f32:	fd49f2e3          	bgeu	s3,s4,80004ef6 <exec+0x10e>
      n = sz - i;
    80004f36:	894e                	mv	s2,s3
    80004f38:	bf7d                	j	80004ef6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f3a:	4481                	li	s1,0
  iunlockput(ip);
    80004f3c:	8556                	mv	a0,s5
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	bf4080e7          	jalr	-1036(ra) # 80003b32 <iunlockput>
  end_op();
    80004f46:	fffff097          	auipc	ra,0xfffff
    80004f4a:	3ca080e7          	jalr	970(ra) # 80004310 <end_op>
  p = myproc();
    80004f4e:	ffffd097          	auipc	ra,0xffffd
    80004f52:	d0e080e7          	jalr	-754(ra) # 80001c5c <myproc>
    80004f56:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f58:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f5c:	6785                	lui	a5,0x1
    80004f5e:	17fd                	addi	a5,a5,-1
    80004f60:	94be                	add	s1,s1,a5
    80004f62:	77fd                	lui	a5,0xfffff
    80004f64:	8fe5                	and	a5,a5,s1
    80004f66:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f6a:	6609                	lui	a2,0x2
    80004f6c:	963e                	add	a2,a2,a5
    80004f6e:	85be                	mv	a1,a5
    80004f70:	855a                	mv	a0,s6
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	646080e7          	jalr	1606(ra) # 800015b8 <uvmalloc>
    80004f7a:	8c2a                	mv	s8,a0
  ip = 0;
    80004f7c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f7e:	12050e63          	beqz	a0,800050ba <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f82:	75f9                	lui	a1,0xffffe
    80004f84:	95aa                	add	a1,a1,a0
    80004f86:	855a                	mv	a0,s6
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	858080e7          	jalr	-1960(ra) # 800017e0 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f90:	7afd                	lui	s5,0xfffff
    80004f92:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f94:	df043783          	ld	a5,-528(s0)
    80004f98:	6388                	ld	a0,0(a5)
    80004f9a:	c925                	beqz	a0,8000500a <exec+0x222>
    80004f9c:	e8840993          	addi	s3,s0,-376
    80004fa0:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004fa4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fa6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	022080e7          	jalr	34(ra) # 80000fca <strlen>
    80004fb0:	0015079b          	addiw	a5,a0,1
    80004fb4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fb8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fbc:	13596363          	bltu	s2,s5,800050e2 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fc0:	df043d83          	ld	s11,-528(s0)
    80004fc4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004fc8:	8552                	mv	a0,s4
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	000080e7          	jalr	ra # 80000fca <strlen>
    80004fd2:	0015069b          	addiw	a3,a0,1
    80004fd6:	8652                	mv	a2,s4
    80004fd8:	85ca                	mv	a1,s2
    80004fda:	855a                	mv	a0,s6
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	a8e080e7          	jalr	-1394(ra) # 80001a6a <copyout>
    80004fe4:	10054363          	bltz	a0,800050ea <exec+0x302>
    ustack[argc] = sp;
    80004fe8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fec:	0485                	addi	s1,s1,1
    80004fee:	008d8793          	addi	a5,s11,8
    80004ff2:	def43823          	sd	a5,-528(s0)
    80004ff6:	008db503          	ld	a0,8(s11)
    80004ffa:	c911                	beqz	a0,8000500e <exec+0x226>
    if(argc >= MAXARG)
    80004ffc:	09a1                	addi	s3,s3,8
    80004ffe:	fb3c95e3          	bne	s9,s3,80004fa8 <exec+0x1c0>
  sz = sz1;
    80005002:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005006:	4a81                	li	s5,0
    80005008:	a84d                	j	800050ba <exec+0x2d2>
  sp = sz;
    8000500a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000500c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000500e:	00349793          	slli	a5,s1,0x3
    80005012:	f9040713          	addi	a4,s0,-112
    80005016:	97ba                	add	a5,a5,a4
    80005018:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7fdb8ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000501c:	00148693          	addi	a3,s1,1
    80005020:	068e                	slli	a3,a3,0x3
    80005022:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005026:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000502a:	01597663          	bgeu	s2,s5,80005036 <exec+0x24e>
  sz = sz1;
    8000502e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005032:	4a81                	li	s5,0
    80005034:	a059                	j	800050ba <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005036:	e8840613          	addi	a2,s0,-376
    8000503a:	85ca                	mv	a1,s2
    8000503c:	855a                	mv	a0,s6
    8000503e:	ffffd097          	auipc	ra,0xffffd
    80005042:	a2c080e7          	jalr	-1492(ra) # 80001a6a <copyout>
    80005046:	0a054663          	bltz	a0,800050f2 <exec+0x30a>
  p->trapframe->a1 = sp;
    8000504a:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000504e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005052:	de843783          	ld	a5,-536(s0)
    80005056:	0007c703          	lbu	a4,0(a5)
    8000505a:	cf11                	beqz	a4,80005076 <exec+0x28e>
    8000505c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000505e:	02f00693          	li	a3,47
    80005062:	a039                	j	80005070 <exec+0x288>
      last = s+1;
    80005064:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005068:	0785                	addi	a5,a5,1
    8000506a:	fff7c703          	lbu	a4,-1(a5)
    8000506e:	c701                	beqz	a4,80005076 <exec+0x28e>
    if(*s == '/')
    80005070:	fed71ce3          	bne	a4,a3,80005068 <exec+0x280>
    80005074:	bfc5                	j	80005064 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005076:	4641                	li	a2,16
    80005078:	de843583          	ld	a1,-536(s0)
    8000507c:	158b8513          	addi	a0,s7,344
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	f18080e7          	jalr	-232(ra) # 80000f98 <safestrcpy>
  oldpagetable = p->pagetable;
    80005088:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000508c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005090:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005094:	058bb783          	ld	a5,88(s7)
    80005098:	e6043703          	ld	a4,-416(s0)
    8000509c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000509e:	058bb783          	ld	a5,88(s7)
    800050a2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050a6:	85ea                	mv	a1,s10
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	d14080e7          	jalr	-748(ra) # 80001dbc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050b0:	0004851b          	sext.w	a0,s1
    800050b4:	bbc1                	j	80004e84 <exec+0x9c>
    800050b6:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050ba:	df843583          	ld	a1,-520(s0)
    800050be:	855a                	mv	a0,s6
    800050c0:	ffffd097          	auipc	ra,0xffffd
    800050c4:	cfc080e7          	jalr	-772(ra) # 80001dbc <proc_freepagetable>
  if(ip){
    800050c8:	da0a94e3          	bnez	s5,80004e70 <exec+0x88>
  return -1;
    800050cc:	557d                	li	a0,-1
    800050ce:	bb5d                	j	80004e84 <exec+0x9c>
    800050d0:	de943c23          	sd	s1,-520(s0)
    800050d4:	b7dd                	j	800050ba <exec+0x2d2>
    800050d6:	de943c23          	sd	s1,-520(s0)
    800050da:	b7c5                	j	800050ba <exec+0x2d2>
    800050dc:	de943c23          	sd	s1,-520(s0)
    800050e0:	bfe9                	j	800050ba <exec+0x2d2>
  sz = sz1;
    800050e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050e6:	4a81                	li	s5,0
    800050e8:	bfc9                	j	800050ba <exec+0x2d2>
  sz = sz1;
    800050ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ee:	4a81                	li	s5,0
    800050f0:	b7e9                	j	800050ba <exec+0x2d2>
  sz = sz1;
    800050f2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050f6:	4a81                	li	s5,0
    800050f8:	b7c9                	j	800050ba <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050fa:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050fe:	e0843783          	ld	a5,-504(s0)
    80005102:	0017869b          	addiw	a3,a5,1
    80005106:	e0d43423          	sd	a3,-504(s0)
    8000510a:	e0043783          	ld	a5,-512(s0)
    8000510e:	0387879b          	addiw	a5,a5,56
    80005112:	e8045703          	lhu	a4,-384(s0)
    80005116:	e2e6d3e3          	bge	a3,a4,80004f3c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000511a:	2781                	sext.w	a5,a5
    8000511c:	e0f43023          	sd	a5,-512(s0)
    80005120:	03800713          	li	a4,56
    80005124:	86be                	mv	a3,a5
    80005126:	e1040613          	addi	a2,s0,-496
    8000512a:	4581                	li	a1,0
    8000512c:	8556                	mv	a0,s5
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	a56080e7          	jalr	-1450(ra) # 80003b84 <readi>
    80005136:	03800793          	li	a5,56
    8000513a:	f6f51ee3          	bne	a0,a5,800050b6 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000513e:	e1042783          	lw	a5,-496(s0)
    80005142:	4705                	li	a4,1
    80005144:	fae79de3          	bne	a5,a4,800050fe <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005148:	e3843603          	ld	a2,-456(s0)
    8000514c:	e3043783          	ld	a5,-464(s0)
    80005150:	f8f660e3          	bltu	a2,a5,800050d0 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005154:	e2043783          	ld	a5,-480(s0)
    80005158:	963e                	add	a2,a2,a5
    8000515a:	f6f66ee3          	bltu	a2,a5,800050d6 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000515e:	85a6                	mv	a1,s1
    80005160:	855a                	mv	a0,s6
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	456080e7          	jalr	1110(ra) # 800015b8 <uvmalloc>
    8000516a:	dea43c23          	sd	a0,-520(s0)
    8000516e:	d53d                	beqz	a0,800050dc <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005170:	e2043c03          	ld	s8,-480(s0)
    80005174:	de043783          	ld	a5,-544(s0)
    80005178:	00fc77b3          	and	a5,s8,a5
    8000517c:	ff9d                	bnez	a5,800050ba <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000517e:	e1842c83          	lw	s9,-488(s0)
    80005182:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005186:	f60b8ae3          	beqz	s7,800050fa <exec+0x312>
    8000518a:	89de                	mv	s3,s7
    8000518c:	4481                	li	s1,0
    8000518e:	b371                	j	80004f1a <exec+0x132>

0000000080005190 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005190:	7179                	addi	sp,sp,-48
    80005192:	f406                	sd	ra,40(sp)
    80005194:	f022                	sd	s0,32(sp)
    80005196:	ec26                	sd	s1,24(sp)
    80005198:	e84a                	sd	s2,16(sp)
    8000519a:	1800                	addi	s0,sp,48
    8000519c:	892e                	mv	s2,a1
    8000519e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051a0:	fdc40593          	addi	a1,s0,-36
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	bbc080e7          	jalr	-1092(ra) # 80002d60 <argint>
    800051ac:	04054063          	bltz	a0,800051ec <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051b0:	fdc42703          	lw	a4,-36(s0)
    800051b4:	47bd                	li	a5,15
    800051b6:	02e7ed63          	bltu	a5,a4,800051f0 <argfd+0x60>
    800051ba:	ffffd097          	auipc	ra,0xffffd
    800051be:	aa2080e7          	jalr	-1374(ra) # 80001c5c <myproc>
    800051c2:	fdc42703          	lw	a4,-36(s0)
    800051c6:	01a70793          	addi	a5,a4,26
    800051ca:	078e                	slli	a5,a5,0x3
    800051cc:	953e                	add	a0,a0,a5
    800051ce:	611c                	ld	a5,0(a0)
    800051d0:	c395                	beqz	a5,800051f4 <argfd+0x64>
    return -1;
  if(pfd)
    800051d2:	00090463          	beqz	s2,800051da <argfd+0x4a>
    *pfd = fd;
    800051d6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051da:	4501                	li	a0,0
  if(pf)
    800051dc:	c091                	beqz	s1,800051e0 <argfd+0x50>
    *pf = f;
    800051de:	e09c                	sd	a5,0(s1)
}
    800051e0:	70a2                	ld	ra,40(sp)
    800051e2:	7402                	ld	s0,32(sp)
    800051e4:	64e2                	ld	s1,24(sp)
    800051e6:	6942                	ld	s2,16(sp)
    800051e8:	6145                	addi	sp,sp,48
    800051ea:	8082                	ret
    return -1;
    800051ec:	557d                	li	a0,-1
    800051ee:	bfcd                	j	800051e0 <argfd+0x50>
    return -1;
    800051f0:	557d                	li	a0,-1
    800051f2:	b7fd                	j	800051e0 <argfd+0x50>
    800051f4:	557d                	li	a0,-1
    800051f6:	b7ed                	j	800051e0 <argfd+0x50>

00000000800051f8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051f8:	1101                	addi	sp,sp,-32
    800051fa:	ec06                	sd	ra,24(sp)
    800051fc:	e822                	sd	s0,16(sp)
    800051fe:	e426                	sd	s1,8(sp)
    80005200:	1000                	addi	s0,sp,32
    80005202:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005204:	ffffd097          	auipc	ra,0xffffd
    80005208:	a58080e7          	jalr	-1448(ra) # 80001c5c <myproc>
    8000520c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000520e:	0d050793          	addi	a5,a0,208
    80005212:	4501                	li	a0,0
    80005214:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005216:	6398                	ld	a4,0(a5)
    80005218:	cb19                	beqz	a4,8000522e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000521a:	2505                	addiw	a0,a0,1
    8000521c:	07a1                	addi	a5,a5,8
    8000521e:	fed51ce3          	bne	a0,a3,80005216 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005222:	557d                	li	a0,-1
}
    80005224:	60e2                	ld	ra,24(sp)
    80005226:	6442                	ld	s0,16(sp)
    80005228:	64a2                	ld	s1,8(sp)
    8000522a:	6105                	addi	sp,sp,32
    8000522c:	8082                	ret
      p->ofile[fd] = f;
    8000522e:	01a50793          	addi	a5,a0,26
    80005232:	078e                	slli	a5,a5,0x3
    80005234:	963e                	add	a2,a2,a5
    80005236:	e204                	sd	s1,0(a2)
      return fd;
    80005238:	b7f5                	j	80005224 <fdalloc+0x2c>

000000008000523a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000523a:	715d                	addi	sp,sp,-80
    8000523c:	e486                	sd	ra,72(sp)
    8000523e:	e0a2                	sd	s0,64(sp)
    80005240:	fc26                	sd	s1,56(sp)
    80005242:	f84a                	sd	s2,48(sp)
    80005244:	f44e                	sd	s3,40(sp)
    80005246:	f052                	sd	s4,32(sp)
    80005248:	ec56                	sd	s5,24(sp)
    8000524a:	0880                	addi	s0,sp,80
    8000524c:	89ae                	mv	s3,a1
    8000524e:	8ab2                	mv	s5,a2
    80005250:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005252:	fb040593          	addi	a1,s0,-80
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	e4c080e7          	jalr	-436(ra) # 800040a2 <nameiparent>
    8000525e:	892a                	mv	s2,a0
    80005260:	12050e63          	beqz	a0,8000539c <create+0x162>
    return 0;

  ilock(dp);
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	66c080e7          	jalr	1644(ra) # 800038d0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000526c:	4601                	li	a2,0
    8000526e:	fb040593          	addi	a1,s0,-80
    80005272:	854a                	mv	a0,s2
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	b3e080e7          	jalr	-1218(ra) # 80003db2 <dirlookup>
    8000527c:	84aa                	mv	s1,a0
    8000527e:	c921                	beqz	a0,800052ce <create+0x94>
    iunlockput(dp);
    80005280:	854a                	mv	a0,s2
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	8b0080e7          	jalr	-1872(ra) # 80003b32 <iunlockput>
    ilock(ip);
    8000528a:	8526                	mv	a0,s1
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	644080e7          	jalr	1604(ra) # 800038d0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005294:	2981                	sext.w	s3,s3
    80005296:	4789                	li	a5,2
    80005298:	02f99463          	bne	s3,a5,800052c0 <create+0x86>
    8000529c:	0444d783          	lhu	a5,68(s1)
    800052a0:	37f9                	addiw	a5,a5,-2
    800052a2:	17c2                	slli	a5,a5,0x30
    800052a4:	93c1                	srli	a5,a5,0x30
    800052a6:	4705                	li	a4,1
    800052a8:	00f76c63          	bltu	a4,a5,800052c0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052ac:	8526                	mv	a0,s1
    800052ae:	60a6                	ld	ra,72(sp)
    800052b0:	6406                	ld	s0,64(sp)
    800052b2:	74e2                	ld	s1,56(sp)
    800052b4:	7942                	ld	s2,48(sp)
    800052b6:	79a2                	ld	s3,40(sp)
    800052b8:	7a02                	ld	s4,32(sp)
    800052ba:	6ae2                	ld	s5,24(sp)
    800052bc:	6161                	addi	sp,sp,80
    800052be:	8082                	ret
    iunlockput(ip);
    800052c0:	8526                	mv	a0,s1
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	870080e7          	jalr	-1936(ra) # 80003b32 <iunlockput>
    return 0;
    800052ca:	4481                	li	s1,0
    800052cc:	b7c5                	j	800052ac <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052ce:	85ce                	mv	a1,s3
    800052d0:	00092503          	lw	a0,0(s2)
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	464080e7          	jalr	1124(ra) # 80003738 <ialloc>
    800052dc:	84aa                	mv	s1,a0
    800052de:	c521                	beqz	a0,80005326 <create+0xec>
  ilock(ip);
    800052e0:	ffffe097          	auipc	ra,0xffffe
    800052e4:	5f0080e7          	jalr	1520(ra) # 800038d0 <ilock>
  ip->major = major;
    800052e8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052ec:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052f0:	4a05                	li	s4,1
    800052f2:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800052f6:	8526                	mv	a0,s1
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	50e080e7          	jalr	1294(ra) # 80003806 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005300:	2981                	sext.w	s3,s3
    80005302:	03498a63          	beq	s3,s4,80005336 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005306:	40d0                	lw	a2,4(s1)
    80005308:	fb040593          	addi	a1,s0,-80
    8000530c:	854a                	mv	a0,s2
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	cb4080e7          	jalr	-844(ra) # 80003fc2 <dirlink>
    80005316:	06054b63          	bltz	a0,8000538c <create+0x152>
  iunlockput(dp);
    8000531a:	854a                	mv	a0,s2
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	816080e7          	jalr	-2026(ra) # 80003b32 <iunlockput>
  return ip;
    80005324:	b761                	j	800052ac <create+0x72>
    panic("create: ialloc");
    80005326:	00003517          	auipc	a0,0x3
    8000532a:	3ba50513          	addi	a0,a0,954 # 800086e0 <syscalls+0x2b0>
    8000532e:	ffffb097          	auipc	ra,0xffffb
    80005332:	214080e7          	jalr	532(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    80005336:	04a95783          	lhu	a5,74(s2)
    8000533a:	2785                	addiw	a5,a5,1
    8000533c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005340:	854a                	mv	a0,s2
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	4c4080e7          	jalr	1220(ra) # 80003806 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000534a:	40d0                	lw	a2,4(s1)
    8000534c:	00003597          	auipc	a1,0x3
    80005350:	3a458593          	addi	a1,a1,932 # 800086f0 <syscalls+0x2c0>
    80005354:	8526                	mv	a0,s1
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	c6c080e7          	jalr	-916(ra) # 80003fc2 <dirlink>
    8000535e:	00054f63          	bltz	a0,8000537c <create+0x142>
    80005362:	00492603          	lw	a2,4(s2)
    80005366:	00003597          	auipc	a1,0x3
    8000536a:	39258593          	addi	a1,a1,914 # 800086f8 <syscalls+0x2c8>
    8000536e:	8526                	mv	a0,s1
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	c52080e7          	jalr	-942(ra) # 80003fc2 <dirlink>
    80005378:	f80557e3          	bgez	a0,80005306 <create+0xcc>
      panic("create dots");
    8000537c:	00003517          	auipc	a0,0x3
    80005380:	38450513          	addi	a0,a0,900 # 80008700 <syscalls+0x2d0>
    80005384:	ffffb097          	auipc	ra,0xffffb
    80005388:	1be080e7          	jalr	446(ra) # 80000542 <panic>
    panic("create: dirlink");
    8000538c:	00003517          	auipc	a0,0x3
    80005390:	38450513          	addi	a0,a0,900 # 80008710 <syscalls+0x2e0>
    80005394:	ffffb097          	auipc	ra,0xffffb
    80005398:	1ae080e7          	jalr	430(ra) # 80000542 <panic>
    return 0;
    8000539c:	84aa                	mv	s1,a0
    8000539e:	b739                	j	800052ac <create+0x72>

00000000800053a0 <sys_dup>:
{
    800053a0:	7179                	addi	sp,sp,-48
    800053a2:	f406                	sd	ra,40(sp)
    800053a4:	f022                	sd	s0,32(sp)
    800053a6:	ec26                	sd	s1,24(sp)
    800053a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053aa:	fd840613          	addi	a2,s0,-40
    800053ae:	4581                	li	a1,0
    800053b0:	4501                	li	a0,0
    800053b2:	00000097          	auipc	ra,0x0
    800053b6:	dde080e7          	jalr	-546(ra) # 80005190 <argfd>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053bc:	02054363          	bltz	a0,800053e2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053c0:	fd843503          	ld	a0,-40(s0)
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	e34080e7          	jalr	-460(ra) # 800051f8 <fdalloc>
    800053cc:	84aa                	mv	s1,a0
    return -1;
    800053ce:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053d0:	00054963          	bltz	a0,800053e2 <sys_dup+0x42>
  filedup(f);
    800053d4:	fd843503          	ld	a0,-40(s0)
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	338080e7          	jalr	824(ra) # 80004710 <filedup>
  return fd;
    800053e0:	87a6                	mv	a5,s1
}
    800053e2:	853e                	mv	a0,a5
    800053e4:	70a2                	ld	ra,40(sp)
    800053e6:	7402                	ld	s0,32(sp)
    800053e8:	64e2                	ld	s1,24(sp)
    800053ea:	6145                	addi	sp,sp,48
    800053ec:	8082                	ret

00000000800053ee <sys_read>:
{
    800053ee:	7179                	addi	sp,sp,-48
    800053f0:	f406                	sd	ra,40(sp)
    800053f2:	f022                	sd	s0,32(sp)
    800053f4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f6:	fe840613          	addi	a2,s0,-24
    800053fa:	4581                	li	a1,0
    800053fc:	4501                	li	a0,0
    800053fe:	00000097          	auipc	ra,0x0
    80005402:	d92080e7          	jalr	-622(ra) # 80005190 <argfd>
    return -1;
    80005406:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005408:	04054163          	bltz	a0,8000544a <sys_read+0x5c>
    8000540c:	fe440593          	addi	a1,s0,-28
    80005410:	4509                	li	a0,2
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	94e080e7          	jalr	-1714(ra) # 80002d60 <argint>
    return -1;
    8000541a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000541c:	02054763          	bltz	a0,8000544a <sys_read+0x5c>
    80005420:	fd840593          	addi	a1,s0,-40
    80005424:	4505                	li	a0,1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	95c080e7          	jalr	-1700(ra) # 80002d82 <argaddr>
    return -1;
    8000542e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005430:	00054d63          	bltz	a0,8000544a <sys_read+0x5c>
  return fileread(f, p, n);
    80005434:	fe442603          	lw	a2,-28(s0)
    80005438:	fd843583          	ld	a1,-40(s0)
    8000543c:	fe843503          	ld	a0,-24(s0)
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	45c080e7          	jalr	1116(ra) # 8000489c <fileread>
    80005448:	87aa                	mv	a5,a0
}
    8000544a:	853e                	mv	a0,a5
    8000544c:	70a2                	ld	ra,40(sp)
    8000544e:	7402                	ld	s0,32(sp)
    80005450:	6145                	addi	sp,sp,48
    80005452:	8082                	ret

0000000080005454 <sys_write>:
{
    80005454:	7179                	addi	sp,sp,-48
    80005456:	f406                	sd	ra,40(sp)
    80005458:	f022                	sd	s0,32(sp)
    8000545a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545c:	fe840613          	addi	a2,s0,-24
    80005460:	4581                	li	a1,0
    80005462:	4501                	li	a0,0
    80005464:	00000097          	auipc	ra,0x0
    80005468:	d2c080e7          	jalr	-724(ra) # 80005190 <argfd>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546e:	04054163          	bltz	a0,800054b0 <sys_write+0x5c>
    80005472:	fe440593          	addi	a1,s0,-28
    80005476:	4509                	li	a0,2
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	8e8080e7          	jalr	-1816(ra) # 80002d60 <argint>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005482:	02054763          	bltz	a0,800054b0 <sys_write+0x5c>
    80005486:	fd840593          	addi	a1,s0,-40
    8000548a:	4505                	li	a0,1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	8f6080e7          	jalr	-1802(ra) # 80002d82 <argaddr>
    return -1;
    80005494:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005496:	00054d63          	bltz	a0,800054b0 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000549a:	fe442603          	lw	a2,-28(s0)
    8000549e:	fd843583          	ld	a1,-40(s0)
    800054a2:	fe843503          	ld	a0,-24(s0)
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	4b8080e7          	jalr	1208(ra) # 8000495e <filewrite>
    800054ae:	87aa                	mv	a5,a0
}
    800054b0:	853e                	mv	a0,a5
    800054b2:	70a2                	ld	ra,40(sp)
    800054b4:	7402                	ld	s0,32(sp)
    800054b6:	6145                	addi	sp,sp,48
    800054b8:	8082                	ret

00000000800054ba <sys_close>:
{
    800054ba:	1101                	addi	sp,sp,-32
    800054bc:	ec06                	sd	ra,24(sp)
    800054be:	e822                	sd	s0,16(sp)
    800054c0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054c2:	fe040613          	addi	a2,s0,-32
    800054c6:	fec40593          	addi	a1,s0,-20
    800054ca:	4501                	li	a0,0
    800054cc:	00000097          	auipc	ra,0x0
    800054d0:	cc4080e7          	jalr	-828(ra) # 80005190 <argfd>
    return -1;
    800054d4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054d6:	02054463          	bltz	a0,800054fe <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	782080e7          	jalr	1922(ra) # 80001c5c <myproc>
    800054e2:	fec42783          	lw	a5,-20(s0)
    800054e6:	07e9                	addi	a5,a5,26
    800054e8:	078e                	slli	a5,a5,0x3
    800054ea:	97aa                	add	a5,a5,a0
    800054ec:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054f0:	fe043503          	ld	a0,-32(s0)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	26e080e7          	jalr	622(ra) # 80004762 <fileclose>
  return 0;
    800054fc:	4781                	li	a5,0
}
    800054fe:	853e                	mv	a0,a5
    80005500:	60e2                	ld	ra,24(sp)
    80005502:	6442                	ld	s0,16(sp)
    80005504:	6105                	addi	sp,sp,32
    80005506:	8082                	ret

0000000080005508 <sys_fstat>:
{
    80005508:	1101                	addi	sp,sp,-32
    8000550a:	ec06                	sd	ra,24(sp)
    8000550c:	e822                	sd	s0,16(sp)
    8000550e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005510:	fe840613          	addi	a2,s0,-24
    80005514:	4581                	li	a1,0
    80005516:	4501                	li	a0,0
    80005518:	00000097          	auipc	ra,0x0
    8000551c:	c78080e7          	jalr	-904(ra) # 80005190 <argfd>
    return -1;
    80005520:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005522:	02054563          	bltz	a0,8000554c <sys_fstat+0x44>
    80005526:	fe040593          	addi	a1,s0,-32
    8000552a:	4505                	li	a0,1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	856080e7          	jalr	-1962(ra) # 80002d82 <argaddr>
    return -1;
    80005534:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005536:	00054b63          	bltz	a0,8000554c <sys_fstat+0x44>
  return filestat(f, st);
    8000553a:	fe043583          	ld	a1,-32(s0)
    8000553e:	fe843503          	ld	a0,-24(s0)
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	2e8080e7          	jalr	744(ra) # 8000482a <filestat>
    8000554a:	87aa                	mv	a5,a0
}
    8000554c:	853e                	mv	a0,a5
    8000554e:	60e2                	ld	ra,24(sp)
    80005550:	6442                	ld	s0,16(sp)
    80005552:	6105                	addi	sp,sp,32
    80005554:	8082                	ret

0000000080005556 <sys_link>:
{
    80005556:	7169                	addi	sp,sp,-304
    80005558:	f606                	sd	ra,296(sp)
    8000555a:	f222                	sd	s0,288(sp)
    8000555c:	ee26                	sd	s1,280(sp)
    8000555e:	ea4a                	sd	s2,272(sp)
    80005560:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005562:	08000613          	li	a2,128
    80005566:	ed040593          	addi	a1,s0,-304
    8000556a:	4501                	li	a0,0
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	838080e7          	jalr	-1992(ra) # 80002da4 <argstr>
    return -1;
    80005574:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005576:	10054e63          	bltz	a0,80005692 <sys_link+0x13c>
    8000557a:	08000613          	li	a2,128
    8000557e:	f5040593          	addi	a1,s0,-176
    80005582:	4505                	li	a0,1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	820080e7          	jalr	-2016(ra) # 80002da4 <argstr>
    return -1;
    8000558c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000558e:	10054263          	bltz	a0,80005692 <sys_link+0x13c>
  begin_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	cfe080e7          	jalr	-770(ra) # 80004290 <begin_op>
  if((ip = namei(old)) == 0){
    8000559a:	ed040513          	addi	a0,s0,-304
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	ae6080e7          	jalr	-1306(ra) # 80004084 <namei>
    800055a6:	84aa                	mv	s1,a0
    800055a8:	c551                	beqz	a0,80005634 <sys_link+0xde>
  ilock(ip);
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	326080e7          	jalr	806(ra) # 800038d0 <ilock>
  if(ip->type == T_DIR){
    800055b2:	04449703          	lh	a4,68(s1)
    800055b6:	4785                	li	a5,1
    800055b8:	08f70463          	beq	a4,a5,80005640 <sys_link+0xea>
  ip->nlink++;
    800055bc:	04a4d783          	lhu	a5,74(s1)
    800055c0:	2785                	addiw	a5,a5,1
    800055c2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	23e080e7          	jalr	574(ra) # 80003806 <iupdate>
  iunlock(ip);
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	3c0080e7          	jalr	960(ra) # 80003992 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055da:	fd040593          	addi	a1,s0,-48
    800055de:	f5040513          	addi	a0,s0,-176
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	ac0080e7          	jalr	-1344(ra) # 800040a2 <nameiparent>
    800055ea:	892a                	mv	s2,a0
    800055ec:	c935                	beqz	a0,80005660 <sys_link+0x10a>
  ilock(dp);
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	2e2080e7          	jalr	738(ra) # 800038d0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055f6:	00092703          	lw	a4,0(s2)
    800055fa:	409c                	lw	a5,0(s1)
    800055fc:	04f71d63          	bne	a4,a5,80005656 <sys_link+0x100>
    80005600:	40d0                	lw	a2,4(s1)
    80005602:	fd040593          	addi	a1,s0,-48
    80005606:	854a                	mv	a0,s2
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	9ba080e7          	jalr	-1606(ra) # 80003fc2 <dirlink>
    80005610:	04054363          	bltz	a0,80005656 <sys_link+0x100>
  iunlockput(dp);
    80005614:	854a                	mv	a0,s2
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	51c080e7          	jalr	1308(ra) # 80003b32 <iunlockput>
  iput(ip);
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	46a080e7          	jalr	1130(ra) # 80003a8a <iput>
  end_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	ce8080e7          	jalr	-792(ra) # 80004310 <end_op>
  return 0;
    80005630:	4781                	li	a5,0
    80005632:	a085                	j	80005692 <sys_link+0x13c>
    end_op();
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	cdc080e7          	jalr	-804(ra) # 80004310 <end_op>
    return -1;
    8000563c:	57fd                	li	a5,-1
    8000563e:	a891                	j	80005692 <sys_link+0x13c>
    iunlockput(ip);
    80005640:	8526                	mv	a0,s1
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	4f0080e7          	jalr	1264(ra) # 80003b32 <iunlockput>
    end_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	cc6080e7          	jalr	-826(ra) # 80004310 <end_op>
    return -1;
    80005652:	57fd                	li	a5,-1
    80005654:	a83d                	j	80005692 <sys_link+0x13c>
    iunlockput(dp);
    80005656:	854a                	mv	a0,s2
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	4da080e7          	jalr	1242(ra) # 80003b32 <iunlockput>
  ilock(ip);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	26e080e7          	jalr	622(ra) # 800038d0 <ilock>
  ip->nlink--;
    8000566a:	04a4d783          	lhu	a5,74(s1)
    8000566e:	37fd                	addiw	a5,a5,-1
    80005670:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005674:	8526                	mv	a0,s1
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	190080e7          	jalr	400(ra) # 80003806 <iupdate>
  iunlockput(ip);
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	4b2080e7          	jalr	1202(ra) # 80003b32 <iunlockput>
  end_op();
    80005688:	fffff097          	auipc	ra,0xfffff
    8000568c:	c88080e7          	jalr	-888(ra) # 80004310 <end_op>
  return -1;
    80005690:	57fd                	li	a5,-1
}
    80005692:	853e                	mv	a0,a5
    80005694:	70b2                	ld	ra,296(sp)
    80005696:	7412                	ld	s0,288(sp)
    80005698:	64f2                	ld	s1,280(sp)
    8000569a:	6952                	ld	s2,272(sp)
    8000569c:	6155                	addi	sp,sp,304
    8000569e:	8082                	ret

00000000800056a0 <sys_unlink>:
{
    800056a0:	7151                	addi	sp,sp,-240
    800056a2:	f586                	sd	ra,232(sp)
    800056a4:	f1a2                	sd	s0,224(sp)
    800056a6:	eda6                	sd	s1,216(sp)
    800056a8:	e9ca                	sd	s2,208(sp)
    800056aa:	e5ce                	sd	s3,200(sp)
    800056ac:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056ae:	08000613          	li	a2,128
    800056b2:	f3040593          	addi	a1,s0,-208
    800056b6:	4501                	li	a0,0
    800056b8:	ffffd097          	auipc	ra,0xffffd
    800056bc:	6ec080e7          	jalr	1772(ra) # 80002da4 <argstr>
    800056c0:	18054163          	bltz	a0,80005842 <sys_unlink+0x1a2>
  begin_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	bcc080e7          	jalr	-1076(ra) # 80004290 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056cc:	fb040593          	addi	a1,s0,-80
    800056d0:	f3040513          	addi	a0,s0,-208
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	9ce080e7          	jalr	-1586(ra) # 800040a2 <nameiparent>
    800056dc:	84aa                	mv	s1,a0
    800056de:	c979                	beqz	a0,800057b4 <sys_unlink+0x114>
  ilock(dp);
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	1f0080e7          	jalr	496(ra) # 800038d0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056e8:	00003597          	auipc	a1,0x3
    800056ec:	00858593          	addi	a1,a1,8 # 800086f0 <syscalls+0x2c0>
    800056f0:	fb040513          	addi	a0,s0,-80
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	6a4080e7          	jalr	1700(ra) # 80003d98 <namecmp>
    800056fc:	14050a63          	beqz	a0,80005850 <sys_unlink+0x1b0>
    80005700:	00003597          	auipc	a1,0x3
    80005704:	ff858593          	addi	a1,a1,-8 # 800086f8 <syscalls+0x2c8>
    80005708:	fb040513          	addi	a0,s0,-80
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	68c080e7          	jalr	1676(ra) # 80003d98 <namecmp>
    80005714:	12050e63          	beqz	a0,80005850 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005718:	f2c40613          	addi	a2,s0,-212
    8000571c:	fb040593          	addi	a1,s0,-80
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	690080e7          	jalr	1680(ra) # 80003db2 <dirlookup>
    8000572a:	892a                	mv	s2,a0
    8000572c:	12050263          	beqz	a0,80005850 <sys_unlink+0x1b0>
  ilock(ip);
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	1a0080e7          	jalr	416(ra) # 800038d0 <ilock>
  if(ip->nlink < 1)
    80005738:	04a91783          	lh	a5,74(s2)
    8000573c:	08f05263          	blez	a5,800057c0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005740:	04491703          	lh	a4,68(s2)
    80005744:	4785                	li	a5,1
    80005746:	08f70563          	beq	a4,a5,800057d0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000574a:	4641                	li	a2,16
    8000574c:	4581                	li	a1,0
    8000574e:	fc040513          	addi	a0,s0,-64
    80005752:	ffffb097          	auipc	ra,0xffffb
    80005756:	6f4080e7          	jalr	1780(ra) # 80000e46 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000575a:	4741                	li	a4,16
    8000575c:	f2c42683          	lw	a3,-212(s0)
    80005760:	fc040613          	addi	a2,s0,-64
    80005764:	4581                	li	a1,0
    80005766:	8526                	mv	a0,s1
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	514080e7          	jalr	1300(ra) # 80003c7c <writei>
    80005770:	47c1                	li	a5,16
    80005772:	0af51563          	bne	a0,a5,8000581c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005776:	04491703          	lh	a4,68(s2)
    8000577a:	4785                	li	a5,1
    8000577c:	0af70863          	beq	a4,a5,8000582c <sys_unlink+0x18c>
  iunlockput(dp);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	3b0080e7          	jalr	944(ra) # 80003b32 <iunlockput>
  ip->nlink--;
    8000578a:	04a95783          	lhu	a5,74(s2)
    8000578e:	37fd                	addiw	a5,a5,-1
    80005790:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005794:	854a                	mv	a0,s2
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	070080e7          	jalr	112(ra) # 80003806 <iupdate>
  iunlockput(ip);
    8000579e:	854a                	mv	a0,s2
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	392080e7          	jalr	914(ra) # 80003b32 <iunlockput>
  end_op();
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	b68080e7          	jalr	-1176(ra) # 80004310 <end_op>
  return 0;
    800057b0:	4501                	li	a0,0
    800057b2:	a84d                	j	80005864 <sys_unlink+0x1c4>
    end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	b5c080e7          	jalr	-1188(ra) # 80004310 <end_op>
    return -1;
    800057bc:	557d                	li	a0,-1
    800057be:	a05d                	j	80005864 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057c0:	00003517          	auipc	a0,0x3
    800057c4:	f6050513          	addi	a0,a0,-160 # 80008720 <syscalls+0x2f0>
    800057c8:	ffffb097          	auipc	ra,0xffffb
    800057cc:	d7a080e7          	jalr	-646(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057d0:	04c92703          	lw	a4,76(s2)
    800057d4:	02000793          	li	a5,32
    800057d8:	f6e7f9e3          	bgeu	a5,a4,8000574a <sys_unlink+0xaa>
    800057dc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057e0:	4741                	li	a4,16
    800057e2:	86ce                	mv	a3,s3
    800057e4:	f1840613          	addi	a2,s0,-232
    800057e8:	4581                	li	a1,0
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	398080e7          	jalr	920(ra) # 80003b84 <readi>
    800057f4:	47c1                	li	a5,16
    800057f6:	00f51b63          	bne	a0,a5,8000580c <sys_unlink+0x16c>
    if(de.inum != 0)
    800057fa:	f1845783          	lhu	a5,-232(s0)
    800057fe:	e7a1                	bnez	a5,80005846 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005800:	29c1                	addiw	s3,s3,16
    80005802:	04c92783          	lw	a5,76(s2)
    80005806:	fcf9ede3          	bltu	s3,a5,800057e0 <sys_unlink+0x140>
    8000580a:	b781                	j	8000574a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000580c:	00003517          	auipc	a0,0x3
    80005810:	f2c50513          	addi	a0,a0,-212 # 80008738 <syscalls+0x308>
    80005814:	ffffb097          	auipc	ra,0xffffb
    80005818:	d2e080e7          	jalr	-722(ra) # 80000542 <panic>
    panic("unlink: writei");
    8000581c:	00003517          	auipc	a0,0x3
    80005820:	f3450513          	addi	a0,a0,-204 # 80008750 <syscalls+0x320>
    80005824:	ffffb097          	auipc	ra,0xffffb
    80005828:	d1e080e7          	jalr	-738(ra) # 80000542 <panic>
    dp->nlink--;
    8000582c:	04a4d783          	lhu	a5,74(s1)
    80005830:	37fd                	addiw	a5,a5,-1
    80005832:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005836:	8526                	mv	a0,s1
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	fce080e7          	jalr	-50(ra) # 80003806 <iupdate>
    80005840:	b781                	j	80005780 <sys_unlink+0xe0>
    return -1;
    80005842:	557d                	li	a0,-1
    80005844:	a005                	j	80005864 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005846:	854a                	mv	a0,s2
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	2ea080e7          	jalr	746(ra) # 80003b32 <iunlockput>
  iunlockput(dp);
    80005850:	8526                	mv	a0,s1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	2e0080e7          	jalr	736(ra) # 80003b32 <iunlockput>
  end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	ab6080e7          	jalr	-1354(ra) # 80004310 <end_op>
  return -1;
    80005862:	557d                	li	a0,-1
}
    80005864:	70ae                	ld	ra,232(sp)
    80005866:	740e                	ld	s0,224(sp)
    80005868:	64ee                	ld	s1,216(sp)
    8000586a:	694e                	ld	s2,208(sp)
    8000586c:	69ae                	ld	s3,200(sp)
    8000586e:	616d                	addi	sp,sp,240
    80005870:	8082                	ret

0000000080005872 <sys_open>:

uint64
sys_open(void)
{
    80005872:	7131                	addi	sp,sp,-192
    80005874:	fd06                	sd	ra,184(sp)
    80005876:	f922                	sd	s0,176(sp)
    80005878:	f526                	sd	s1,168(sp)
    8000587a:	f14a                	sd	s2,160(sp)
    8000587c:	ed4e                	sd	s3,152(sp)
    8000587e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005880:	08000613          	li	a2,128
    80005884:	f5040593          	addi	a1,s0,-176
    80005888:	4501                	li	a0,0
    8000588a:	ffffd097          	auipc	ra,0xffffd
    8000588e:	51a080e7          	jalr	1306(ra) # 80002da4 <argstr>
    return -1;
    80005892:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005894:	0c054163          	bltz	a0,80005956 <sys_open+0xe4>
    80005898:	f4c40593          	addi	a1,s0,-180
    8000589c:	4505                	li	a0,1
    8000589e:	ffffd097          	auipc	ra,0xffffd
    800058a2:	4c2080e7          	jalr	1218(ra) # 80002d60 <argint>
    800058a6:	0a054863          	bltz	a0,80005956 <sys_open+0xe4>

  begin_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	9e6080e7          	jalr	-1562(ra) # 80004290 <begin_op>

  if(omode & O_CREATE){
    800058b2:	f4c42783          	lw	a5,-180(s0)
    800058b6:	2007f793          	andi	a5,a5,512
    800058ba:	cbdd                	beqz	a5,80005970 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058bc:	4681                	li	a3,0
    800058be:	4601                	li	a2,0
    800058c0:	4589                	li	a1,2
    800058c2:	f5040513          	addi	a0,s0,-176
    800058c6:	00000097          	auipc	ra,0x0
    800058ca:	974080e7          	jalr	-1676(ra) # 8000523a <create>
    800058ce:	892a                	mv	s2,a0
    if(ip == 0){
    800058d0:	c959                	beqz	a0,80005966 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058d2:	04491703          	lh	a4,68(s2)
    800058d6:	478d                	li	a5,3
    800058d8:	00f71763          	bne	a4,a5,800058e6 <sys_open+0x74>
    800058dc:	04695703          	lhu	a4,70(s2)
    800058e0:	47a5                	li	a5,9
    800058e2:	0ce7ec63          	bltu	a5,a4,800059ba <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	dc0080e7          	jalr	-576(ra) # 800046a6 <filealloc>
    800058ee:	89aa                	mv	s3,a0
    800058f0:	10050263          	beqz	a0,800059f4 <sys_open+0x182>
    800058f4:	00000097          	auipc	ra,0x0
    800058f8:	904080e7          	jalr	-1788(ra) # 800051f8 <fdalloc>
    800058fc:	84aa                	mv	s1,a0
    800058fe:	0e054663          	bltz	a0,800059ea <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005902:	04491703          	lh	a4,68(s2)
    80005906:	478d                	li	a5,3
    80005908:	0cf70463          	beq	a4,a5,800059d0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000590c:	4789                	li	a5,2
    8000590e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005912:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005916:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000591a:	f4c42783          	lw	a5,-180(s0)
    8000591e:	0017c713          	xori	a4,a5,1
    80005922:	8b05                	andi	a4,a4,1
    80005924:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005928:	0037f713          	andi	a4,a5,3
    8000592c:	00e03733          	snez	a4,a4
    80005930:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005934:	4007f793          	andi	a5,a5,1024
    80005938:	c791                	beqz	a5,80005944 <sys_open+0xd2>
    8000593a:	04491703          	lh	a4,68(s2)
    8000593e:	4789                	li	a5,2
    80005940:	08f70f63          	beq	a4,a5,800059de <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005944:	854a                	mv	a0,s2
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	04c080e7          	jalr	76(ra) # 80003992 <iunlock>
  end_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	9c2080e7          	jalr	-1598(ra) # 80004310 <end_op>

  return fd;
}
    80005956:	8526                	mv	a0,s1
    80005958:	70ea                	ld	ra,184(sp)
    8000595a:	744a                	ld	s0,176(sp)
    8000595c:	74aa                	ld	s1,168(sp)
    8000595e:	790a                	ld	s2,160(sp)
    80005960:	69ea                	ld	s3,152(sp)
    80005962:	6129                	addi	sp,sp,192
    80005964:	8082                	ret
      end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	9aa080e7          	jalr	-1622(ra) # 80004310 <end_op>
      return -1;
    8000596e:	b7e5                	j	80005956 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005970:	f5040513          	addi	a0,s0,-176
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	710080e7          	jalr	1808(ra) # 80004084 <namei>
    8000597c:	892a                	mv	s2,a0
    8000597e:	c905                	beqz	a0,800059ae <sys_open+0x13c>
    ilock(ip);
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	f50080e7          	jalr	-176(ra) # 800038d0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005988:	04491703          	lh	a4,68(s2)
    8000598c:	4785                	li	a5,1
    8000598e:	f4f712e3          	bne	a4,a5,800058d2 <sys_open+0x60>
    80005992:	f4c42783          	lw	a5,-180(s0)
    80005996:	dba1                	beqz	a5,800058e6 <sys_open+0x74>
      iunlockput(ip);
    80005998:	854a                	mv	a0,s2
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	198080e7          	jalr	408(ra) # 80003b32 <iunlockput>
      end_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	96e080e7          	jalr	-1682(ra) # 80004310 <end_op>
      return -1;
    800059aa:	54fd                	li	s1,-1
    800059ac:	b76d                	j	80005956 <sys_open+0xe4>
      end_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	962080e7          	jalr	-1694(ra) # 80004310 <end_op>
      return -1;
    800059b6:	54fd                	li	s1,-1
    800059b8:	bf79                	j	80005956 <sys_open+0xe4>
    iunlockput(ip);
    800059ba:	854a                	mv	a0,s2
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	176080e7          	jalr	374(ra) # 80003b32 <iunlockput>
    end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	94c080e7          	jalr	-1716(ra) # 80004310 <end_op>
    return -1;
    800059cc:	54fd                	li	s1,-1
    800059ce:	b761                	j	80005956 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059d0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059d4:	04691783          	lh	a5,70(s2)
    800059d8:	02f99223          	sh	a5,36(s3)
    800059dc:	bf2d                	j	80005916 <sys_open+0xa4>
    itrunc(ip);
    800059de:	854a                	mv	a0,s2
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	ffe080e7          	jalr	-2(ra) # 800039de <itrunc>
    800059e8:	bfb1                	j	80005944 <sys_open+0xd2>
      fileclose(f);
    800059ea:	854e                	mv	a0,s3
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	d76080e7          	jalr	-650(ra) # 80004762 <fileclose>
    iunlockput(ip);
    800059f4:	854a                	mv	a0,s2
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	13c080e7          	jalr	316(ra) # 80003b32 <iunlockput>
    end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	912080e7          	jalr	-1774(ra) # 80004310 <end_op>
    return -1;
    80005a06:	54fd                	li	s1,-1
    80005a08:	b7b9                	j	80005956 <sys_open+0xe4>

0000000080005a0a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a0a:	7175                	addi	sp,sp,-144
    80005a0c:	e506                	sd	ra,136(sp)
    80005a0e:	e122                	sd	s0,128(sp)
    80005a10:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	87e080e7          	jalr	-1922(ra) # 80004290 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a1a:	08000613          	li	a2,128
    80005a1e:	f7040593          	addi	a1,s0,-144
    80005a22:	4501                	li	a0,0
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	380080e7          	jalr	896(ra) # 80002da4 <argstr>
    80005a2c:	02054963          	bltz	a0,80005a5e <sys_mkdir+0x54>
    80005a30:	4681                	li	a3,0
    80005a32:	4601                	li	a2,0
    80005a34:	4585                	li	a1,1
    80005a36:	f7040513          	addi	a0,s0,-144
    80005a3a:	00000097          	auipc	ra,0x0
    80005a3e:	800080e7          	jalr	-2048(ra) # 8000523a <create>
    80005a42:	cd11                	beqz	a0,80005a5e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	0ee080e7          	jalr	238(ra) # 80003b32 <iunlockput>
  end_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	8c4080e7          	jalr	-1852(ra) # 80004310 <end_op>
  return 0;
    80005a54:	4501                	li	a0,0
}
    80005a56:	60aa                	ld	ra,136(sp)
    80005a58:	640a                	ld	s0,128(sp)
    80005a5a:	6149                	addi	sp,sp,144
    80005a5c:	8082                	ret
    end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	8b2080e7          	jalr	-1870(ra) # 80004310 <end_op>
    return -1;
    80005a66:	557d                	li	a0,-1
    80005a68:	b7fd                	j	80005a56 <sys_mkdir+0x4c>

0000000080005a6a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a6a:	7135                	addi	sp,sp,-160
    80005a6c:	ed06                	sd	ra,152(sp)
    80005a6e:	e922                	sd	s0,144(sp)
    80005a70:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	81e080e7          	jalr	-2018(ra) # 80004290 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a7a:	08000613          	li	a2,128
    80005a7e:	f7040593          	addi	a1,s0,-144
    80005a82:	4501                	li	a0,0
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	320080e7          	jalr	800(ra) # 80002da4 <argstr>
    80005a8c:	04054a63          	bltz	a0,80005ae0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a90:	f6c40593          	addi	a1,s0,-148
    80005a94:	4505                	li	a0,1
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	2ca080e7          	jalr	714(ra) # 80002d60 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a9e:	04054163          	bltz	a0,80005ae0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005aa2:	f6840593          	addi	a1,s0,-152
    80005aa6:	4509                	li	a0,2
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	2b8080e7          	jalr	696(ra) # 80002d60 <argint>
     argint(1, &major) < 0 ||
    80005ab0:	02054863          	bltz	a0,80005ae0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ab4:	f6841683          	lh	a3,-152(s0)
    80005ab8:	f6c41603          	lh	a2,-148(s0)
    80005abc:	458d                	li	a1,3
    80005abe:	f7040513          	addi	a0,s0,-144
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	778080e7          	jalr	1912(ra) # 8000523a <create>
     argint(2, &minor) < 0 ||
    80005aca:	c919                	beqz	a0,80005ae0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	066080e7          	jalr	102(ra) # 80003b32 <iunlockput>
  end_op();
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	83c080e7          	jalr	-1988(ra) # 80004310 <end_op>
  return 0;
    80005adc:	4501                	li	a0,0
    80005ade:	a031                	j	80005aea <sys_mknod+0x80>
    end_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	830080e7          	jalr	-2000(ra) # 80004310 <end_op>
    return -1;
    80005ae8:	557d                	li	a0,-1
}
    80005aea:	60ea                	ld	ra,152(sp)
    80005aec:	644a                	ld	s0,144(sp)
    80005aee:	610d                	addi	sp,sp,160
    80005af0:	8082                	ret

0000000080005af2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005af2:	7135                	addi	sp,sp,-160
    80005af4:	ed06                	sd	ra,152(sp)
    80005af6:	e922                	sd	s0,144(sp)
    80005af8:	e526                	sd	s1,136(sp)
    80005afa:	e14a                	sd	s2,128(sp)
    80005afc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005afe:	ffffc097          	auipc	ra,0xffffc
    80005b02:	15e080e7          	jalr	350(ra) # 80001c5c <myproc>
    80005b06:	892a                	mv	s2,a0
  
  begin_op();
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	788080e7          	jalr	1928(ra) # 80004290 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b10:	08000613          	li	a2,128
    80005b14:	f6040593          	addi	a1,s0,-160
    80005b18:	4501                	li	a0,0
    80005b1a:	ffffd097          	auipc	ra,0xffffd
    80005b1e:	28a080e7          	jalr	650(ra) # 80002da4 <argstr>
    80005b22:	04054b63          	bltz	a0,80005b78 <sys_chdir+0x86>
    80005b26:	f6040513          	addi	a0,s0,-160
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	55a080e7          	jalr	1370(ra) # 80004084 <namei>
    80005b32:	84aa                	mv	s1,a0
    80005b34:	c131                	beqz	a0,80005b78 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	d9a080e7          	jalr	-614(ra) # 800038d0 <ilock>
  if(ip->type != T_DIR){
    80005b3e:	04449703          	lh	a4,68(s1)
    80005b42:	4785                	li	a5,1
    80005b44:	04f71063          	bne	a4,a5,80005b84 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	e48080e7          	jalr	-440(ra) # 80003992 <iunlock>
  iput(p->cwd);
    80005b52:	15093503          	ld	a0,336(s2)
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	f34080e7          	jalr	-204(ra) # 80003a8a <iput>
  end_op();
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	7b2080e7          	jalr	1970(ra) # 80004310 <end_op>
  p->cwd = ip;
    80005b66:	14993823          	sd	s1,336(s2)
  return 0;
    80005b6a:	4501                	li	a0,0
}
    80005b6c:	60ea                	ld	ra,152(sp)
    80005b6e:	644a                	ld	s0,144(sp)
    80005b70:	64aa                	ld	s1,136(sp)
    80005b72:	690a                	ld	s2,128(sp)
    80005b74:	610d                	addi	sp,sp,160
    80005b76:	8082                	ret
    end_op();
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	798080e7          	jalr	1944(ra) # 80004310 <end_op>
    return -1;
    80005b80:	557d                	li	a0,-1
    80005b82:	b7ed                	j	80005b6c <sys_chdir+0x7a>
    iunlockput(ip);
    80005b84:	8526                	mv	a0,s1
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	fac080e7          	jalr	-84(ra) # 80003b32 <iunlockput>
    end_op();
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	782080e7          	jalr	1922(ra) # 80004310 <end_op>
    return -1;
    80005b96:	557d                	li	a0,-1
    80005b98:	bfd1                	j	80005b6c <sys_chdir+0x7a>

0000000080005b9a <sys_exec>:

uint64
sys_exec(void)
{
    80005b9a:	7145                	addi	sp,sp,-464
    80005b9c:	e786                	sd	ra,456(sp)
    80005b9e:	e3a2                	sd	s0,448(sp)
    80005ba0:	ff26                	sd	s1,440(sp)
    80005ba2:	fb4a                	sd	s2,432(sp)
    80005ba4:	f74e                	sd	s3,424(sp)
    80005ba6:	f352                	sd	s4,416(sp)
    80005ba8:	ef56                	sd	s5,408(sp)
    80005baa:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bac:	08000613          	li	a2,128
    80005bb0:	f4040593          	addi	a1,s0,-192
    80005bb4:	4501                	li	a0,0
    80005bb6:	ffffd097          	auipc	ra,0xffffd
    80005bba:	1ee080e7          	jalr	494(ra) # 80002da4 <argstr>
    return -1;
    80005bbe:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bc0:	0c054a63          	bltz	a0,80005c94 <sys_exec+0xfa>
    80005bc4:	e3840593          	addi	a1,s0,-456
    80005bc8:	4505                	li	a0,1
    80005bca:	ffffd097          	auipc	ra,0xffffd
    80005bce:	1b8080e7          	jalr	440(ra) # 80002d82 <argaddr>
    80005bd2:	0c054163          	bltz	a0,80005c94 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bd6:	10000613          	li	a2,256
    80005bda:	4581                	li	a1,0
    80005bdc:	e4040513          	addi	a0,s0,-448
    80005be0:	ffffb097          	auipc	ra,0xffffb
    80005be4:	266080e7          	jalr	614(ra) # 80000e46 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005be8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bec:	89a6                	mv	s3,s1
    80005bee:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bf0:	02000a13          	li	s4,32
    80005bf4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bf8:	00391793          	slli	a5,s2,0x3
    80005bfc:	e3040593          	addi	a1,s0,-464
    80005c00:	e3843503          	ld	a0,-456(s0)
    80005c04:	953e                	add	a0,a0,a5
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	0c0080e7          	jalr	192(ra) # 80002cc6 <fetchaddr>
    80005c0e:	02054a63          	bltz	a0,80005c42 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c12:	e3043783          	ld	a5,-464(s0)
    80005c16:	c3b9                	beqz	a5,80005c5c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c18:	ffffb097          	auipc	ra,0xffffb
    80005c1c:	f82080e7          	jalr	-126(ra) # 80000b9a <kalloc>
    80005c20:	85aa                	mv	a1,a0
    80005c22:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c26:	cd11                	beqz	a0,80005c42 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c28:	6605                	lui	a2,0x1
    80005c2a:	e3043503          	ld	a0,-464(s0)
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	0ea080e7          	jalr	234(ra) # 80002d18 <fetchstr>
    80005c36:	00054663          	bltz	a0,80005c42 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c3a:	0905                	addi	s2,s2,1
    80005c3c:	09a1                	addi	s3,s3,8
    80005c3e:	fb491be3          	bne	s2,s4,80005bf4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c42:	10048913          	addi	s2,s1,256
    80005c46:	6088                	ld	a0,0(s1)
    80005c48:	c529                	beqz	a0,80005c92 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c4a:	ffffb097          	auipc	ra,0xffffb
    80005c4e:	dc8080e7          	jalr	-568(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c52:	04a1                	addi	s1,s1,8
    80005c54:	ff2499e3          	bne	s1,s2,80005c46 <sys_exec+0xac>
  return -1;
    80005c58:	597d                	li	s2,-1
    80005c5a:	a82d                	j	80005c94 <sys_exec+0xfa>
      argv[i] = 0;
    80005c5c:	0a8e                	slli	s5,s5,0x3
    80005c5e:	fc040793          	addi	a5,s0,-64
    80005c62:	9abe                	add	s5,s5,a5
    80005c64:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7fdb8e80>
  int ret = exec(path, argv);
    80005c68:	e4040593          	addi	a1,s0,-448
    80005c6c:	f4040513          	addi	a0,s0,-192
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	178080e7          	jalr	376(ra) # 80004de8 <exec>
    80005c78:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7a:	10048993          	addi	s3,s1,256
    80005c7e:	6088                	ld	a0,0(s1)
    80005c80:	c911                	beqz	a0,80005c94 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c82:	ffffb097          	auipc	ra,0xffffb
    80005c86:	d90080e7          	jalr	-624(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8a:	04a1                	addi	s1,s1,8
    80005c8c:	ff3499e3          	bne	s1,s3,80005c7e <sys_exec+0xe4>
    80005c90:	a011                	j	80005c94 <sys_exec+0xfa>
  return -1;
    80005c92:	597d                	li	s2,-1
}
    80005c94:	854a                	mv	a0,s2
    80005c96:	60be                	ld	ra,456(sp)
    80005c98:	641e                	ld	s0,448(sp)
    80005c9a:	74fa                	ld	s1,440(sp)
    80005c9c:	795a                	ld	s2,432(sp)
    80005c9e:	79ba                	ld	s3,424(sp)
    80005ca0:	7a1a                	ld	s4,416(sp)
    80005ca2:	6afa                	ld	s5,408(sp)
    80005ca4:	6179                	addi	sp,sp,464
    80005ca6:	8082                	ret

0000000080005ca8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ca8:	7139                	addi	sp,sp,-64
    80005caa:	fc06                	sd	ra,56(sp)
    80005cac:	f822                	sd	s0,48(sp)
    80005cae:	f426                	sd	s1,40(sp)
    80005cb0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cb2:	ffffc097          	auipc	ra,0xffffc
    80005cb6:	faa080e7          	jalr	-86(ra) # 80001c5c <myproc>
    80005cba:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cbc:	fd840593          	addi	a1,s0,-40
    80005cc0:	4501                	li	a0,0
    80005cc2:	ffffd097          	auipc	ra,0xffffd
    80005cc6:	0c0080e7          	jalr	192(ra) # 80002d82 <argaddr>
    return -1;
    80005cca:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ccc:	0e054063          	bltz	a0,80005dac <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cd0:	fc840593          	addi	a1,s0,-56
    80005cd4:	fd040513          	addi	a0,s0,-48
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	de0080e7          	jalr	-544(ra) # 80004ab8 <pipealloc>
    return -1;
    80005ce0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ce2:	0c054563          	bltz	a0,80005dac <sys_pipe+0x104>
  fd0 = -1;
    80005ce6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cea:	fd043503          	ld	a0,-48(s0)
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	50a080e7          	jalr	1290(ra) # 800051f8 <fdalloc>
    80005cf6:	fca42223          	sw	a0,-60(s0)
    80005cfa:	08054c63          	bltz	a0,80005d92 <sys_pipe+0xea>
    80005cfe:	fc843503          	ld	a0,-56(s0)
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	4f6080e7          	jalr	1270(ra) # 800051f8 <fdalloc>
    80005d0a:	fca42023          	sw	a0,-64(s0)
    80005d0e:	06054863          	bltz	a0,80005d7e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d12:	4691                	li	a3,4
    80005d14:	fc440613          	addi	a2,s0,-60
    80005d18:	fd843583          	ld	a1,-40(s0)
    80005d1c:	68a8                	ld	a0,80(s1)
    80005d1e:	ffffc097          	auipc	ra,0xffffc
    80005d22:	d4c080e7          	jalr	-692(ra) # 80001a6a <copyout>
    80005d26:	02054063          	bltz	a0,80005d46 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d2a:	4691                	li	a3,4
    80005d2c:	fc040613          	addi	a2,s0,-64
    80005d30:	fd843583          	ld	a1,-40(s0)
    80005d34:	0591                	addi	a1,a1,4
    80005d36:	68a8                	ld	a0,80(s1)
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	d32080e7          	jalr	-718(ra) # 80001a6a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d40:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d42:	06055563          	bgez	a0,80005dac <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d46:	fc442783          	lw	a5,-60(s0)
    80005d4a:	07e9                	addi	a5,a5,26
    80005d4c:	078e                	slli	a5,a5,0x3
    80005d4e:	97a6                	add	a5,a5,s1
    80005d50:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d54:	fc042503          	lw	a0,-64(s0)
    80005d58:	0569                	addi	a0,a0,26
    80005d5a:	050e                	slli	a0,a0,0x3
    80005d5c:	9526                	add	a0,a0,s1
    80005d5e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d62:	fd043503          	ld	a0,-48(s0)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	9fc080e7          	jalr	-1540(ra) # 80004762 <fileclose>
    fileclose(wf);
    80005d6e:	fc843503          	ld	a0,-56(s0)
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	9f0080e7          	jalr	-1552(ra) # 80004762 <fileclose>
    return -1;
    80005d7a:	57fd                	li	a5,-1
    80005d7c:	a805                	j	80005dac <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d7e:	fc442783          	lw	a5,-60(s0)
    80005d82:	0007c863          	bltz	a5,80005d92 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d86:	01a78513          	addi	a0,a5,26
    80005d8a:	050e                	slli	a0,a0,0x3
    80005d8c:	9526                	add	a0,a0,s1
    80005d8e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d92:	fd043503          	ld	a0,-48(s0)
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	9cc080e7          	jalr	-1588(ra) # 80004762 <fileclose>
    fileclose(wf);
    80005d9e:	fc843503          	ld	a0,-56(s0)
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	9c0080e7          	jalr	-1600(ra) # 80004762 <fileclose>
    return -1;
    80005daa:	57fd                	li	a5,-1
}
    80005dac:	853e                	mv	a0,a5
    80005dae:	70e2                	ld	ra,56(sp)
    80005db0:	7442                	ld	s0,48(sp)
    80005db2:	74a2                	ld	s1,40(sp)
    80005db4:	6121                	addi	sp,sp,64
    80005db6:	8082                	ret
	...

0000000080005dc0 <kernelvec>:
    80005dc0:	7111                	addi	sp,sp,-256
    80005dc2:	e006                	sd	ra,0(sp)
    80005dc4:	e40a                	sd	sp,8(sp)
    80005dc6:	e80e                	sd	gp,16(sp)
    80005dc8:	ec12                	sd	tp,24(sp)
    80005dca:	f016                	sd	t0,32(sp)
    80005dcc:	f41a                	sd	t1,40(sp)
    80005dce:	f81e                	sd	t2,48(sp)
    80005dd0:	fc22                	sd	s0,56(sp)
    80005dd2:	e0a6                	sd	s1,64(sp)
    80005dd4:	e4aa                	sd	a0,72(sp)
    80005dd6:	e8ae                	sd	a1,80(sp)
    80005dd8:	ecb2                	sd	a2,88(sp)
    80005dda:	f0b6                	sd	a3,96(sp)
    80005ddc:	f4ba                	sd	a4,104(sp)
    80005dde:	f8be                	sd	a5,112(sp)
    80005de0:	fcc2                	sd	a6,120(sp)
    80005de2:	e146                	sd	a7,128(sp)
    80005de4:	e54a                	sd	s2,136(sp)
    80005de6:	e94e                	sd	s3,144(sp)
    80005de8:	ed52                	sd	s4,152(sp)
    80005dea:	f156                	sd	s5,160(sp)
    80005dec:	f55a                	sd	s6,168(sp)
    80005dee:	f95e                	sd	s7,176(sp)
    80005df0:	fd62                	sd	s8,184(sp)
    80005df2:	e1e6                	sd	s9,192(sp)
    80005df4:	e5ea                	sd	s10,200(sp)
    80005df6:	e9ee                	sd	s11,208(sp)
    80005df8:	edf2                	sd	t3,216(sp)
    80005dfa:	f1f6                	sd	t4,224(sp)
    80005dfc:	f5fa                	sd	t5,232(sp)
    80005dfe:	f9fe                	sd	t6,240(sp)
    80005e00:	d93fc0ef          	jal	ra,80002b92 <kerneltrap>
    80005e04:	6082                	ld	ra,0(sp)
    80005e06:	6122                	ld	sp,8(sp)
    80005e08:	61c2                	ld	gp,16(sp)
    80005e0a:	7282                	ld	t0,32(sp)
    80005e0c:	7322                	ld	t1,40(sp)
    80005e0e:	73c2                	ld	t2,48(sp)
    80005e10:	7462                	ld	s0,56(sp)
    80005e12:	6486                	ld	s1,64(sp)
    80005e14:	6526                	ld	a0,72(sp)
    80005e16:	65c6                	ld	a1,80(sp)
    80005e18:	6666                	ld	a2,88(sp)
    80005e1a:	7686                	ld	a3,96(sp)
    80005e1c:	7726                	ld	a4,104(sp)
    80005e1e:	77c6                	ld	a5,112(sp)
    80005e20:	7866                	ld	a6,120(sp)
    80005e22:	688a                	ld	a7,128(sp)
    80005e24:	692a                	ld	s2,136(sp)
    80005e26:	69ca                	ld	s3,144(sp)
    80005e28:	6a6a                	ld	s4,152(sp)
    80005e2a:	7a8a                	ld	s5,160(sp)
    80005e2c:	7b2a                	ld	s6,168(sp)
    80005e2e:	7bca                	ld	s7,176(sp)
    80005e30:	7c6a                	ld	s8,184(sp)
    80005e32:	6c8e                	ld	s9,192(sp)
    80005e34:	6d2e                	ld	s10,200(sp)
    80005e36:	6dce                	ld	s11,208(sp)
    80005e38:	6e6e                	ld	t3,216(sp)
    80005e3a:	7e8e                	ld	t4,224(sp)
    80005e3c:	7f2e                	ld	t5,232(sp)
    80005e3e:	7fce                	ld	t6,240(sp)
    80005e40:	6111                	addi	sp,sp,256
    80005e42:	10200073          	sret
    80005e46:	00000013          	nop
    80005e4a:	00000013          	nop
    80005e4e:	0001                	nop

0000000080005e50 <timervec>:
    80005e50:	34051573          	csrrw	a0,mscratch,a0
    80005e54:	e10c                	sd	a1,0(a0)
    80005e56:	e510                	sd	a2,8(a0)
    80005e58:	e914                	sd	a3,16(a0)
    80005e5a:	710c                	ld	a1,32(a0)
    80005e5c:	7510                	ld	a2,40(a0)
    80005e5e:	6194                	ld	a3,0(a1)
    80005e60:	96b2                	add	a3,a3,a2
    80005e62:	e194                	sd	a3,0(a1)
    80005e64:	4589                	li	a1,2
    80005e66:	14459073          	csrw	sip,a1
    80005e6a:	6914                	ld	a3,16(a0)
    80005e6c:	6510                	ld	a2,8(a0)
    80005e6e:	610c                	ld	a1,0(a0)
    80005e70:	34051573          	csrrw	a0,mscratch,a0
    80005e74:	30200073          	mret
	...

0000000080005e7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e7a:	1141                	addi	sp,sp,-16
    80005e7c:	e422                	sd	s0,8(sp)
    80005e7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e80:	0c0007b7          	lui	a5,0xc000
    80005e84:	4705                	li	a4,1
    80005e86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e88:	c3d8                	sw	a4,4(a5)
}
    80005e8a:	6422                	ld	s0,8(sp)
    80005e8c:	0141                	addi	sp,sp,16
    80005e8e:	8082                	ret

0000000080005e90 <plicinithart>:

void
plicinithart(void)
{
    80005e90:	1141                	addi	sp,sp,-16
    80005e92:	e406                	sd	ra,8(sp)
    80005e94:	e022                	sd	s0,0(sp)
    80005e96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	d98080e7          	jalr	-616(ra) # 80001c30 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ea0:	0085171b          	slliw	a4,a0,0x8
    80005ea4:	0c0027b7          	lui	a5,0xc002
    80005ea8:	97ba                	add	a5,a5,a4
    80005eaa:	40200713          	li	a4,1026
    80005eae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005eb2:	00d5151b          	slliw	a0,a0,0xd
    80005eb6:	0c2017b7          	lui	a5,0xc201
    80005eba:	953e                	add	a0,a0,a5
    80005ebc:	00052023          	sw	zero,0(a0)
}
    80005ec0:	60a2                	ld	ra,8(sp)
    80005ec2:	6402                	ld	s0,0(sp)
    80005ec4:	0141                	addi	sp,sp,16
    80005ec6:	8082                	ret

0000000080005ec8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ec8:	1141                	addi	sp,sp,-16
    80005eca:	e406                	sd	ra,8(sp)
    80005ecc:	e022                	sd	s0,0(sp)
    80005ece:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ed0:	ffffc097          	auipc	ra,0xffffc
    80005ed4:	d60080e7          	jalr	-672(ra) # 80001c30 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ed8:	00d5179b          	slliw	a5,a0,0xd
    80005edc:	0c201537          	lui	a0,0xc201
    80005ee0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ee2:	4148                	lw	a0,4(a0)
    80005ee4:	60a2                	ld	ra,8(sp)
    80005ee6:	6402                	ld	s0,0(sp)
    80005ee8:	0141                	addi	sp,sp,16
    80005eea:	8082                	ret

0000000080005eec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eec:	1101                	addi	sp,sp,-32
    80005eee:	ec06                	sd	ra,24(sp)
    80005ef0:	e822                	sd	s0,16(sp)
    80005ef2:	e426                	sd	s1,8(sp)
    80005ef4:	1000                	addi	s0,sp,32
    80005ef6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	d38080e7          	jalr	-712(ra) # 80001c30 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f00:	00d5151b          	slliw	a0,a0,0xd
    80005f04:	0c2017b7          	lui	a5,0xc201
    80005f08:	97aa                	add	a5,a5,a0
    80005f0a:	c3c4                	sw	s1,4(a5)
}
    80005f0c:	60e2                	ld	ra,24(sp)
    80005f0e:	6442                	ld	s0,16(sp)
    80005f10:	64a2                	ld	s1,8(sp)
    80005f12:	6105                	addi	sp,sp,32
    80005f14:	8082                	ret

0000000080005f16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f16:	1141                	addi	sp,sp,-16
    80005f18:	e406                	sd	ra,8(sp)
    80005f1a:	e022                	sd	s0,0(sp)
    80005f1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f1e:	479d                	li	a5,7
    80005f20:	04a7cc63          	blt	a5,a0,80005f78 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f24:	0023d797          	auipc	a5,0x23d
    80005f28:	0dc78793          	addi	a5,a5,220 # 80243000 <disk>
    80005f2c:	00a78733          	add	a4,a5,a0
    80005f30:	6789                	lui	a5,0x2
    80005f32:	97ba                	add	a5,a5,a4
    80005f34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f38:	eba1                	bnez	a5,80005f88 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f3a:	00451713          	slli	a4,a0,0x4
    80005f3e:	0023f797          	auipc	a5,0x23f
    80005f42:	0c27b783          	ld	a5,194(a5) # 80245000 <disk+0x2000>
    80005f46:	97ba                	add	a5,a5,a4
    80005f48:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f4c:	0023d797          	auipc	a5,0x23d
    80005f50:	0b478793          	addi	a5,a5,180 # 80243000 <disk>
    80005f54:	97aa                	add	a5,a5,a0
    80005f56:	6509                	lui	a0,0x2
    80005f58:	953e                	add	a0,a0,a5
    80005f5a:	4785                	li	a5,1
    80005f5c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f60:	0023f517          	auipc	a0,0x23f
    80005f64:	0b850513          	addi	a0,a0,184 # 80245018 <disk+0x2018>
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	688080e7          	jalr	1672(ra) # 800025f0 <wakeup>
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f78:	00002517          	auipc	a0,0x2
    80005f7c:	7e850513          	addi	a0,a0,2024 # 80008760 <syscalls+0x330>
    80005f80:	ffffa097          	auipc	ra,0xffffa
    80005f84:	5c2080e7          	jalr	1474(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005f88:	00002517          	auipc	a0,0x2
    80005f8c:	7f050513          	addi	a0,a0,2032 # 80008778 <syscalls+0x348>
    80005f90:	ffffa097          	auipc	ra,0xffffa
    80005f94:	5b2080e7          	jalr	1458(ra) # 80000542 <panic>

0000000080005f98 <virtio_disk_init>:
{
    80005f98:	1101                	addi	sp,sp,-32
    80005f9a:	ec06                	sd	ra,24(sp)
    80005f9c:	e822                	sd	s0,16(sp)
    80005f9e:	e426                	sd	s1,8(sp)
    80005fa0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fa2:	00002597          	auipc	a1,0x2
    80005fa6:	7ee58593          	addi	a1,a1,2030 # 80008790 <syscalls+0x360>
    80005faa:	0023f517          	auipc	a0,0x23f
    80005fae:	0fe50513          	addi	a0,a0,254 # 802450a8 <disk+0x20a8>
    80005fb2:	ffffb097          	auipc	ra,0xffffb
    80005fb6:	d08080e7          	jalr	-760(ra) # 80000cba <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fba:	100017b7          	lui	a5,0x10001
    80005fbe:	4398                	lw	a4,0(a5)
    80005fc0:	2701                	sext.w	a4,a4
    80005fc2:	747277b7          	lui	a5,0x74727
    80005fc6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fca:	0ef71163          	bne	a4,a5,800060ac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	43dc                	lw	a5,4(a5)
    80005fd4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fd6:	4705                	li	a4,1
    80005fd8:	0ce79a63          	bne	a5,a4,800060ac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fdc:	100017b7          	lui	a5,0x10001
    80005fe0:	479c                	lw	a5,8(a5)
    80005fe2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fe4:	4709                	li	a4,2
    80005fe6:	0ce79363          	bne	a5,a4,800060ac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fea:	100017b7          	lui	a5,0x10001
    80005fee:	47d8                	lw	a4,12(a5)
    80005ff0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ff2:	554d47b7          	lui	a5,0x554d4
    80005ff6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ffa:	0af71963          	bne	a4,a5,800060ac <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffe:	100017b7          	lui	a5,0x10001
    80006002:	4705                	li	a4,1
    80006004:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006006:	470d                	li	a4,3
    80006008:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000600a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000600c:	c7ffe737          	lui	a4,0xc7ffe
    80006010:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47db875f>
    80006014:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006016:	2701                	sext.w	a4,a4
    80006018:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000601a:	472d                	li	a4,11
    8000601c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000601e:	473d                	li	a4,15
    80006020:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006022:	6705                	lui	a4,0x1
    80006024:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006026:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000602a:	5bdc                	lw	a5,52(a5)
    8000602c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000602e:	c7d9                	beqz	a5,800060bc <virtio_disk_init+0x124>
  if(max < NUM)
    80006030:	471d                	li	a4,7
    80006032:	08f77d63          	bgeu	a4,a5,800060cc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006036:	100014b7          	lui	s1,0x10001
    8000603a:	47a1                	li	a5,8
    8000603c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000603e:	6609                	lui	a2,0x2
    80006040:	4581                	li	a1,0
    80006042:	0023d517          	auipc	a0,0x23d
    80006046:	fbe50513          	addi	a0,a0,-66 # 80243000 <disk>
    8000604a:	ffffb097          	auipc	ra,0xffffb
    8000604e:	dfc080e7          	jalr	-516(ra) # 80000e46 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006052:	0023d717          	auipc	a4,0x23d
    80006056:	fae70713          	addi	a4,a4,-82 # 80243000 <disk>
    8000605a:	00c75793          	srli	a5,a4,0xc
    8000605e:	2781                	sext.w	a5,a5
    80006060:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006062:	0023f797          	auipc	a5,0x23f
    80006066:	f9e78793          	addi	a5,a5,-98 # 80245000 <disk+0x2000>
    8000606a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000606c:	0023d717          	auipc	a4,0x23d
    80006070:	01470713          	addi	a4,a4,20 # 80243080 <disk+0x80>
    80006074:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006076:	0023e717          	auipc	a4,0x23e
    8000607a:	f8a70713          	addi	a4,a4,-118 # 80244000 <disk+0x1000>
    8000607e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006080:	4705                	li	a4,1
    80006082:	00e78c23          	sb	a4,24(a5)
    80006086:	00e78ca3          	sb	a4,25(a5)
    8000608a:	00e78d23          	sb	a4,26(a5)
    8000608e:	00e78da3          	sb	a4,27(a5)
    80006092:	00e78e23          	sb	a4,28(a5)
    80006096:	00e78ea3          	sb	a4,29(a5)
    8000609a:	00e78f23          	sb	a4,30(a5)
    8000609e:	00e78fa3          	sb	a4,31(a5)
}
    800060a2:	60e2                	ld	ra,24(sp)
    800060a4:	6442                	ld	s0,16(sp)
    800060a6:	64a2                	ld	s1,8(sp)
    800060a8:	6105                	addi	sp,sp,32
    800060aa:	8082                	ret
    panic("could not find virtio disk");
    800060ac:	00002517          	auipc	a0,0x2
    800060b0:	6f450513          	addi	a0,a0,1780 # 800087a0 <syscalls+0x370>
    800060b4:	ffffa097          	auipc	ra,0xffffa
    800060b8:	48e080e7          	jalr	1166(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    800060bc:	00002517          	auipc	a0,0x2
    800060c0:	70450513          	addi	a0,a0,1796 # 800087c0 <syscalls+0x390>
    800060c4:	ffffa097          	auipc	ra,0xffffa
    800060c8:	47e080e7          	jalr	1150(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    800060cc:	00002517          	auipc	a0,0x2
    800060d0:	71450513          	addi	a0,a0,1812 # 800087e0 <syscalls+0x3b0>
    800060d4:	ffffa097          	auipc	ra,0xffffa
    800060d8:	46e080e7          	jalr	1134(ra) # 80000542 <panic>

00000000800060dc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060dc:	7175                	addi	sp,sp,-144
    800060de:	e506                	sd	ra,136(sp)
    800060e0:	e122                	sd	s0,128(sp)
    800060e2:	fca6                	sd	s1,120(sp)
    800060e4:	f8ca                	sd	s2,112(sp)
    800060e6:	f4ce                	sd	s3,104(sp)
    800060e8:	f0d2                	sd	s4,96(sp)
    800060ea:	ecd6                	sd	s5,88(sp)
    800060ec:	e8da                	sd	s6,80(sp)
    800060ee:	e4de                	sd	s7,72(sp)
    800060f0:	e0e2                	sd	s8,64(sp)
    800060f2:	fc66                	sd	s9,56(sp)
    800060f4:	f86a                	sd	s10,48(sp)
    800060f6:	f46e                	sd	s11,40(sp)
    800060f8:	0900                	addi	s0,sp,144
    800060fa:	8aaa                	mv	s5,a0
    800060fc:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060fe:	00c52c83          	lw	s9,12(a0)
    80006102:	001c9c9b          	slliw	s9,s9,0x1
    80006106:	1c82                	slli	s9,s9,0x20
    80006108:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000610c:	0023f517          	auipc	a0,0x23f
    80006110:	f9c50513          	addi	a0,a0,-100 # 802450a8 <disk+0x20a8>
    80006114:	ffffb097          	auipc	ra,0xffffb
    80006118:	c36080e7          	jalr	-970(ra) # 80000d4a <acquire>
  for(int i = 0; i < 3; i++){
    8000611c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000611e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006120:	0023dc17          	auipc	s8,0x23d
    80006124:	ee0c0c13          	addi	s8,s8,-288 # 80243000 <disk>
    80006128:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000612a:	4b0d                	li	s6,3
    8000612c:	a0ad                	j	80006196 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000612e:	00fc0733          	add	a4,s8,a5
    80006132:	975e                	add	a4,a4,s7
    80006134:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006138:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000613a:	0207c563          	bltz	a5,80006164 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000613e:	2905                	addiw	s2,s2,1
    80006140:	0611                	addi	a2,a2,4
    80006142:	19690d63          	beq	s2,s6,800062dc <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006146:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006148:	0023f717          	auipc	a4,0x23f
    8000614c:	ed070713          	addi	a4,a4,-304 # 80245018 <disk+0x2018>
    80006150:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006152:	00074683          	lbu	a3,0(a4)
    80006156:	fee1                	bnez	a3,8000612e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006158:	2785                	addiw	a5,a5,1
    8000615a:	0705                	addi	a4,a4,1
    8000615c:	fe979be3          	bne	a5,s1,80006152 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006160:	57fd                	li	a5,-1
    80006162:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006164:	01205d63          	blez	s2,8000617e <virtio_disk_rw+0xa2>
    80006168:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000616a:	000a2503          	lw	a0,0(s4)
    8000616e:	00000097          	auipc	ra,0x0
    80006172:	da8080e7          	jalr	-600(ra) # 80005f16 <free_desc>
      for(int j = 0; j < i; j++)
    80006176:	2d85                	addiw	s11,s11,1
    80006178:	0a11                	addi	s4,s4,4
    8000617a:	ffb918e3          	bne	s2,s11,8000616a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000617e:	0023f597          	auipc	a1,0x23f
    80006182:	f2a58593          	addi	a1,a1,-214 # 802450a8 <disk+0x20a8>
    80006186:	0023f517          	auipc	a0,0x23f
    8000618a:	e9250513          	addi	a0,a0,-366 # 80245018 <disk+0x2018>
    8000618e:	ffffc097          	auipc	ra,0xffffc
    80006192:	2e2080e7          	jalr	738(ra) # 80002470 <sleep>
  for(int i = 0; i < 3; i++){
    80006196:	f8040a13          	addi	s4,s0,-128
{
    8000619a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000619c:	894e                	mv	s2,s3
    8000619e:	b765                	j	80006146 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061a0:	0023f717          	auipc	a4,0x23f
    800061a4:	e6073703          	ld	a4,-416(a4) # 80245000 <disk+0x2000>
    800061a8:	973e                	add	a4,a4,a5
    800061aa:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061ae:	0023d517          	auipc	a0,0x23d
    800061b2:	e5250513          	addi	a0,a0,-430 # 80243000 <disk>
    800061b6:	0023f717          	auipc	a4,0x23f
    800061ba:	e4a70713          	addi	a4,a4,-438 # 80245000 <disk+0x2000>
    800061be:	6314                	ld	a3,0(a4)
    800061c0:	96be                	add	a3,a3,a5
    800061c2:	00c6d603          	lhu	a2,12(a3)
    800061c6:	00166613          	ori	a2,a2,1
    800061ca:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061ce:	f8842683          	lw	a3,-120(s0)
    800061d2:	6310                	ld	a2,0(a4)
    800061d4:	97b2                	add	a5,a5,a2
    800061d6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    800061da:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    800061de:	0612                	slli	a2,a2,0x4
    800061e0:	962a                	add	a2,a2,a0
    800061e2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061e6:	00469793          	slli	a5,a3,0x4
    800061ea:	630c                	ld	a1,0(a4)
    800061ec:	95be                	add	a1,a1,a5
    800061ee:	6689                	lui	a3,0x2
    800061f0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800061f4:	96ca                	add	a3,a3,s2
    800061f6:	96aa                	add	a3,a3,a0
    800061f8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800061fa:	6314                	ld	a3,0(a4)
    800061fc:	96be                	add	a3,a3,a5
    800061fe:	4585                	li	a1,1
    80006200:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006202:	6314                	ld	a3,0(a4)
    80006204:	96be                	add	a3,a3,a5
    80006206:	4509                	li	a0,2
    80006208:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000620c:	6314                	ld	a3,0(a4)
    8000620e:	97b6                	add	a5,a5,a3
    80006210:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006214:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006218:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000621c:	6714                	ld	a3,8(a4)
    8000621e:	0026d783          	lhu	a5,2(a3)
    80006222:	8b9d                	andi	a5,a5,7
    80006224:	0789                	addi	a5,a5,2
    80006226:	0786                	slli	a5,a5,0x1
    80006228:	97b6                	add	a5,a5,a3
    8000622a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000622e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006232:	6718                	ld	a4,8(a4)
    80006234:	00275783          	lhu	a5,2(a4)
    80006238:	2785                	addiw	a5,a5,1
    8000623a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000623e:	100017b7          	lui	a5,0x10001
    80006242:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006246:	004aa783          	lw	a5,4(s5)
    8000624a:	02b79163          	bne	a5,a1,8000626c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000624e:	0023f917          	auipc	s2,0x23f
    80006252:	e5a90913          	addi	s2,s2,-422 # 802450a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006256:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006258:	85ca                	mv	a1,s2
    8000625a:	8556                	mv	a0,s5
    8000625c:	ffffc097          	auipc	ra,0xffffc
    80006260:	214080e7          	jalr	532(ra) # 80002470 <sleep>
  while(b->disk == 1) {
    80006264:	004aa783          	lw	a5,4(s5)
    80006268:	fe9788e3          	beq	a5,s1,80006258 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000626c:	f8042483          	lw	s1,-128(s0)
    80006270:	20048793          	addi	a5,s1,512
    80006274:	00479713          	slli	a4,a5,0x4
    80006278:	0023d797          	auipc	a5,0x23d
    8000627c:	d8878793          	addi	a5,a5,-632 # 80243000 <disk>
    80006280:	97ba                	add	a5,a5,a4
    80006282:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006286:	0023f917          	auipc	s2,0x23f
    8000628a:	d7a90913          	addi	s2,s2,-646 # 80245000 <disk+0x2000>
    8000628e:	a019                	j	80006294 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006290:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006294:	8526                	mv	a0,s1
    80006296:	00000097          	auipc	ra,0x0
    8000629a:	c80080e7          	jalr	-896(ra) # 80005f16 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000629e:	0492                	slli	s1,s1,0x4
    800062a0:	00093783          	ld	a5,0(s2)
    800062a4:	94be                	add	s1,s1,a5
    800062a6:	00c4d783          	lhu	a5,12(s1)
    800062aa:	8b85                	andi	a5,a5,1
    800062ac:	f3f5                	bnez	a5,80006290 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ae:	0023f517          	auipc	a0,0x23f
    800062b2:	dfa50513          	addi	a0,a0,-518 # 802450a8 <disk+0x20a8>
    800062b6:	ffffb097          	auipc	ra,0xffffb
    800062ba:	b48080e7          	jalr	-1208(ra) # 80000dfe <release>
}
    800062be:	60aa                	ld	ra,136(sp)
    800062c0:	640a                	ld	s0,128(sp)
    800062c2:	74e6                	ld	s1,120(sp)
    800062c4:	7946                	ld	s2,112(sp)
    800062c6:	79a6                	ld	s3,104(sp)
    800062c8:	7a06                	ld	s4,96(sp)
    800062ca:	6ae6                	ld	s5,88(sp)
    800062cc:	6b46                	ld	s6,80(sp)
    800062ce:	6ba6                	ld	s7,72(sp)
    800062d0:	6c06                	ld	s8,64(sp)
    800062d2:	7ce2                	ld	s9,56(sp)
    800062d4:	7d42                	ld	s10,48(sp)
    800062d6:	7da2                	ld	s11,40(sp)
    800062d8:	6149                	addi	sp,sp,144
    800062da:	8082                	ret
  if(write)
    800062dc:	01a037b3          	snez	a5,s10
    800062e0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800062e4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800062e8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800062ec:	f8042483          	lw	s1,-128(s0)
    800062f0:	00449913          	slli	s2,s1,0x4
    800062f4:	0023f997          	auipc	s3,0x23f
    800062f8:	d0c98993          	addi	s3,s3,-756 # 80245000 <disk+0x2000>
    800062fc:	0009ba03          	ld	s4,0(s3)
    80006300:	9a4a                	add	s4,s4,s2
    80006302:	f7040513          	addi	a0,s0,-144
    80006306:	ffffb097          	auipc	ra,0xffffb
    8000630a:	f10080e7          	jalr	-240(ra) # 80001216 <kvmpa>
    8000630e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006312:	0009b783          	ld	a5,0(s3)
    80006316:	97ca                	add	a5,a5,s2
    80006318:	4741                	li	a4,16
    8000631a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000631c:	0009b783          	ld	a5,0(s3)
    80006320:	97ca                	add	a5,a5,s2
    80006322:	4705                	li	a4,1
    80006324:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006328:	f8442783          	lw	a5,-124(s0)
    8000632c:	0009b703          	ld	a4,0(s3)
    80006330:	974a                	add	a4,a4,s2
    80006332:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006336:	0792                	slli	a5,a5,0x4
    80006338:	0009b703          	ld	a4,0(s3)
    8000633c:	973e                	add	a4,a4,a5
    8000633e:	058a8693          	addi	a3,s5,88
    80006342:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006344:	0009b703          	ld	a4,0(s3)
    80006348:	973e                	add	a4,a4,a5
    8000634a:	40000693          	li	a3,1024
    8000634e:	c714                	sw	a3,8(a4)
  if(write)
    80006350:	e40d18e3          	bnez	s10,800061a0 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006354:	0023f717          	auipc	a4,0x23f
    80006358:	cac73703          	ld	a4,-852(a4) # 80245000 <disk+0x2000>
    8000635c:	973e                	add	a4,a4,a5
    8000635e:	4689                	li	a3,2
    80006360:	00d71623          	sh	a3,12(a4)
    80006364:	b5a9                	j	800061ae <virtio_disk_rw+0xd2>

0000000080006366 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006366:	1101                	addi	sp,sp,-32
    80006368:	ec06                	sd	ra,24(sp)
    8000636a:	e822                	sd	s0,16(sp)
    8000636c:	e426                	sd	s1,8(sp)
    8000636e:	e04a                	sd	s2,0(sp)
    80006370:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006372:	0023f517          	auipc	a0,0x23f
    80006376:	d3650513          	addi	a0,a0,-714 # 802450a8 <disk+0x20a8>
    8000637a:	ffffb097          	auipc	ra,0xffffb
    8000637e:	9d0080e7          	jalr	-1584(ra) # 80000d4a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006382:	0023f717          	auipc	a4,0x23f
    80006386:	c7e70713          	addi	a4,a4,-898 # 80245000 <disk+0x2000>
    8000638a:	02075783          	lhu	a5,32(a4)
    8000638e:	6b18                	ld	a4,16(a4)
    80006390:	00275683          	lhu	a3,2(a4)
    80006394:	8ebd                	xor	a3,a3,a5
    80006396:	8a9d                	andi	a3,a3,7
    80006398:	cab9                	beqz	a3,800063ee <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000639a:	0023d917          	auipc	s2,0x23d
    8000639e:	c6690913          	addi	s2,s2,-922 # 80243000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063a2:	0023f497          	auipc	s1,0x23f
    800063a6:	c5e48493          	addi	s1,s1,-930 # 80245000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063aa:	078e                	slli	a5,a5,0x3
    800063ac:	97ba                	add	a5,a5,a4
    800063ae:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800063b0:	20078713          	addi	a4,a5,512
    800063b4:	0712                	slli	a4,a4,0x4
    800063b6:	974a                	add	a4,a4,s2
    800063b8:	03074703          	lbu	a4,48(a4)
    800063bc:	ef21                	bnez	a4,80006414 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063be:	20078793          	addi	a5,a5,512
    800063c2:	0792                	slli	a5,a5,0x4
    800063c4:	97ca                	add	a5,a5,s2
    800063c6:	7798                	ld	a4,40(a5)
    800063c8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063cc:	7788                	ld	a0,40(a5)
    800063ce:	ffffc097          	auipc	ra,0xffffc
    800063d2:	222080e7          	jalr	546(ra) # 800025f0 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063d6:	0204d783          	lhu	a5,32(s1)
    800063da:	2785                	addiw	a5,a5,1
    800063dc:	8b9d                	andi	a5,a5,7
    800063de:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063e2:	6898                	ld	a4,16(s1)
    800063e4:	00275683          	lhu	a3,2(a4)
    800063e8:	8a9d                	andi	a3,a3,7
    800063ea:	fcf690e3          	bne	a3,a5,800063aa <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063ee:	10001737          	lui	a4,0x10001
    800063f2:	533c                	lw	a5,96(a4)
    800063f4:	8b8d                	andi	a5,a5,3
    800063f6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063f8:	0023f517          	auipc	a0,0x23f
    800063fc:	cb050513          	addi	a0,a0,-848 # 802450a8 <disk+0x20a8>
    80006400:	ffffb097          	auipc	ra,0xffffb
    80006404:	9fe080e7          	jalr	-1538(ra) # 80000dfe <release>
}
    80006408:	60e2                	ld	ra,24(sp)
    8000640a:	6442                	ld	s0,16(sp)
    8000640c:	64a2                	ld	s1,8(sp)
    8000640e:	6902                	ld	s2,0(sp)
    80006410:	6105                	addi	sp,sp,32
    80006412:	8082                	ret
      panic("virtio_disk_intr status");
    80006414:	00002517          	auipc	a0,0x2
    80006418:	3ec50513          	addi	a0,a0,1004 # 80008800 <syscalls+0x3d0>
    8000641c:	ffffa097          	auipc	ra,0xffffa
    80006420:	126080e7          	jalr	294(ra) # 80000542 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
