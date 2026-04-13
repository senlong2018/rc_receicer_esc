在本实验中，我们将以安路的设计软件TangDynasty（TD）为平台，利用AHBlite总线将Block RAM与Cortex-M0裸核相连接，搭建一个SoC下载到安路FPGA开发板中，并编写简单的汇编代码，利用Keil在SoC平台上进行调试运行。
本实验的配套视频解说请在以下网址观看：
[（集创赛）Cortex-M0软件开发与Keil开发工具实战介绍 - 极术社区 - 连接开发者与智能计算生态](https://aijishu.com/l/1110000000104544)

# 硬件原理

## 1. SoC组成

图1-1为本实验需要实现的SoC架构示意图。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153488427-bd881dd3-b655-461a-98b2-ff50848f1bdd.png" width="818" title="" crop="0,0,1,1" id="mSBBt" class="ne-image" style="font-size: 16px">
_<font style="color:#595959;">图1-1 本实验实现的简单SoC</font>_
Cortex-M0 处理器基于冯诺依曼架构（单总线接口），使用32位精简指令集（RISC），该指令集被称为Thumb指令集。如图3-6所示为基于Cortex-M0的SoC基本架构图，可以看到其可以分为Corte-M0处理器核心（Core）、总线接口（Bus Matrix）、<font style="color:#000000;">嵌套向量中断控制</font>器（NVIC）、调试子系统4个部分。
AHB-Lite总线是AHB总线的简化版本。由于Cortex-M0处理器设计是用来做简单的控制的，所以只设计支持了简单的AHB-Lite总线。AHB-Lite总线只支持一个AHB主机。
BRAM是存放SoC需要调用的指令的存储器，其通过BRAM总线接口与AHBlite总线相连接。

## 2. 硬件代码

本节中涉及的可以展示的硬件代码功能如下。

### 2.1 cortexm0ds_logic.v

本模块从ARM DesignStart申请获得，是Cortex-M0裸核网表形式的Verilog代码，这里不与展示。

### 2.2 AHBlite_Decoder.v

本模块是AHBlite总线译码模块，我们预留了四个从机的总线端口，选择Port0端口作为存储指令的BRAM端口，指定BRAM所占据的地址空间为0x00000000到0x0000ffff。

### 2.3 AHBlite_SlaveMUX.v

本模块是<font style="color:#24292E;">用于选择从机，包含几个多路复用器，用于选择对应从机的控制信号和数据通路。</font>

### 2.4 AHBlite_Interconnect.v

本模块是实现AHBlite总线的关键模块，其例化了AHBlite_Decoder和AHBlite_SlaveMUX模块，将主机的地址总线、数据总线、控制总线与四个从机的对应总线相连。

### 2.5 Block_RAM.v

本模块生成一个提前输入了SoC能识别的指令机器码（hex）的、大小为4096*32的BRAM，**<font style="color:#FF0000;">其读取的机器码需要由Keil根据软件内容编译出，我们会在软件部分2.3节讲解机器码的生成方式。注意需要修改代码指向您电脑上的hex文件。</font>**

### 2.6 AHBlite_Block_RAM.v

本模块是BRAM与AHBlite总线的接口，用于联络选中该从机后的总线并控制BRAM中数据的读写。

### 2.7 CortexM0_SoC.v

本模块是实验需要实现的SoC的顶层文件，调用了Cortex-M0裸核、AHBlite总线、Block_RAM和其与总线的接口模块，将外界的时钟信号、复位信号、调试接口与芯片相连接。

## 3. 关键硬件代码解析

<font style="color:#24292E;">我们要搭建如图3-1所示的简单SoC，总共需要完成修改两个个部分的硬件设计：</font>

+ <font style="color:#24292E;">在顶层文件中将RAMCODE总线接口与总线扩展模块连接</font>
+ <font style="color:#24292E;">在总线扩展模块中的Decoder内添加对应的译码电路</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">第一步，在“CortexM0_SoC/Task1/rtl/AHBlite_Decoder.v”文件中修改Decoder模块代码。</font>
1. <font style="color:#24292E;">在端口参数部分，令RAMCODE使能有效。</font>
   
   ```plain
   /*RAMCODE enable parameter*/
   parameter Port0_en = 0,
   /************************/
   ```
   
   _改为：_
   
   ```plain
   /*RAMCODE enable parameter*/
   parameter Port0_en = 1,
   /************************/
   ```
2. <font style="color:#24292E;">根据第二章所述的memory map，RAMCODE的总线编码为0x00000000-0x0000ffff，因为对于一次总线操作，只要地址总线的高16位为0，则Decoder认为这是一次对指令存储器的操作，进而生成指令存储器总线选择信号。在译码部分插入RAMCODE的译码器代码。</font>
   
   ```plain
   //0x00000000-0x0000ffff
   /*Insert RAMCODE decoder code there*/
   assign P0_HSEL = 1’b0;
   /***********************************/
   ```
   
   _改为：_
   
   ```plain
   //0x00000000-0x0000ffff
   /*Insert RAMCODE decoder code there*/
   assign P0_HSEL = (HADDR[31:16] == 16'h0000) ? Port0_en : 1'b0; 
   /***********************************/
   ```
   
   <font style="color:#24292E;">第二步，在顶层文件中将RAMCODE总线接口与总线扩展模块连接。</font>
   <font style="color:#24292E;"></font>
   <font style="color:#24292E;">在“CortexM0_SoC/Task1/rtl/ CortexM0_SoC.v”中，已经完成了处理器核、总线扩展模块、RAMCODE总线接口模块以及Block RAM模块的例化（调用这些模块，将这些模块添加至设计里面），但未在总线扩展模块接口部分连接RAMCODE总线接口。</font>
   
   ```plain
   /* Connect to Interconnect Port 0 */
   .HCLK (clk),
   .HRESETn (cpuresetn),
   .HSEL (/*Port 0*/),
   .HADDR (/*Port 0*/),
   .HPROT (/*Port 0*/),
   .HSIZE (/*Port 0*/),
   .HTRANS (/*Port 0*/),
   .HWDATA (/*Port 0*/),
   .HWRITE (/*Port 0*/),
   .HRDATA (/*Port 0*/),
   .HREADY (/*Port 0*/),
   .HREADYOUT (/*Port 0*/),
   .HRESP (/*Port 0*/),
   .BRAM_ADDR (RAMCODE_ADDR),
   .BRAM_RDATA (RAMCODE_RDATA),
   .BRAM_WDATA (RAMCODE_WDATA),
   .BRAM_WRITE (RAMCODE_WRITE)
   /**********************************/ 
   ```
   
   _改为：_
   
   ```plain
   /* Connect to Interconnect Port 0 */
   .HCLK (clk),
   .HRESETn (cpuresetn),
   .HSEL (HSEL_P0),
   .HADDR (HADDR_P0),
   .HPROT (HPROT_P0),
   .HSIZE (HSIZE_P0),
   .HTRANS (HTRANS_P0),
   .HWDATA (HWDATA_P0),
   .HWRITE (HWRITE_P0),
   .HRDATA (HRDATA_P0),
   .HREADY (HREADY_P0),
   .HREADYOUT (HREADYOUT_P0),
   .HRESP (HRESP_P0),
   .BRAM_ADDR (RAMCODE_ADDR),
   .BRAM_RDATA (RAMCODE_RDATA),
   .BRAM_WDATA (RAMCODE_WDATA),
   .BRAM_WRITE (RAMCODE_WRITE)
   /**********************************/ 
   ```
   
   <font style="color:#24292E;">硬件部分已经完成了。</font>
   
   # 软件部分
   
   ## 1.1 Keil工程的建立和设置
   
   第一步，打开Keil，其工程界面如下图2-1所示，点击左上角Project菜单，选择new uVision project，在工程目录下“/CortexM0_SoC/Task0/keil/”文件夹下新建一个名为code的工程：
   
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153489041-fb79d3da-b22a-4008-841e-8d7fe6d7d0a6.png" width="1213" title="" crop="0,0,1,1" id="czEHW" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-1 Keil软件界面</font>_
   在第一个弹框处选择CMSDK_CM0，如图2-2。如果在弹框处没有这个选项，需要在keil软件的官网上进行下载，网址为[https://www.keil.com/dd2/arm/cmsdk_cm0/,](https://www.keil.com/dd2/arm/cmsdk_cm0/,)下载后安装即可。
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153489512-e6e8d5ee-7eb0-4239-890d-1815d233e1e5.png" width="801" title="" crop="0,0,1,1" id="JnuAw" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-2 选择编程芯片模型</font>_
   第二步，在Keil软件左侧的工程结构界面处，展开Target 1，右键点击Source Group 1，选择“Add Existing Files to Group ‘Source Group 1’”，将“/CortexM0_SoC/Task0/keil/”文件夹下的汇编文件“startup_CMSDK_CM0.s”添加到该工程中（注意文件类型应选择Asm Source file或者All files，才能找到startup_CMSDK_CM0.s），如图2-3。
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153489959-99a2e0d8-c641-4d65-8f2d-16e95bea3618.png" width="793" title="" crop="0,0,1,1" id="tMLKg" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-3 向工程中添加汇编文件</font>_
   第三步，在Keil软件左侧的工程结构界面处，右键点击Target 1，选择Options for Target，对工程进行配置。首先便是对Target选项进行设置，如图2-4左侧红框圈出的部分，此步设置将片上一块大小为0x10000的Memory作为ROM，对核来说这片ROM起始地址为0x00000000，Keil将会通过调试器把程序下载到这一段存储器中。
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153490183-c1bf38f3-751e-4279-b70d-cb9c46af16d5.png" width="617" title="" crop="0,0,1,1" id="t0xBk" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-4 配置Target</font>_
   第四步，在Output栏处修改输出文件夹的位置，在图2-5所示页面点击Select Folder for Objects，将输出文件地址从Objects改为上一级文件夹地址，即工程所在文件夹地址，方便观察输出的文件帮助调试，同时也方便编译出的指令存入硬件中运行和进行功能测试，修改过程如图2-6。
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153490511-38763b08-dde7-47cf-955b-2af3721bd870.png" width="617" title="" crop="0,0,1,1" id="lozhF" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-6 修改编译文件生成地址</font>_
   第五步，在User栏添加两行指令，第一行指令用于将axf文件转换为modelsim仿真所需要的hex文件，作为存储器的初始化文件。第二行用于将axf文件转换为txt格式汇编代码输出。
   在如图2-7的界面勾选Run #1，并在之后框中添加如下代码：
   ```plain
   fromelf -cvf .\code.axf --vhx --32x1 -o code.hex
   ```
   勾选Run #2，并在之后框中添加如下代码：
   ```plain
   fromelf -cvf .\code.axf -o code.txt
   ```
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153490940-68efd40e-44f2-440f-b5d6-5f9af121f08d.png" width="616" title="" crop="0,0,1,1" id="kXeKz" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-7 添加编译指令</font>_
   第六步，在Linker栏勾选Use Memory Layout from Target Dialog及Don’t Search Standard Librarie两个选项，如图2-8。
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153491506-bc7c89aa-2c79-44a6-8072-8463fa5f7431.png" width="852" title="" crop="0,0,1,1" id="KTFZB" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-8 Linker设置</font>_
   第七步，在Debug栏取消勾选Load Application at Startup，选择CMSIS-DAP Debugger在Initialization File处选择工程目录keil文件夹下名为code.ini的启动脚本文件，如图2-9所示，code.ini文件代码如下：
   ```plain
   reset
   _WDWORD(0xE000ED08,0x00000000);
   LOAD code.axf
   SP = _RDWORD(0x00000000);
   PC = _RDWORD(0x00000004);
   ```
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153492121-315d5bdd-d2f2-4f5e-a571-686ab8b72058.png" width="855" title="" crop="0,0,1,1" id="kcNjE" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-9 Debug设置</font>_
   Cortex-M0在启动时会从<font style="color:#24292E;">地址0x00000004处加载复位处理函数的地址，所以在启动文件code.ini中将PC的值设为从地址0x00000004读到的值。</font>
   第八步，在图2-9的界面点击CMSIS-DAP调试器处右侧选项进入Debugger setting，选择Flash Download栏目，由于我们没有Flash，所以选择Do not Erase，并且取消勾选Program以及Verify，如图2-10。
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153492531-694a1b15-632c-4a0e-9d8a-f7265be0b870.png" width="620" title="" crop="0,0,1,1" id="kXJDt" class="ne-image" style="font-size: 16px">
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153492757-0770990f-b9e1-42d6-8602-e8fd4668c5ee.png" width="615" title="" crop="0,0,1,1" id="m0RBN" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-10 Flash Download设置</font>_
   第九步，在Utilities出取消勾选Update Target before Debugging，如图2-11所示。
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153493109-7c8856a4-d202-4ca5-b4d1-e2b92823a9ce.png" width="620" title="" crop="0,0,1,1" id="tjb4s" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-11 Utilities设置</font>_
   至此，我们新建的Keil工程就设置完成，点击OK保存。完成了这两个大步骤后，我们就可以在工程中进行编程了。
   ## 1.2 软件代码
   <font style="color:#24292E;">根据ARMv6-M架构参考手册，Cortex-M0启动过程如下：</font>
+ <font style="color:#24292E;">在复位使能时，CPU处于Reset异常状态；</font>
+ <font style="color:#24292E;">复位释放后，从地址0x00000000出加载栈顶地址，及汇编代码中__Vector的第一行则为栈顶地址，由于我们目前的SoC没有数据存储器，自然也就没有堆栈一说，因此随便设置一个地址即可（此地址必须符合Memory Map定义的可读可写地址段，详情见M0的用户手册）；</font>
+ <font style="color:#24292E;">从地址0x00000004初加载复位处理函数的地址；</font>
+ <font style="color:#24292E;">PC改变为0x00000004中的值，开始执行复位处理，同时CPU的工作状态从异常模式切换为线程模式，开始正常工作。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">由于没有数据存储器，因此我们不能进行相应的load/store指令，仅仅对R0,R1两个寄存器进行操作。</font>
  <font style="color:#24292E;">“CortexM0_SoC/Task1/keil/startup_CMSDK_CM0.s”的</font>软件代码是SoC的启动文件，起到初始化SoC的作用。内容包括划分堆栈大小、定义中断向量表、以及进入复位中断并执行我们所写的一段简单的汇编程序，这段汇编程序实现了一个循环计数器，首先在r1寄存器中存入4，令r0寄存器从0开始不断加1，直到r0内的数值等于r1时，将r0清零并重复计数过程。
  
  ```plain
  ;Inset a loop algorithm there;
  ;****************************;
  ```
  
  _改为：_
  
  ```plain
  ;Inset a loop algorithm there;
  MOVS R1, #4
  Clear MOVS R0, #0
  Adder ADDS R0, R0, #1
  CMP R0, R1
  BEQ Clear
  BNE Adder
  ;****************************;
  ```
  
  <font style="color:#24292E;">修改后完整的startup_CMSDK_CM0.s代码如下：</font>
  
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
  ;Inset a loop algorithm there;
  movs r1,#4
  clear movs r0,#0
  adder adds r0,r0,#1
  cmp r0,r1
  beq clear
  bne adder
  ;****************************;
  ENDP 
  END
  ```
  
  ## 1.3 汇编代码编译
  
  <font style="color:#24292E;">汇编代码编写完成后，我们点击Keil工程中的编译按钮，对文件经行编译，如图2-12所示。</font>
  
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153493649-6545a576-6249-46e5-8426-a4fe434f4a01.png" width="695" title="" crop="0,0,1,1" id="yorRC" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图2-12 编译工程文件</font>_
  编译完成后，在Keil工程的文件夹中我们会得到一个名为code.hex的文件，该文件就是Keil将汇编程序编译获得的机器码。在后续FPGA代码中，我们需要将该文件的路径导入到1.2.5中提到的BRAM初始读取路径中，即可在TD生成比特流的同时将软件内容存入SoC的存储器中。
  ```plain
  initial begin
  /*Insert the address of the hex on your PC in the double quote*/
  $readmemh("E:/M0/Experiments/Task1/keil/code.hex",mem);
  /******************************/
  end
  ```
  # 实现SoC
  ## 1.1 SoC硬件平台准备
  将开发板主体和DAP模块组装好后，用两根USB数据线与电脑连接，见图3-1。开发板要连接两个USB接口，其中一个为TD用于下载bit流文件到FPGA芯片的接口（下图中的FPGA的JTAG口），另一个为Cortex-M0与Keil软件调试的接口（下图中的DAP的USB口）。
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153494291-5df74621-e2d7-4468-9175-341efa0ce992.png" width="677" title="" crop="0,0,1,1" id="trjKU" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3-1 开发板连接</font>_
  ## 1.2 TD工程的建立
  打开TD软件，如图3-2所示。点击Project，选择New Project Wizard，在弹出的窗口第一栏输入工程名字（全英文），第二行输入工程文件路径（全英文），第三、第四行选择我们需要的芯片系列EG4和具体型号EG4S20BG256，点击OK新建一个新的工程。
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153494729-ea13d7e8-9d5c-4f34-bc3d-a8021b1d4679.png" width="1271" title="" crop="0,0,1,1" id="FGMJ7" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3- 2 新建TD工程</font>_
  右键点击Hierarchy，选择New Source弹出的窗口将提示你选择新建文件的类型、 文件名和默认路径，勾选下方Add to Project将自动把新建的文件添加进当前工程中，如图3-3。选择Add Sources弹出的窗口中选择Add Files将依次添加已经存在的路径，选择Add Package files将添加文件夹下的所有文件，如图3-4。
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153495093-26d7b321-c8d9-4960-bcc8-788d3e46661d.png" width="1269" title="" crop="0,0,1,1" id="qoR0T" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3-3 新建文件</font>_
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153495440-360ba9bf-43c0-4b72-896e-d2e255917d95.png" width="1269" title="" crop="0,0,1,1" id="WY5UK" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3-4 导入文件</font>_
  我们将已经编写好的HDL文件全部导入到工程中，软件会自动选择CortexM0_SoC文件作为头文件。也可以右键选择某一个文件，点击Set As Top手动设置为头文件。
  接下来我们添加管脚约束文件，其规定了芯片管脚与开发板接口之间的连接关系。应用在本实验使用的开发板平台上约束文件名为pin.adc，其具体内容如下。
  ```plain
  set_pin_assignment { RSTn } { LOCATION = A9; }
  set_pin_assignment { SWCLK } { LOCATION = R2; }
  set_pin_assignment { SWDIO } { LOCATION = P2; }
  set_pin_assignment { clk } { LOCATION = R7; }
  ```
  管脚约束也可以在TD的图形化窗口上完成。如图3-5，打开上方菜单中的Tools - IO constraint，软件将自动完成左下角工具栏中的HDL2Bit Flow - Read Design，读取当前工程下的设计文件，读取完成后将弹出管脚约束图形化窗口，如图3-6。在Location一栏中填入SoC接口对应的芯片引脚，也能完成管脚约束。
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153495828-41bb740f-0bf5-43e5-b36b-7e6139b5928d.png" width="656" title="" crop="0,0,1,1" id="swGuc" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3-5 利用软件完成管脚约束</font>_
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153496376-74a5cb04-e3aa-4c3b-96f7-5dea17576a18.png" width="904" title="" crop="0,0,1,1" id="oZcT5" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3-6 TD中管脚约束的图形化窗口</font>_
  ## 1.3 SoC的实现和调试
  在完成管脚约束后，直接双击软件左下方工具栏中的HDL2Bit Flow生成比特流。软件会花费一定时间完成综合和布局布线并生成比特流，直到HDL2Bit Flow图标上显示对号，说明比特流生成过程顺利完成，如图3-7所示。
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153496824-2d6dda81-b9b4-49ac-85eb-d6557a3da6c7.png" width="298" title="" crop="0,0,1,1" id="nst3X" class="ne-image" style="font-size: 16px">
  _图3-7 完成比特流生成_
  生成比特流后就需要将比特流烧录到开发板中。双击软件左下方工具栏中Download，如图3-8。弹出的窗口如图3-9所示，上方工具栏显示了已经连接的开发板的芯片型号，说明开发板正确连接到设备上。点击左侧Add，在工程文件夹中找到拓展名为bit的比特流文件，点击打开回到烧录窗口，在File窗口中选中我们要烧录的比特流，点击左侧的Run，等待一段时间，烧录完成。
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153497350-ffe52388-04d9-4cb5-ace7-e97be961c7c0.png" width="298" title="" crop="0,0,1,1" id="tPrNZ" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3-8 打开TD软件烧录工具</font>_
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153497882-1a109688-3038-46c5-aebd-bc5234cc4bfc.png" width="654" title="" crop="0,0,1,1" id="bOTNc" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3-9 TD软件烧录窗口</font>_
  保持开发板与电脑连接，打开Keil工程，点击Option for Target:
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153498385-9cca9319-112a-493e-804d-8d60608e5fb8.png" width="1088" title="" crop="0,0,1,1" id="JMBO0" class="ne-image" style="font-size: 16px">
  参考图2-9中的设置步骤进入Debugger Setting，如果看到图3-10所示的IDCODE则表示调试器与SoC成功连接。（注意：如果该界面红色区域显示的是JTAG端口就需要把它改成SW）。
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153498884-34b519f9-d3d3-48e4-9f33-9ec3521969f0.png" width="617" title="" crop="0,0,1,1" id="R5eeL" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3-10 调试器设置界面</font>_
  确认成功连接后，点击Start Debug，Keil成功进入调试模式：
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153499381-9856fb35-ab15-4e2c-a667-500fcef4727d.png" width="1110" title="" crop="0,0,1,1" id="ZyKeY" class="ne-image" style="font-size: 16px">
  按F11进行单步调试，可以看到CPU按照汇编代码开始正常运行，R0，R1寄存器被正常赋值，如图3-11。
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649153499875-5a8cd520-bf0c-4dc8-8953-fbd6608eba8f.png" width="649" title="" crop="0,0,1,1" id="icyja" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3- 11 Keil调试界面</font>_
  在红框1处为CPU内部寄存器的值，能够随着程序单步执行实时显示每一步寄存器值的变化，而在红框2处为当前执行的汇编代码以及代码存储地址，在红框3处显示的是当前执行的源代码，这里的源代码既可以是汇编代码也可以是C语言代码。根据之前使用汇编语言编写的循环计数程序，正常情况下，在红框1处的R1的值应保持为4，而R0则应在0-4之间循环计数。
  在实验到这里，就证明我们的SoC平台能够完整的执行我们所设计的汇编代码。开发板在下载SoC比特流文件后，如果想要练习其他程序只需要在预留的区域修改代码，编译调试即可，不需要再重复下载FPGA代码和新建工程。

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
