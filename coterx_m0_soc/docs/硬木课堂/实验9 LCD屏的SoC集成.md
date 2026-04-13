<font style="color:#000000;">我们继续介绍LCD屏的使用和软件编写，并将之前的各个功能模块集成在一个SoC中，实现一个功能相对完整的系统。使用的屏幕可在如下链接购买（9341驱动）：</font>
[https://item.taobao.com/item.htm?spm=a230r.1.14.16.41646a4bv368v5&id=561935745378&ns=1&abbucket=20#detail](https://item.taobao.com/item.htm?spm=a230r.1.14.16.41646a4bv368v5&id=561935745378&ns=1&abbucket=20#detail)

# <font style="color:#000000;">1. LCD及驱动芯片ILI9341介绍</font>

## <font style="color:#000000;">1.1 LCD简介</font>

<font style="color:#000000;">TFT-LCD 即薄膜晶体管液晶显示器。它在液晶显示屏的每一个象素上都设置有一个薄膜晶体管（TFT），可有效地克服非选通时的串扰，提高了图像质量。</font>
<font style="color:#000000;"></font>
<font style="color:#000000;">课程中使用到的2.4寸LCD屏采用的驱动芯片为ILI9341，且使用8080 MCU 16位总线接口模式，可以直插课程提供的FPGA教学板。</font>

## <font style="color:#000000;">1.2 LCD模块使用原理</font>

<font style="color:#000000;">LCD模块使用的基本原理是，主机通过引脚向驱动芯片发送一系列指令和数据，之后驱动芯片会根据这些指令和数据刷新LCD屏幕并进行显示。</font>
<font style="color:#000000;"></font>
<font style="color:#000000;">一次典型的LCD使用流程如图1.1所示</font>
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649167123394-7a972472-eabf-4150-9f09-622ae50caeb2.png" width="926" title="" crop="0,0,1,1" id="DaW2X" class="ne-image" style="color: #000000; font-size: 16px">
_<font style="color:#595959;">图1.1 LCD的使用流程</font>_

## <font style="color:#000000;">1.3 LCD模块接口</font>

| <font style="color:#000000;">接口信号</font>                                                                                                                                                                                   | <font style="color:#000000;">I/O</font>     | <font style="color:#000000;">LCD屏引脚名</font>    | <font style="color:#000000;">功能</font>                                                |
|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:-------------------------------------------:|:----------------------------------------------:|:-------------------------------------------------------------------------------------:|
| <font style="color:#000000;">RESX</font>                                                                                                                                                                                   | **<font style="color:#000000;">I</font>**   | **<font style="color:#000000;">RES</font>**    | **<font style="color:#000000;">TFTLCD的硬复位信号，低电平有效</font>**                            |
| <font style="color:#000000;">CSX</font>                                                                                                                                                                                    | **<font style="color:#000000;">I</font>**   | **<font style="color:#000000;">CS</font>**     | **<font style="color:#000000;">TFTLCD的使能信号，低电平有效</font>**                             |
| <font style="color:#000000;">D/CX</font>                                                                                                                                                                                   | **<font style="color:#000000;">I</font>**   | **<font style="color:#000000;">RS</font>**     | **<font style="color:#000000;">命令或数据的选择信号，当该信号为0时读写指令；当该信号为1时，读写数据</font>**           |
| <font style="color:#000000;">RDX</font>                                                                                                                                                                                    | **<font style="color:#000000;">I</font>**   | **<font style="color:#000000;">RD</font>**     | **<font style="color:#000000;">从TFTLCD读取数据的读信号</font>**                               |
| <font style="color:#000000;">WRX</font>                                                                                                                                                                                    | **<font style="color:#000000;">I</font>**   | **<font style="color:#000000;">WR</font>**     | **<font style="color:#000000;">向TFTLCD写入数据的写信号</font>**                               |
| <font style="color:#000000;">D[17:0]</font>                                                                                                                                                                                | **<font style="color:#000000;">I/O</font>** | **<font style="color:#000000;">D0~D15</font>** | **<font style="color:#000000;">18位双向数据线。课程提供的LCD屏使用了其中的16位，从低到高对应屏幕引脚的D0~D15</font>** |
| _<font style="color:#595959;">表1.1 LCD接口介绍</font>_                                                                                                                                                                         |                                             |                                                |                                                                                       |
| <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649167123761-a6a5bd07-ac3b-4454-bc35-5e0d2df40023.png" width="878" title="" crop="0,0,1,1" id="O2Szy" class="ne-image" style="color: #000000; font-size: 16px"> |                                             |                                                |                                                                                       |
| _<font style="color:#595959;">图1.2 LCD接口功能</font>_                                                                                                                                                                         |                                             |                                                |                                                                                       |

## <font style="color:#000000;">1.4 LCD操作时序</font>





![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-36-16-image.png)





![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-36-31-image.png)



## 1.5 ILI9341指令举例



![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-36-59-image.png)

1. 表1.2为指令0xD3的描述，该指令用于读取LCD控制器的ID
2. 在第一栏指令中，可以看到若要写入该指令，需要将控制信号RS （即前面介绍的D/CX信号）保持为0，在WR上升沿写入数据0xD3。
3. 写入该指令后，会读到四个参数，后两个分别是0x93和0x41，刚好是我们使用的控制器ILI9341的数字部分

## 1.6 ILI9341操作示例

下面以写入颜色为例讲解ILI9341的操作

1. **指定列区域**

2A指令用于定义MCU能操作的列区域

写入该指令后，会读到四个参数，前两个参数的低八位组成列的起始地址，后两个参数的低八位组成列的结束地址



![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-37-23-image.png)



2. **指定行区域**

2B指令用于定义MCU能操作的行区域

写入该指令后，会读到四个参数，前两个参数的低八位组成行的起始地址，后两个参数的低八位组成行的结束地址

![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-37-41-image.png)

3. **写入颜色**

2C指令用于将颜色数据传给MCU

写入该指令后，行寄存器和列寄存器会重置为SC和SP的坐标

根据参数信息写入颜色信息

![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-37-59-image.png)



4. **总结**

通过2A和2B指令设置坐标

通过2C指令写入数据信息

![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-38-16-image.png)

# AHB总线矩阵

CMSDK AHB Busmatrix 是一个可配置的总线矩阵，它支持完整的AHB协议、多主机以及灵活的地址映射并且自带仲裁器。

![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-39-17-image.png)

使用CMSDK AHB Busmatrix可以灵活且方便地生成总线互联，而不用手动地例化AHB Mux和编写地址解码器。

# 简易DMA的实现

大量数据传输会占用CPU的时钟周期，并可能会造成严重的处理延迟问题。因此，常用DMA(Direct Memory Access)来替CPU执行数据传输的操作。DMA用于将数据从一个地址传输到另一个地址。本次实验将实现一个简易的AHB DMA核，其由从机和主机两部分组成，从机用于接收来自CPU的数据传输指令，主机用于进行数据传输，支持AHB中的单次传输。DMA将用于蜂鸣器的控制。

此外，使用DMA来传输音乐数据，即将音乐数据储存在程序地址空间而不是专用的ROM中，可以方便地更换歌曲，极大地提高了灵活性

# 硬件部分

本次实验最终实现的SoC如图4.1所示。使用按键来切换蜂鸣器播放的歌曲，同时LCD显示对应的变化图案。Sound DMA和BGM DMA分别用来播放促发的单音和较长的BGM。

![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-39-45-image.png)

## 总线矩阵

总线矩阵的接口和互联如图2.1所示。

从机的地址空间如下：

![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-39-58-image.png)

总线矩阵的配置信息如下：

<!-- Global definitions -->

  <architecture_version>ahb2</architecture_version>

  <arbitration_scheme>burst</arbitration_scheme>

  <routing_data_width>32</routing_data_width>

  <routing_address_width>32</routing_address_width>

  <user_signal_width>32</user_signal_width>

  <bus_matrix_name>BuzzerSoCBusMtx</bus_matrix_name>

  <input_stage_name>BuzzerSoCBusIn</input_stage_name>

  <matrix_decode_name>BuzzerSoCBusDec</matrix_decode_name>

  <output_arbiter_name>BuzzerSoCBusArb</output_arbiter_name>

  <output_stage_name>BuzzerSoCBusOut</output_stage_name>

  <!-- Slave interface definitions -->

  <slave_interface name="S0">

    <sparse_connect interface="M0"/>

    <sparse_connect interface= "M1"/>

    <sparse_connect interface= "M2"/>

    <address_region interface="M0" mem_lo="00000000" mem_hi='1fffffff' remapping='none'/>

    <address_region interface="M1" mem_lo="20000000" mem_hi="3fffffff" remapping='none'/>

    <address_region interface="M2" mem_lo="40000000" mem_hi="5fffffff" remapping='none'/>

  </slave_interface>

  <slave_interface name="S1">

    <sparse_connect interface="M0"/>

    <sparse_connect interface="M1"/>

    <sparse_connect interface="M2"/>

    <address_region interface="M0" mem_lo="00000000" mem_hi='1fffffff' remapping='none'/>

    <address_region interface="M1" mem_lo="20000000" mem_hi="3fffffff" remapping='none'/>

    <address_region interface="M2" mem_lo="40000000" mem_hi="5fffffff" remapping='none'/>

  </slave_interface>

  <slave_interface name="S2">

    <sparse_connect interface="M0"/>

    <sparse_connect interface="M1"/>

    <sparse_connect interface="M2"/>

    <address_region interface="M0" mem_lo="00000000" mem_hi='1fffffff' remapping='none'/>

    <address_region interface="M1" mem_lo="20000000" mem_hi="3fffffff" remapping='none'/>

    <address_region interface="M2" mem_lo="40000000" mem_hi="5fffffff" remapping='none'/>

  </slave_interface>

  <!-- Master interface definitions -->

  <master_interface name="M0"/>

  <master_interface name="M1"/>

  <master_interface name="M2"/>



## DMA蜂鸣器

DMA蜂鸣器的蜂鸣器控制部分和之前实验中的基本一致，只是新增加了DMA。

DMA分从机和主机部分，从机为DMA控制器，用于接收CPU发来的歌曲起始地址、判断歌曲播放状态以及控制DMA主机传输每个音的数据和蜂鸣器载入并播放新的音。

DMA从机所在文件为

DMA主机用于通过AHB互联来读取数据，它由一个有四个状态的状态机组成。这四个状态分别为：S0(idle), AddrPhase, DataPhase, ready

DMA主机接收来自DMA从机和总线矩阵的信号来改变状态，并通过总线矩阵读取歌曲的数据。



## APB子系统

APB (Advanced Peripheral Bus)为AMBA总线协议的一种。它相较于AHB总线复杂性更小，实现的开销也更小，用于连接低带宽、不需要流水线总线接口的外设。

此次实验实现的SoC中的APB子系统由AHB到APB桥和几个外设组成。APB协议不在此做赘述。



## LCD控制器

LCD控制器用于控制LCD的复位以及数据端口。它由一个ROM、控制器和用于与LCD模块相连的输出端口组成。ROM用于储存LCD初始化的命令，控制器用来控制输出端口的输出，即在LCD初始化时输出ROM中的一系列命令；在LCD初始化完成后，接收CPU发来的数据并据此控制端口进行输出。、



# 软件部分

## 5.1 主程序

主程序的任务是初始化LCD后进入蜂鸣器LCD联动显示程序。

以下为主函数内容

int main()
{
    SYSInit();
    isPlaying = false;
    isStop = false;

    uint16_t x, y;
    uint8_t dx, dy;
    
    LCD->LCD_MODE = 1;
    LCD_RST_CLR;
    LCD_RST_SET;
    LCD_BL_CTR_SET;
    x  = y  = 110;
    dx = dy = 20;
    LCD_Init();
    while(!LCD_ini_finish) ;
    LCD_ini_finish = 0;
    LCD -> LCD_MODE = 1;
    LCD_CS_SET;
    LCD_RS_SET;
    LCD_WR_SET;
    LCD_RD_SET;
    
    PlayCol();
    
    return 0;

}



LCD_Init()为发起LCD初始化的函数，发起后用while循环等待LCD初始化完成，触发中断，之后进入PlayCol()，即蜂鸣器LCD联动显示程序。

Main.c中四个全局数组，两个Music_x[]储存了两首音乐的数据，Sound[]用于储存促发音的数据,ColTab[]用于储存LCD显示内容的调校数据。



## LCD驱动程序

LCD驱动程序中的核心是LCD_Fill()函数，它用于在LCD上一个指定区域显示某种颜色的色块



# 调试与运行

调试与运行和实验三（IP核集成与软件驱动方式）的流程相同。

KEY3播放暂停，KEY7切歌



![](C:\Users\senlong2020\AppData\Roaming\marktext\images\2026-04-09-15-42-26-image.png)
