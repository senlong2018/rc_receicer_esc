实验2和实验3的实验视频请查看：
[bilibili](https://player.bilibili.com/player.html?bvid=BV1ea4y187YX&autoplay=0)

# 1. 任务简介

在上个实验中，我们搭建了一个最简单的 SoC 系统，它仅包含了 Cortex-M0 处理器内核和一个用于存储指令代码的 RAM 存储器。在本次实验中，我们将完成如下图所示的SoC设计。
我们先介绍如通过 AHBlite 总线添加数据存储器，再介绍如何通过 AHBlite 总线给 SoC 添加外设，最后通过对比两种不同的方式实现流水灯功能，理解软硬件结合和控制字的概念。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155305460-b882fbfe-b219-4f0c-b913-255b7a8c5db8.png" width="832" title="" crop="0,0,1,1" id="ueed55a95" class="ne-image">

# 2. 添加数据存储器

数据存储器对于 SoC 系统非常重要。数据存储器不仅用来运算的数据，还在程序跳转、异常处理的过程中发挥重要作用。直接使用寄存器存储数据显然是不现实的，有处理器内核和指令存储器SoC能执行指令和利用内部的寄存器存储数据，数据存储器特定的一段地址空间会被编译器分配为栈存储空间。因此，在一个能够执行复杂程序的系统中，必须拥有数据存储器。
首先，在顶层模块中需要连接RAMDATA 总线接口以及对应的 Block RAM，将 RAMDATA 总线接口接入总线扩展模块中预留的 P1 接口。

```plain
Block_RAM RAM_DATA(
 .clka (clk),
 .addra (RAMDATA_WADDR),
 .addrb (RAMDATA_RADDR),
 .dina (RAMDATA_WDATA),
 .doutb (RAMDATA_RDATA),
 .wea (RAMDATA_WRITE)
);
AHBlite_Block_RAM RAMDATA_Interface(
 /* Connect to Interconnect Port 1 */
 .HCLK (clk),
 .HRESETn (cpuresetn),
 .HSEL (HSEL_P1),
 .HADDR (HADDR_P1),
 .HPROT (HPROT_P1),
 .HSIZE (HSIZE_P1),
 .HTRANS (HTRANS_P1),
 .HWDATA (HWDATA_P1),
 .HWRITE (HWRITE_P1),
 .HRDATA (HRDATA_P1),
 .HREADY (HREADY_P1),
 .HREADYOUT (HREADYOUT_P1),
 .HRESP (HRESP_P1),
 .BRAM_RDADDR (RAMDATA_RADDR),
 .BRAM_WRADDR (RAMDATA_WADDR),
 .BRAM_RDATA (RAMDATA_RDATA),
 .BRAM_WDATA (RAMDATA_WDATA),
 .BRAM_WRITE (RAMDATA_WRITE)
 /**********************************/
);
```

接下来，我们需要在硬件译码模块”AHBlite_Decoder.v“中找到RAMDATA（Port 1）端口并将其使能。

```plain
/*RAMCODE enable parameter*/
parameter Port0_en = 1,
/************************/
```

根据存储系统所述的 memory map 推荐地址分配，我们在地址 0x20000000分配了一个 512KB 的 RAMDATA。所以 RAMDATA 的总线编码为 0x20000000-0x2000ffff，因为对于一次总线操作，只要地址总线的高 16 位为 0x2000，则 Decoder 认为这是一次对数据存储器的操作，进而生成数据存储器总线选择信号。在译码部分插入 RAMDATA 的译码器代码。

```plain
//RAMDATA-----------------------------
//0X20000000-0X2000FFFF
/*Insert RAMDATA decoder code there*/
assign P1_HSEL = (HADDR[31:16] == 16'h2000) ? Port1_en : 1'b0;
/***********************************/
```

紧接着我们要对存储器进行初始化，我们借助于readmemh函数，将keil编译生成的机器码，初始化到程序 RAM中。即在Block_RAM.v文件中修改初始化函数中的文件路径，使得编译器能够找到code.hex文件。

```plain
initial begin
 $readmemh("D:/YOUR_PATH/code.hex",mem);
end
```

至此，我们就完成了 RAMDATA 部分的修改，接下来，我们就进行外设 GPIO 的介绍,完成对GPIO外设的添加。

# 3. 添加GPIO外设实现流水灯

GPIO（General Purpose I/O Ports）意思为通用输入/输出端口，通俗地说，就是一些引脚，可以通过它们输出高低电平或者通过它们读入引脚的状态-是高电平或是低电平。GPIO口一是个比较重要的概念，用户可以通过GPIO口和硬件进行数据交互(如UART)，控制硬件工作(如LED、蜂鸣器等),读取硬件的工作状态信号（如中断信号）等。GPIO口的使用非常广泛。
设计 GPIO 外设的目的就是为了提高 SoC 系统的通用性。以单片机这一 SoC 系统为例，单片机作为工业设备的控制核心，往往需要驱动不同的芯片，这些芯片的通信协议各不相同，SoC 设计人员不可能把每一种芯片的通信协议都制作成硬件的形式集成在 SoC 中。因此，设计 GPIO 外设，让编程人员通过处理器控制 GPIO 接口模拟各个驱动芯片的通信时序以达到驱动各个外部芯片的功能。GPIO 接口能够避免没有特殊芯片的通信时序的尴尬。
如果熟悉单片机的同学，就会知道，几乎所有的单片机都具有 GPIO 接口。在一些单片机中，GPIO 接口还可以配置连接到处理器的 IRQ 中断上，允许 SoC 系统外的电平信号触发中断。
处理器通过总线给固定的地址写入一个字长数据，这个数据用于控制总线外部硬件电路就被称为控制字。本次设计的 GPIO 模块就包含了 3 个控制字，一个是 oData用于控制 GPIO 的引脚输出的电平，另一个是 iData 用于表明 GPIO 引脚输入的电平，最后一个是 outEn 用于控制 GPIO 的输入输出状态。
接下来，将介绍如何将 GPIO 集成到 SoC 系统中，并且使用软件编程控制它实现流水灯的功能。
与之前添加存储器同理，向 SoC 中添加 GPIO，参考添加 RAMCODE 步骤。在顶层模块中添加好 GPIO 总线接口以及对应的硬件代码，再完成将流水灯总线接口接入总线扩展模块中预留的 P4 接口。

```plain
GPIO GPIO(
 .outEn(outEn),
 .oData(oData),
 .iData(iData),
 .clk(clk),
 .RSTn(cpuresetn),
 .ioPin(ioPin)
);
AHBlite_GPIO GPIO_Interface(
 /* Connect to Interconnect Port 4 */
 .HCLK (clk),
 .HRESETn (cpuresetn),
 .HSEL (HSEL_P4),
 .HADDR (HADDR_P4),
 .HPROT (HPROT_P4),
 .HSIZE (HSIZE_P4),
 .HTRANS (HTRANS_P4),
 .HWDATA (HWDATA_P4),
 .HWRITE (HWRITE_P4),
 .HRDATA (HRDATA_P4),
 .HREADY (HREADY_P4),
 .HREADYOUT (HREADYOUT_P4),
 .HRESP (HRESP_P4),
 .outEn (outEn),
 .oData (oData),
 .iData (iData)
 /**********************************/ 
);
```

接下来，我们需要在硬件译码模块”AHBlite_Decoder.v“中找到RAMDATA（Port 1）端口并将其使能。

```plain
 /*GPIO enable parameter*/
 parameter Port4_en=1
 /************************/
```

本次实验给 GPIO 的三个控制字分配地址空间如下：输出数据寄存器 oData 的地址为 0x40000020，输入数据寄存器 iData 的地址为 0x40000024，输出使能寄存器 outEn 的地址为 0x40000028。因为对于一次总线操作，只要地址总线的高 28 位为 0x4000002，则 Decoder 认为这是一次对 GPIO 的操作，进而生成 GPIO 总线选择信号。在译码部分插入 GPIO 的译码器代码。

```plain
//0x40000028 OUT ENABLE
//0X40000024 IN DATA
//0X40000020 OUT DATA
/*Insert GPIO decoder code there*/
assign P4_HSEL = (HADDR[31:4] == 28'h4000002) ? Port4_en : 1'd0;
/***********************************/
```

**三、添加GPIO汇编代码**
新建 keil 工程，编写汇编程序使流水灯工作。在“startup_CMSDK_CM0.s”文件中，程序进入 GPIO 段后，R2 的存储 GPIO 输出寄存器的地址，R3 存储 GPIO 输入寄存器地址，R4 存储输入/输出模式控制寄存器地址，R1 存储计数器时间。
我们设计的 8 个 GPIO 端口实现流水灯功能，其程序流程如下：
1） 配置 GPIO 为输出模式；
2） 往 oData 控制寄存器写入 0x01 点亮右边第一个灯并且延迟一定时间；
3） 将 0x01 左移一位（即 0x02）写入 oData 寄存器中，并且延迟一定时间;
4） 重复第 2、第 3 步，第 8 个灯点亮之后，再次跳转到第 2 步。
需要注意的是，为了方便仿真观察，我们将延迟的间隔时间设置得非常小，在接下来的上板调试时，需要重新修改 R0 的值，使流水灯模式转换时间保持在 1s 左右。在汇编文件中补充代码段，实现往右流的流水灯功能，并且利用 R1 计数至 16 后返回实现 delay 功能。 

```plain
 PRESERVE8
 THUMB
 AREA RESET, DATA, READONLY
 EXPORT __Vectors
__Vectors DCD 0x20000000 ; Top of Stack
 DCD Reset_Handler ; Reset Handler
 DCD 0 ; NMI Handler
 DCD 0 ; Hard Fault Handler
 DCD 0 ; Reserved
 DCD 0 ; Reserved
 DCD 0 ; Reserved
 DCD 0 ; Reserved
 DCD 0 ; Reserved
 DCD 0 ; Reserved
 DCD 0 ; Reserved
 DCD 0 ; SVCall Handler
 DCD 0 ; Reserved
 DCD 0 ; Reserved
 DCD 0 ; PendSV Handler
 DCD 0 ; SysTick Handler
 DCD 0 ; IRQ0 Handler
 AREA |.text|, CODE, READONLY
; Reset Handler
Reset_Handler PROC
 GLOBAL Reset_Handler
 ENTRY
 LDR R2, =0x40000020 ;R2 GPIO OUT reg addr
 ADDS R3, R2, #4 ;R3 GPIO IN reg addr
 ADDS R4, R3, #4 ;R4 GPIO OUTen reg addr
GPIO LDR R6, =0x00 ;GPIO INPUT ENABLE VALUE
 STR R6, [R4] ;Set input ENABLE
 LDR R5, [R3] ;read GPIO value
 LDR R6, =0x01 ;GPIO OUTPUT ENABLE VALUE
 STR R6, [R4] ;Set OUTPUT ENABLE
 LDR R6, =0X01 ;GPIO_0 Set value
 STR R6, [R2] ;store
 MOVS R1, #1 ;Interval cnt initial
 BL delay
 LDR R6, =0X02 ;GPIO_1 Set value
 STR R6, [R2] ;store
 MOVS R1, #1 ;Interval cnt initial
 BL delay
 LDR R6, =0X04 ;GPIO_2 Set value
 STR R6, [R2] ;store
 MOVS R1, #1 ;Interval cnt initial
 BL delay
 LDR R6, =0X08 ;GPIO_3 Set value
 STR R6, [R2] ;store
 MOVS R1, #1 ;Interval cnt initial
 BL delay
 LDR R6, =0X10 ;GPIO_4 Set value
 STR R6, [R2] ;store
 MOVS R1, #1 ;Interval cnt initial
 BL delay
 LDR R6, =0X20 ;GPIO_5 Set value
 STR R6, [R2] ;store
 MOVS R1, #1 ;Interval cnt initial
 BL delay
 LDR R6, =0X40 ;GPIO_6 Set value
 STR R6, [R2] ;store
 MOVS R1, #1 ;Interval cnt initial
 BL delay
 LDR R6, =0X80 ;GPIO_7 Set value
 STR R6, [R2] ;store
 MOVS R1, #1 ;Interval cnt initial
 BL delay
 B GPIO
delay ADDS R1,R1,#1
 LDR R0,=0X600000
 CMP R0,R1
 BNE delay
 BX LR
```

使用keil生成二进制文件后，记得将生成文件“code.hex”放在上文所说的数据存储器地址位置。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155047282-46259942-3f64-49c6-9f46-db2d73d4d421.png" width="1077" title="" crop="0,0,1,1" id="d69AZ" class="ne-image" style="font-size: 16px">

# 4. 上板调试

将新编写的 verilog 文件添加进 TD工程中，将 GPIO[0:7]分配到开发的 LED0-LED7上，同时为了验证输入功能将 GPIO7 约束到开关 SW1 上，综合布局布线后生成比特流文件并下载进 FPGA 中。
创建管脚约束文件“pin.adc”，内容如下。

```plain
set_pin_assignment { RSTn } { LOCATION = A9; IOSTANDARD = LVTTL33; }
set_pin_assignment { SWCLK } { LOCATION = R2; IOSTANDARD = LVTTL33; }
set_pin_assignment { SWDIO } { LOCATION = P2; IOSTANDARD = LVTTL33; }
set_pin_assignment { clk } { LOCATION = R7; IOSTANDARD = LVTTL33; }
set_pin_assignment { ioPin[0] } { LOCATION = B14; IOSTANDARD = LVTTL33; }
set_pin_assignment { ioPin[1] } { LOCATION = B15; IOSTANDARD = LVTTL33; }
set_pin_assignment { ioPin[2] } { LOCATION = B16; IOSTANDARD = LVTTL33; }
set_pin_assignment { ioPin[3] } { LOCATION = C15; IOSTANDARD = LVTTL33; }
set_pin_assignment { ioPin[4] } { LOCATION = C16; IOSTANDARD = LVTTL33; }
set_pin_assignment { ioPin[5] } { LOCATION = E13; IOSTANDARD = LVTTL33; }
set_pin_assignment { ioPin[6] } { LOCATION = E16; IOSTANDARD = LVTTL33; }
set_pin_assignment { ioPin[7] } { LOCATION = F16; IOSTANDARD = LVTTL33; }
```

打开Anlogic TD，创建new project。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155047742-bd8771f8-5f7d-4bad-aa84-c0d8a8b2f42a.png" width="1277" title="" crop="0,0,1,1" id="Uv5TX" class="ne-image" style="font-size: 16px">
如图所示创建新工程，路径自行进行更改。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155047955-07ada497-b7af-459d-ac5d-7528f0e01b9d.png" width="500" title="" crop="0,0,1,1" id="tlyRm" class="ne-image" style="font-size: 16px">
分别添加RTL文件和管脚约束文件。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155048309-8b777d16-7d41-48ae-8486-ec81b4b50cab.png" width="1278" title="" crop="0,0,1,1" id="hIoc2" class="ne-image" style="font-size: 16px">
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155048803-f0ca3f5d-e4a3-4fb5-b02d-5553d58466aa.png" width="1271" title="" crop="0,0,1,1" id="zMD28" class="ne-image" style="font-size: 16px">
所需文件均添加完成后，点击run按钮进入自动流程。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155049253-92f15a1d-b8e7-42e4-afb8-0450bd906ed6.png" width="1278" title="" crop="0,0,1,1" id="yEowV" class="ne-image" style="font-size: 16px">
左下角所有流程均成功通过打勾时，将开发板的JTAG接口与电脑相连接，这时可以点击”Download”将比特流下载到开发板上了。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155049913-67275e1d-a5f5-44d8-84ea-19a69d558d80.png" width="650" title="" crop="0,0,1,1" id="dOLkd" class="ne-image" style="font-size: 16px">
点击add将刚刚生成的比特流加入列表，随后点击“run”按钮即可下载。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155050459-10cc543e-4c14-44c6-9c62-fa237be7df35.png" width="1095" title="" crop="0,0,1,1" id="jbTOD" class="ne-image" style="font-size: 16px">
在程序全部成功编译并download之后，需要进入keil调试模式运行一次之后退出调试模式，此时程序成功下载到板子上。
调试方法如下：
新建keil5的project，将编写好的文件添加至工程中，设置如下：
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155050996-13da2d30-f480-40c4-901b-1bbb9877e112.png" width="782" title="" crop="0,0,1,1" id="bbY8M" class="ne-image" style="font-size: 16px">
点击setting，查看是否检测到调试DAP接口：
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155051517-314716c9-18c0-4d9a-bdfa-b25712c3df39.png" width="778" title="" crop="0,0,1,1" id="RMYPZ" class="ne-image" style="font-size: 16px">
点击开始调试按钮。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155052026-d86d215f-01c2-4bc4-ba59-2c87a0e240f1.png" width="1095" title="" crop="0,0,1,1" id="iR2UA" class="ne-image" style="font-size: 16px">
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649155052491-6527660e-0e78-4717-bdbb-e5482fc093a6.png" width="1095" title="" crop="0,0,1,1" id="hPV6g" class="ne-image" style="font-size: 16px">
此时，可以看到开发板上成功亮起流水灯。

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
  <img src="https://cdn.nlark.com/yuque/0/2021/png/23019172/1637915212423-e7dc19be-fd80-421a-b8a5-adda96035560.png" width="317.75" title="" crop="0,0,1,1" id="ByGHZ" class="ne-image">
+ **知识库**：硬木课堂知识库 [https://www.yuque.com/yingmuketang/01](https://www.yuque.com/yingmuketang/01)
+ **B站**：硬木课堂 [https://space.bilibili.com/506069950](https://space.bilibili.com/506069950)
+ **官网**：[http://www.emooc.cc/](http://www.emooc.cc/)
