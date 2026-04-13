在前一部分介绍完成数字系统的硬件实现音乐播放后，我们将介绍如何基于Cortex-M0搭建SoC，并在SoC系统上进行软件开发，以矩阵键盘为基础，利用中断信号实现音乐的正确切歌播放。本实验视频请查看：
[bilibili](https://player.bilibili.com/player.html?bvid=BV16p4y1m7AA&autoplay=0)

# 1. Cortex-M0处理器简介

在搭建SoC之前，我们先简要介绍Cortex-M0处理器的特点。

1. 基于ARMv6-M架构规范，采用Thumb指令集。
2. 采用Thumb-2技术，32位指令和16位指令并存，以获得更高的代码密度。
3. 处理器Core由3个部分组成：
   - 寄存器组，包含16个32位寄存器，其中一些为特殊寄存器。在处理器中需要设置若干寄存器来暂时存放处理器工作时的控制信息和数据信息
   - 算术逻辑单元（ALU），是运算部件的核心，完成具体的运算操作。
   - 控制逻辑，Cortex-M0具有三级流水线(pipelining)结构，分别为取指、译码、执行。控制逻辑的作用就是控制硬件依次执行相应的命令。流水线是能够重叠执行若干条指令的方法，可以减少一组指令的执行时间。
4. 包括一个嵌套向量中断控制器（NVIC）可以处理最多32个中断请求和一个不可屏蔽中断（NMI）输入。
5. 系统总线接口基于流水线结构，符合名为Advanced High-performance Bus(AHB) Lite总线协议。支持8、16、32位数据传输，并且允许插入等待状态。
6. 具有多个调试特性，软件开发人员可以快速构建自己的应用。
   
   # 2. AHB-Lite总线
   
   由于Cortex-M0处理器设计是用来做简单的控制的，所以只设计支持了简单的AHB-Lite总线。AHB-Lite总线与AHB总线最大的区别在于，AHB-Lite总线只支持一个AHB主机，而AHB总线是支持多主机的。所以在结构上，AHB-Lite总线不需要仲裁器。
   <font style="color:#24292E;">AHB-Lite结构示意图如图2-1所示，其包括一个主机（Master）、若干个从机（Slave），一个译码器（Decoder）用于选择对应的从机以及一个选通开关（MUX）用于选择对应的返回数据。</font>
   
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164894565-80cccb23-11fd-4567-821c-e7b2d10a283f.png" width="663" title="" crop="0,0,1,1" id="VhWR7" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2-1 AHB-Lite总线示意图</font>_
   ## 2.1 部分接口介绍
   AHB-Lite还有部分重要的接口信号。这些接口对于设计SoC的总线协议非常重要，下面我们简要介绍Cortex-M0处理器中的总线接口信号，如表2-2所示。
   表2-2 Cortex-M0部分总线接口说明
   | 名称 | 来源 | 描述 |
   | :--- | :--- | :--- |
   | HADDR[31:0] | Master | 传输地址 |
   | HBURST[2:0] | Master | Burst类型 |
   | HSIZE[2:0] | Master | 数据宽度<br/>00：8bit Byte<br/>01：16bit Halfword<br/>10：32bit Word |
   | HTRANS[1:0] | Master | 传输类型<br/>00：IDLE，无操作<br/>01：BUSY<br/>10：NONSEQ，主要的传输方式<br/>11：SEQ |
   | HWDATA[31:0] | Master | 核发出的写数据 |
   | HWRITE | Master | 读写选择（1：写，0：读） |
   | HRDATA[31:0] | Slave | 外设返回的读数据 |
   | HREADOUT | Slave | 何时传输完成（通常为1） |
   | HRESP | Slave | 传输是否成功（通常为0） |
   ## 2.2 基本读写操作
   由于Cortex-M0处理器核的特性，其AHB-Lite总线仅支持NONSEQ传输，即基本的读写操作和具有等待状态的读写操作。所以接下来我们将介绍AHB-Lite总线的基本读写操作时序和具有等待状态的读写操作时序。
   <font style="color:#24292E;">基本读操作：如图2-3。</font>
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164894794-a1f23f95-e85a-4825-9417-8423c9b122d6.png" width="1045" title="" crop="0,0,1,1" id="J1l9c" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2- 3 基本读操作</font>_
   <font style="color:#24292E;"></font>
   <font style="color:#24292E;">当Master需要从外设读取数据时，总共需要经历两个阶段：Address phase & Data phase，因此一次读传输至少需要2cycle。在Address phase时，Master会把读取地址输出在地址总线上，直到HREADY为‘1’ 。在图2-3中，由于HREADY一直为‘1’，那么Master在Address phase放出地址后直接进入Data phase；在Data phase时，Master会在HREADY为‘1’时读取数据总线HRDATA上的数据，至此传输完成。</font>
   <font style="color:#24292E;"></font>
   <font style="color:#24292E;">基本写操作：如图2-4所示。</font>
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164895102-335e05a2-8719-4b1e-8637-fe2888d75b2a.png" width="1047" title="" crop="0,0,1,1" id="Wj6Cr" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2- 4 基本写操作</font>_
   <font style="color:#24292E;"></font>
   <font style="color:#24292E;">类似基本读操作，写操作也会经历两个阶段：在Address phase时，Master会把写地址输出在地址总线上，直到HREADY为‘1’，在图2-4中，由于HREADY一直为‘1’，那么Master在Address phase放出地址 后直接进入Data phase；在Data phase时，Master会将写数据放在数据总线HWDATA上，直到HREADY为‘1’，传输完成。</font>
   <font style="color:#24292E;"></font>
   <font style="color:#24292E;">具有等待的读写操作：如图2-5、图2-6所示。</font>
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164895466-f888be82-8c17-4912-b933-652abfd5d13b.png" width="1042" title="" crop="0,0,1,1" id="elPZX" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2- 5 具有等待状态的读操作</font>_<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164895727-8a50e52c-c0a4-4560-a512-6e233f3e4b4b.png" width="1001" title="" crop="0,0,1,1" id="KEq8c" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图2- 6 具有等待状态的写操作</font>_
   正如前面所说，HREADY为当前正在进行传输的Slave返回的HREADYOUT，Master端会把HREADY既作为进入传输的判断条件（在HREADY为‘0’时不会开始下一个传输），也会作为传输完成的条件（在HREADY为‘0’时不会退出当前传输）。但是，总线是流水线结构，虽然对于一次传输至少需要两个cycle，但是对于两次传输，例如把图2-7中的A与B看作两次传输，最终实现如图2-7所示的流水线传输。
   <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164896164-d82ee737-d03b-4bc9-9a95-c3b1678c8d6b.png" width="1013" title="" crop="0,0,1,1" id="KG7pW" class="ne-image" style="font-size: 16px">
   _<font style="color:#595959;">图3- 37 总线流水</font>_
   <font style="color:#24292E;"></font>
   <font style="color:#24292E;">对与Slave而言，HREADY只需要作为进入传输的判断条件，因为进入传输后，HREADY就会被切换到自己的输出HREADOUT上，因此当Slave根据HREADY等信号进入传输状态后，自行控制传输结束的时间，并依此控制HREADYOUT输出。</font>
   # 3. 中断处理
   <font style="color:#24292E;">根据ARMv6-M架构参考手册以及Cortex-M0用户手册，CPU中断处理过程如下：</font>
+ <font style="color:#24292E;">CPU接收到中断信号（IRQ、NMI、Systick等等）；</font>
+ <font style="color:#24292E;">将R0,R1,R2,R3,R12,LR,PC,xPSR寄存器入栈，如图3-1所示；</font>
+ <font style="color:#24292E;">根据中断信号查找中断向量表（对应汇编启动代码中的__Vector段），跳转至中断处理函数，如图3-2所示；</font>
+ <font style="color:#24292E;">中断处理函数执行完成后，利用链接寄存器返回，寄存器出栈，PC跳转。</font>
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164896498-de2af0d0-7020-4ad8-9e02-5b3c981783cb.png" width="1064" title="" crop="0,0,1,1" id="mM5IY" class="ne-image" style="font-size: 16px">_<font style="color:#595959;">图3- 1 寄存器入栈</font>_<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164896734-44a60bda-adc0-47e0-a5f9-0e8ca91038d6.png" width="647" title="" crop="0,0,1,1" id="Ynh1R" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图3- 2 异常中断向量表</font>_
  
  # <font style="color:#24292E;">4. 硬件部分</font>
  
  <font style="color:#24292E;">此实验最终实现的SoC如图4-3所示。利用开发板上面的矩阵键盘最下面的3个按键，通过上升沿触发Cortex-M0的IRQ中断。然后处理器在中断服务程序中，控制切换播放不同音乐。</font>
  
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164897302-46e02095-7ff6-4c25-a10f-219bc3bad92b.png" width="1021" title="" crop="0,0,1,1" id="J8wKu" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图4- 3 本次SoC系统</font>_
  在前面的学习中了解了蜂鸣器播放音乐的完整数字系统的硬件实现以及M0的部分基本原理后，下面我们将根据图4.3的SoC系统，将实现功能所需要的外设搭载在AHB-lite总线上。
  ## 4.1 矩阵键盘
  搭载矩阵键盘的具体代码如下，矩阵键盘按下后key_data信号作为数据被读入到HRDATA的低16位，并且当写信号有效时，将数据写到信号key_clear的地址里。
  ```plain
  module AHBlite_keyboard(
  input wire HCLK,
  input wire HRESETn,
  input wire HSEL,
  input wire [31:0] HADDR,
  input wire [2:0] HBURST,
  input wire HMASTLOCK,
  input wire [1:0] HTRANS,
  input wire [2:0] HSIZE,
  input wire [3:0] HPROT,
  input wire HWRITE,
  input wire [31:0] HWDATA,
  input wire HREADY,
  output wire HREADYOUT,
  output wire[31:0] HRDATA,
  output wire HRESP,
  input wire [15:0] key_data,
  output wire key_clear
  );
  assign HRESP=1'b0;
  assign HREADYOUT=1'b1;
  wire write_en;
  assign write_en=HSEL & HTRANS[1] & HWRITE & HREADY;
  reg wr_en_reg;
  always@(posedge HCLK or negedge HRESETn)
  begin
  if(~HRESETn)
  wr_en_reg<=1'b0;
  else if(write_en)
  wr_en_reg<=1'b1;
  else
  wr_en_reg<=1'b0;
  end
  assign key_clear=wr_en_reg? HWDATA[0]:1'b0;
  assign HRDATA={16'h0,key_data};
  endmodule
  ```
  ## 4.2 音乐播放器
  搭载buzzermusic的具体代码如下，当写信号有效时，M0将HWDATA上数据的最低2位写到信号music_select对应的地址，并且将HWDATA的5位信号作为播放音乐的有效信号写到信号music_start对应的地址。
  ```plain
  module AHBlite_Buzzermusic(
  input wire HCLK,
  input wire HRESETn,
  input wire HSEL,
  input wire [31:0] HADDR,
  input wire [2:0] HBURST,
  input wire HMASTLOCK,
  input wire [1:0] HTRANS,
  input wire [2:0] HSIZE,
  input wire [3:0] HPROT,
  input wire HWRITE,
  input wire [31:0] HWDATA,
  input wire HREADY,
  output wire HREADYOUT,
  output wire[31:0] HRDATA,
  output wire HRESP,
  output wire [1:0] music_select,
  output wire music_start
  );
  assign HRESP=1'b0;
  assign HREADYOUT=1'b1;
  wire write_en;
  assign write_en=HSEL & HTRANS[1] & HWRITE & HREADY;
  reg wr_en_reg;
  always@(posedge HCLK or negedge HRESETn)
  begin
  if(~HRESETn)
  wr_en_reg<=1'b0;
  else if(write_en)
  wr_en_reg<=1'b1;
  else
  wr_en_reg<=1'b0;
  end
  assign music_select=wr_en_reg? HWDATA[1:0]:2'b00;
  assign music_start = wr_en_reg? HWDATA[4]:1'b0;
  assign HRDATA={30'd0,music_select};
  endmodule
  ```
  ## 4.3 储存地址/数据RAM
  分别将储存地址和数据的RAM挂载到m0上，实现m0和外设的信息交互。
  ```plain
  module AHBlite_Block_RAM #(
  parameter ADDR_WIDTH = 12)(
  input wire HCLK, 
  input wire HRESETn, 
  input wire HSEL, 
  input wire [31:0] HADDR, 
  input wire [1:0] HTRANS, 
  input wire [2:0] HSIZE, 
  input wire [3:0] HPROT, 
  input wire HWRITE, 
  input wire [31:0] HWDATA, 
  input wire HREADY, 
  output wire HREADYOUT, 
  output wire [31:0] HRDATA, 
  output wire HRESP,
  output wire [ADDR_WIDTH-1:0] BRAM_RDADDR,
  output wire [ADDR_WIDTH-1:0] BRAM_WRADDR,
  input wire [31:0] BRAM_RDATA,
  output wire [31:0] BRAM_WDATA,
  output wire [3:0] BRAM_WRITE
  );
  assign HRESP = 1'b0;
  assign HRDATA = BRAM_RDATA;
  wire trans_en;
  assign trans_en = HSEL & HTRANS[1];
  wire write_en;
  assign write_en = trans_en & HWRITE;
  wire read_en;
  assign read_en = trans_en & (~HWRITE);
  reg [3:0] size_dec;
  always@(*) begin
  case({HADDR[1:0],HSIZE[1:0]})
  4'h0 : size_dec = 4'h1;
  4'h1 : size_dec = 4'h3;
  4'h2 : size_dec = 4'hf;
  4'h4 : size_dec = 4'h2;
  4'h8 : size_dec = 4'h4;
  4'h9 : size_dec = 4'hc;
  4'hc : size_dec = 4'h8;
  default : size_dec = 4'h0;
  endcase
  end
  reg [3:0] size_reg;
  always@(posedge HCLK or negedge HRESETn) begin
  if(~HRESETn) size_reg <= 0;
  else if(write_en & HREADY) size_reg <= size_dec;
  end
  reg [ADDR_WIDTH-1:0] addr_reg;
  always@(posedge HCLK or negedge HRESETn) begin
  if(~HRESETn) addr_reg <= 0;
  else if(trans_en & HREADY) addr_reg <= HADDR[(ADDR_WIDTH+1):2];
  end
  reg wr_en_reg;
  always@(posedge HCLK or negedge HRESETn) begin
  if(~HRESETn) wr_en_reg <= 1'b0;
  else if(HREADY) wr_en_reg <= write_en;
  else wr_en_reg <= 1'b0;
  end
  assign BRAM_RDADDR = HADDR[(ADDR_WIDTH+1):2];
  assign BRAM_WRADDR = addr_reg;
  assign HREADYOUT = 1'b1;
  assign BRAM_WRITE = wr_en_reg ? size_reg : 4'h0;
  assign BRAM_WDATA = HWDATA; 
  endmodule
  ```
  ## 4.4 外设与主机互联
  如图2-1所示，我们需要将外设与主机互联，利用HADDR地址的高位判断选择哪一个外设开启，<font style="color:#24292E;">译码器（Decoder）用于选择对应的外设（从机）以及一个选通开关（MUX）用于选择对应的返回数据。</font>
  ```plain
  module AHBlite_Interconnect(
  // CLK & RST
  input wire HCLK,
  input wire HRESETn,
  // CORE SIDE
  input wire [31:0] HADDR,
  input wire [2:0] HBURST,
  input wire HMASTLOCK,
  input wire [3:0] HPROT,
  input wire [2:0] HSIZE,
  input wire [1:0] HTRANS,
  input wire [31:0] HWDATA,
  input wire HWRITE,
  output wire HREADY,
  output wire [31:0] HRDATA,
  output wire HRESP,
  // Peripheral 0
  output wire HSEL_P0,
  output wire [31:0] HADDR_P0,
  output wire [2:0] HBURST_P0,
  output wire HMASTLOCK_P0,
  output wire [3:0] HPROT_P0,
  output wire [2:0] HSIZE_P0,
  output wire [1:0] HTRANS_P0,
  output wire [31:0] HWDATA_P0,
  output wire HWRITE_P0,
  output wire HREADY_P0,
  input wire HREADYOUT_P0,
  input wire [31:0] HRDATA_P0,
  input wire HRESP_P0,
  // Peripheral 1
  ...
  // Peripheral 2

// Peripheral 3

);
// Public signals--------------------------------
//-----------------------------------------------
// HADDR
assign HADDR_P0 = HADDR;
assign HADDR_P1 = HADDR;
assign HADDR_P2 = HADDR;
assign HADDR_P3 = HADDR;
// HBURST
assign HBURST_P0 = HBURST;
assign HBURST_P1 = HBURST;
assign HBURST_P2 = HBURST;
assign HBURST_P3 = HBURST;
// HMASTLOCK
...
// HPROT
...
// HSIZE
...
// HTRANS
...
// HWDATA
...
// HWRITE
...
// HREADY
// Decoder---------------------------------------
//-----------------------------------------------
AHBlite_Decoder Decoder(
 .HADDR (HADDR),
 .P0_HSEL (HSEL_P0),
 .P1_HSEL (HSEL_P1),
 .P2_HSEL (HSEL_P2),
 .P3_HSEL (HSEL_P3) 
);
// Slave MUX-------------------------------------
//-----------------------------------------------
AHBlite_SlaveMUX SlaveMUX(
 // CLOCK & RST
 .HCLK (HCLK),
 .HRESETn (HRESETn),
 .HREADY (HREADY),
 //P0
 .P0_HSEL (HSEL_P0),
 .P0_HREADYOUT (HREADYOUT_P0),
 .P0_HRESP (HRESP_P0),
 .P0_HRDATA (HRDATA_P0),
 //P1
...
 //P2
...
 //P3
...
 .HREADYOUT (HREADY),
 .HRESP (HRESP),
 .HRDATA (HRDATA)
);
endmodule

```
```plain
module AHBlite_Decoder
#(
 /*RAMCODE enable parameter*/
 parameter Port0_en = 1,

/************************/
 /*RAMDATA enable parameter*/

/************************/
 /*keyboard enable parameter*/

/************************/
 /*buzzermusic enable parameter*/
 /************************/
)(
 input [31:0] HADDR,
 /*RAMCODE OUTPUT SELECTION SIGNAL*/
 output wire P0_HSEL,
 /*RAMDATA OUTPUT SELECTION SIGNAL*/
 /*keyboard OUTPUT SELECTION SIGNAL*/
/*buzzermusic OUTPUT SELECTION SIGNAL*/

);
//RAMCODE-----------------------------------
//0x00000000-0x0000ffff
/*Insert RAMCODE decoder code there*/
assign P0_HSEL = (HADDR[31:16] == 16'h0000) ? Port0_en : 1'b0; 
/***********************************/
//RAMDATA-----------------------------
//0x20000000-0x2000ffff
/*Insert RAMDATA decoder code there*/
/***********************************/
//------------------------------
//0x40000000 key_data/key_clear
/***********************************/
//0x40000010 buzzermusic select/en
/***********************************/
endmodule
```

```plain
module AHBlite_SlaveMUX (
 input HCLK,
 input HRESETn,
 input HREADY,
 //port 0
 input P0_HSEL,
 input P0_HREADYOUT,
 input P0_HRESP,
 input [31:0] P0_HRDATA,
//port 1
//port 2
 //port 3
 //output
 output wire HREADYOUT,
 output wire HRESP,
 output wire [31:0] HRDATA
);
//reg the hsel
reg [3:0] hsel_reg;
always@(posedge HCLK or negedge HRESETn) begin
 if(~HRESETn) hsel_reg <= 4'b0000;
 else if(HREADY) hsel_reg <= {P0_HSEL,P1_HSEL,P2_HSEL,P3_HSEL};
end
//hready mux
reg hready_mux;
always@(*) begin
 case(hsel_reg)
 4'b0001 : begin hready_mux = P3_HREADYOUT;end
 4'b0010 : begin hready_mux = P2_HREADYOUT;end
 4'b0100 : begin hready_mux = P1_HREADYOUT;end
 4'b1000 : begin hready_mux = P0_HREADYOUT;end
 default : begin hready_mux = 1'b1;end
 endcase
end
assign HREADYOUT = hready_mux;
//hresp mux
reg hresp_mux;
always@(*) begin
 case(hsel_reg)
 4'b0001 : begin hresp_mux = P3_HRESP;end
 4'b0010 : begin hresp_mux = P2_HRESP;end
 4'b0100 : begin hresp_mux = P1_HRESP;end
 4'b1000 : begin hresp_mux = P0_HRESP;end
 default : begin hresp_mux = 1'b0;end
 endcase
end
assign HRESP = hresp_mux;
//hrdata mux
reg [31:0] hrdata_mux;
always@(*) begin
 case(hsel_reg)
 endcase
end
assign HRDATA = hrdata_mux;
endmodule 
```

## 4.5 顶层文件

将外设与m0互联后，在顶层文件中例化各个子模块，注意将矩阵键盘的按键信号引出，作为中断信号控制切放歌曲。

```plain
/*connect the IRQ with keyboard*/
wire [31:0] IRQ;
wire key_interrupt;
assign IRQ={31'b0,key_interrupt};
```

## 4.6 管脚约束

将顶层文件中的信号和板子上的管脚对应起来。

```plain
set_pin_assignment { clk } { LOCATION = R7; IOSTANDARD = LVCMOS33; }
set_pin_assignment { RSTn } { LOCATION = A9; IOSTANDARD = LVCMOS33; }
set_pin_assignment { col[0] } { LOCATION = E11; IOSTANDARD = LVCMOS33; }
set_pin_assignment { col[1] } { LOCATION = D11; IOSTANDARD = LVCMOS33; }
set_pin_assignment { col[2] } { LOCATION = C11; IOSTANDARD = LVCMOS33; }
set_pin_assignment { col[3] } { LOCATION = F10; IOSTANDARD = LVCMOS33; }
set_pin_assignment { row[0] } { LOCATION = E10; IOSTANDARD = LVCMOS33; }
set_pin_assignment { row[1] } { LOCATION = C10; IOSTANDARD = LVCMOS33; }
set_pin_assignment { row[2] } { LOCATION = F9; IOSTANDARD = LVCMOS33; }
set_pin_assignment { row[3] } { LOCATION = D9; IOSTANDARD = LVCMOS33; }
set_pin_assignment { beep } { LOCATION = H11; IOSTANDARD = LVCMOS33; }
set_pin_assignment { SWDIO } { LOCATION = P2; IOSTANDARD = LVCMOS33; }
set_pin_assignment { SWCLK } { LOCATION = R2; IOSTANDARD = LVCMOS33; }
```

# 5. 软件部分

首先与硬件部分的decoder模块相对应，应该在头文件中定义外设的地址如下：

```plain
#include <stdint.h>
#define NVIC_CTRL_ADDR (* (volatile unsigned *) 0xe000e100)
#define Keyboard_keydata_clear (*(volatile unsigned*) 0x40000000)
#define Music_data (*(volatile unsigned*) 0x40000010)
void KEY_ISR(void);
```

之后在m0的启动代码“startup_CMSDK_CM0.s”中，程序进入main函数后，首先通过给NVIC_CTRL_ADDR赋值，使能用到的中断。之后若无按键按下，程序一直在while（1）处循环，当中断到来，程序跳转到KEY_ISR,给key_flag赋值后程序跳转回main函数，继续顺序执行。
“startup_CMSDK_CM0.s”部分代码：

```plain
/***********************************/
Reset_Handler PROC
 GLOBAL Reset_Handler
 ENTRY
 IMPORT __main
 LDR R0, =__main
 MOV R8, R0
 MOV R9, R8
 BX R0
 ENDP
KEY_Handler PROC
 EXPORT KEY_Handler [WEAK]
 IMPORT KEY_ISR
 PUSH {R0,R1,R2,LR}
 BL KEY_ISR
 POP {R0,R1,R2,PC}
 ENDP
```

<font style="color:rgb(0, 0, 0);">中断函数：</font>

```plain
#include "code_def.h"
#include <stdint.h>
uint32_t key_flag;
void KEY_ISR(void)
{
 key_flag = 1;
}
```

main函数：

```plain
#include <stdint.h>
#include "code_def.h"
#include <string.h>
#include <stdio.h>
extern uint32_t key_flag;
int __main()
{
 NVIC_CTRL_ADDR=1;
while(1)
{ while(!key_flag);
uint32_t din;
din=Keyboard_keydata_clear;
int i=0;
int ans=0;
for(i=0;i<16;i++)
{
 if((din>>i)&1)
{
 ans=i;
 Music_data=16+ans;
 break;
}}
key_flag=0;
Keyboard_keydata_clear=1;
}}
```

# 6. 调试与运行

硬件部分的代码编写好之后，先新建project，将所有的硬件代码与管脚adc文件添加到工程中：
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164897836-edf8c276-b65a-432a-8cd3-776cc40b9910.png" width="1920" title="" crop="0,0,1,1" id="KqrMb" class="ne-image" style="font-size: 16px">
点击上方Process→run，当bitstream成功生成后，点击Download→Add，选择生成的bit流。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164898316-9204a23e-ff2f-4c5b-b8a4-e87b01ef3c16.png" width="934" title="" crop="0,0,1,1" id="z3sQt" class="ne-image" style="font-size: 16px">
之后点击Run按钮，利用板子上的JTAG端口将bit流下载到板子上（需要特别注意下图中标志处是否检测到板子型号）
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649165936205-06467ac6-0bf8-44f3-92d8-4678e78e86aa.png" width="947" title="" crop="0,0,1,1" id="udcd05bd3" class="ne-image">
之后新建keil5的project，将编写好的文件添加至工程中，设置如下：
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649165963875-947fb346-4388-480d-bc23-10127e7b4960.png" width="783" title="" crop="0,0,1,1" id="ueb9b198b" class="ne-image">
点击setting，查看是否检测到调试DAP接口：
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649165987753-10f6dd51-27a7-4d34-897f-38e176fd17dd.png" width="780" title="" crop="0,0,1,1" id="u6a4fac51" class="ne-image">
可能与安路的RAM IP有关，在程序全部成功编译并download之后，需要进入调试模式run一次之后退出调试模式，此时程序成功下载到板子上，能正常执行按键切歌功能。
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164900405-12fcc545-289f-4b87-8a77-a9bb4c324dca.png" width="1269" title="" crop="0,0,1,1" id="Cp6Qu" class="ne-image" style="font-size: 16px">
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649164902391-700508ea-6584-48dc-bd59-81300fc166ca.png" width="1415" title="" crop="0,0,1,1" id="uqj3Z" class="ne-image" style="font-size: 16px">
至此我们就完成了基于Cortex-M0搭建SoC，并使用软件驱动蜂鸣器正常切歌播放的设计。

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
