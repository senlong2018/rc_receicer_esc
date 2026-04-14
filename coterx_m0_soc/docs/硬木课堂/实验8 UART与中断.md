<font style="color:#24292E;">本小节添加UART外设模块实验为基础，讲解CPU的中断处理以及使用C语言高效地编程。</font>
<font style="color:#24292E;">根据ARMv6-M架构参考手册以及Cortex-M0用户手册，CPU中断处理过程如下：</font>

+ <font style="color:#24292E;">CPU接收到中断信号（IRQ、NMI、Systick等等）</font>
+ <font style="color:#24292E;">将R0,R1,R2,R3,R12,LR,PC,xPSR寄存器入栈，如下图</font>
  
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166709682-f27b7f2c-c705-4b82-88fc-036bb625fc99.png" width="647" title="" crop="0,0,1,1" id="GLWD2" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图 寄存器入栈</font>_
+ <font style="color:#24292E;">根据中断信号查找中断向量表（对应汇编启动代码中的__Vector段），跳转至中断处理函数，如下图</font>
  
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166710181-1e5e9182-ff7f-44dc-bba8-f391bfd1645f.png" width="1064" title="" crop="0,0,1,1" id="luPeG" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图 中断向量表</font>_
+ <font style="color:#24292E;">中断处理函数执行完成后，利用链接寄存器返回，寄存器出栈，PC跳转；</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">本实验最终实现的SoC如图3-43所示。</font>
  
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166710731-deba079d-6f49-4b79-bd4c-407943a61022.png" width="911" title="" crop="0,0,1,1" id="GVZmd" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3 本实验实现的SoC</font>_
  # 硬件部分
  <font style="color:#24292E;">UART外设主要由三部分组成：</font>
+ <font style="color:#24292E;">UARTRX：用于接收数据，数据接收完成后向总线输入接收到的数据值并向IRQ中断产生一个时钟周期的脉冲。</font>
+ <font style="color:#24292E;">UARTTX：用于发送数据，内部包含有一个缓冲器（FIFO）用以缓冲总线传来的数据，并通过总线提供FIFO满状态的状态寄存器，CPU需要根据此寄存器判断是否可写。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">UART对应着总线上三个寄存器，及三个word的地址空间，三个寄存器格式如下图所示。</font>
  
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166711230-9da0a769-c6e3-48a8-884e-964af2a64bd2.png" width="819" title="" crop="0,0,1,1" id="X8sN8" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图 UART寄存器格式</font>_
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">UART具体代码提供在”/Task3/rtl/”文件夹下，请读者自行阅读，UART结构如下图所示。</font>
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166711484-a69ea059-53e0-4a73-aa7a-f55783eb1900.png" width="564" title="" crop="0,0,1,1" id="j45qv" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图 UART模块结构图</font>_
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">将UART作为外设连接在总线外设P3端口，首先需要在Decoder中将P3的译码比较器添加进去，并在端口参数处将其使能；在顶层模块中已经完成例化UART各个模块以及总线接口，只需要将其总线接口与总线扩展模块P3端口连接。具体步骤与实验一、实验二相同，不再赘述。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">最后，将UART连接上IRQ中断。</font>
  ```plain
  /*Connect the IRQ with UART*/
  assign IRQ = 32'b0;
  /***************************/
  ```
  _改为：_
  ```plain
  /*Connect the IRQ with UART*/
  assign IRQ = {31'b0,interrupt_UART};
  /***************************/
  ```
  <font style="color:#24292E;">在TD约束文件的基础上增加UART管脚的约束。</font>
  ```plain
  set_pin_assignment { RSTn } { LOCATION = A9; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { SWCLK } { LOCATION = R2; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { SWDIO } { LOCATION = P2; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { clk } { LOCATION = R7; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { TXD } { LOCATION = D12; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { RXD } { LOCATION = F12; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LED[0] } { LOCATION = B14; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LED[1] } { LOCATION = B15; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LED[2] } { LOCATION = B16; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LED[3] } { LOCATION = C15; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LED[4] } { LOCATION = C16; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LED[5] } { LOCATION = E13; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LED[6] } { LOCATION = E16; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LED[7] } { LOCATION = F16; IOSTANDARD = LVCMOS33; }
  set_pin_assignment { LEDclk } { LOCATION = T4; IOSTANDARD = LVCMOS33; }
  ```
  # 启动代码与C语言编程
  <font style="color:#24292E;">我们需要根据CMSIS提供的启动代码重新完成自己的启动代码，具体代码见“/Task3/keil/startup_CMSDK_CM0.s”。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">与之前的汇编代码不同的是，我们在复位处理函数内调用了__mian函数，此函数的作用是将堆栈初始化后跳转至C语言中的mian函数，而最后一段__user_initial_stackheap则是初始化堆栈过程的一部分。初始化堆栈的具体过程由编译器提供，无需人为添加。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">在中断处理的地方可以看到，当UART中断发生后，CPU会根据__Vector中的中断地址跳转到UART中断处理函数，在这个函数里面，首先人为地将寄存器入栈，然后跳转至C语言中的UARTHandle函数，执行完成后寄存器出栈并返回。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">然后，我们需要定义外设的地址，以及自己实现的函数，参考CMSIS编写自己头文件。具体代码见“/Task3/keil/code_def.h”。</font>
  ```plain
  #include <stdint.h>
  ……
  //UART DEF
  typedef struct{
  volatile uint32_t UARTRX_DATA;
  volatile uint32_t UARTTX_STATE;
  volatile uint32_t UARTTX_DATA;
  }UARTType;
  #define UART_BASE 0x40000010
  #define UART ((UARTType *)UART_BASE)
  void SetWaterLightMode(int mode);
  ……
  ```
  <font style="color:#24292E;">第一行<stdint.h>头文件提供了结构体以及结构体运算符”->”的支持，高效地利用结构体定义外设地址，能够有效地减少代码量，节约存储空间。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">下面以UART为例讲解结构体与基地址的使用。首先我们根据之前UART硬件部分设计，UART在地址空间能有三个寄存器，分别为UARTRX_DATA、UARTTX_STATE、UARTTX_DATA，它们的地址分别为0x40000010、0x40000014、0x40000018。三个寄存器在内存空间中是连续的三个字（word），因此在结构体中定义三个寄存器时需要按照它们地址的顺序依次定义，并且类型为32bit的uint32_t。之后再定义UART的基地址为0x40000010。这样一来，当我们使用结构体中第一个元素时，它的地址则为基地址+0；第二个地址为基地址+4；第三个地址为基地址+8依次类推。完全符合我们在硬件时定义的地址。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">然后，我们需要完成函数的实现，具体见“/Task3/keil/code_def.c”</font>
  ```plain
  #include "code_def.h"
  #include <string.h>
  ……
  char ReadUARTState()
  {
  char state;
  state = UART -> UARTTX_STATE;
  return(state);
  }
  char ReadUART()
  {
  char data;
  data = UART -> UARTRX_DATA;
  return(data);
  }
  void WriteUART(char data)
  {
  while(ReadUARTState());
  UART -> UARTTX_DATA = data;
  }
  void UARTString(char *stri)
  {
  int i;
  for(i=0;i<strlen(stri);i++)
  {
  WriteUART(stri[i]);
  }
  }
  void UARTHandle()
  {
  int data;
  data = ReadUART();
  UARTString("Cortex-M0 : ");
  WriteUART(data);
  WriteUART('\n');
  }
  ```
  <font style="color:#24292E;">在实现UART打印字符串时，我们并没有使用常见的重定向printf、scanf函数来实现，而是通过自己编写UARTString函数来实现。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">需要注意的时，在WriteUART函数里面，我们首先调用的时ReadUARTState函数，通过这个函数读取UART发送端口缓冲区是否为满，（满为1，否则为0），只有当其缓冲器未满时才进行写操作。</font>
  <font style="color:#24292E;">最后，编写主文件,具体在“/Task3/keil/main.c”。</font>
  ```plain
  #include "code_def.h"
  #include <string.h>
  #include <stdint.h>
  ……
  int main()
  { 
  //interrupt initial
  NVIC_CTRL_ADDR = 1;
  //UART display
  UARTString("Cortex-M0 Start up!\n");
  ……
  }
  ```
  <font style="color:#24292E;">在main函数中，首先对中断使能进行设置，相关知识请读者阅读相关手册文档，然后使用UART打印“Cortex-M0 Start up”字符串，然后进入流水灯控制，在每次改变流水灯模式后都用UART打印一串字符。</font>
  # 调试与运行
  <font style="color:#24292E;">打开Keil工程将编写好的文件添加至工程中，并在如下图所示的设置中取消勾选“Don’t Search Standard Libraries”，然后编译。</font>
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166711734-b8bb55f7-f31b-444c-b338-d30dc35f4ab9.png" width="641" title="" crop="0,0,1,1" id="AFAEt" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图 取消勾选</font>_
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">在TD中添加UART相关的verilog文件至工程中，在管脚约束中添加RXD与TXD，综合布局布线并生成比特流文件，下载至FPGA中。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">打开串口调试软件与Keil，在Keil中点击开始调试，并开始连续运行，观察串口调试软件信息:</font>
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166711958-6a288d8c-28e2-47df-af78-ae217ee6d619.png" width="956" title="" crop="0,0,1,1" id="FjD9v" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图 UART接收信息</font>_
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">可以看到，CPU启动后正常运行了程序，在通过串口调试软件向CPU发送字符后能成功显示字符串，说明UART中断设置成功。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">注意，本例中使用的UART来自于EG4S20板上的UART2USB接口，插上USB线连接后，安装CH340驱动，电脑会识别到USB-SERIAL CH340 (COMxx):</font>
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166712937-0890b5bb-27cc-4f42-bc79-2a9b5a9adafe.png" width="956" title="" crop="0,0,1,1" id="CLGsx" class="ne-image" style="font-size: 16px">
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649166713547-72d9d4b8-4766-40df-a2cd-94d80d52bda5.png" width="262" title="" crop="0,0,1,1" id="BMIc0" class="ne-image" style="font-size: 16px">

---

# 硬木课堂实验平台常见问题汇总 FAQ

[目录-常见问题汇总 FAQ](https://www.yuque.com/yingmuketang/01/rma2p4)

# 硬木课堂配件网购推荐

[硬木课堂配件网购推荐](https://www.yuque.com/yingmuketang/01/dqmgx0)
---

# 关注硬木课堂

硬木课堂是致力于传播电子技术相关知识的平台，围绕旗下自主知识产权的硬木课堂全功能个人实验平台，打造随时随地动手实践的新学习方法并提供一系列的配套资源。
关注微信公众号，获取**板卡引脚分配图表、源代码和实验教程**，关注Bilibili视频站，**配套视频教程持续更新中**。

+ **微信公众号**：硬木课堂 <font style="color:rgb(53, 53, 53);">（e-labs）</font>
  <img src="https://cdn.nlark.com/yuque/0/2021/png/23019172/1637915212423-e7dc19be-fd80-421a-b8a5-adda96035560.png" width="317.75" title="" crop="0,0,1,1" id="ByGHZ" class="ne-image" style="font-size: 16px">
+ **知识库**：硬木课堂知识库 [https://www.yuque.com/yingmuketang/01](https://www.yuque.com/yingmuketang/01)
+ **B站**：硬木课堂 [https://space.bilibili.com/506069950](https://space.bilibili.com/506069950)
+ **官网**：[http://www.emooc.cc/](http://www.emooc.cc/)
