<font style="color:#24292E;">本手册将介绍如何快速搭建基于ARM Cortex M0 CPU的SoC，将会参考AMBA AHB总线相关知识、cortex m0用户手册、cortex m0技术参考手册以及ARMv6-M架构参考手册,以及将会使用到Keil、Modelsim、串口调试助手以及TD等工程软件。</font>
<font style="color:#24292E;"></font>
<font style="color:#24292E;">例程在硬木课堂的安路EG4S20大拇指开发板上实现。</font>

# Cortex-M0与AMBA3 AHBLite

<font style="color:#24292E;">感谢ARM在其DesignStart项目中开放Cortex M0 CPU能让我们有机会学习研究。CM0 CPU总体结构如图1-1所示。</font>
<img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649151913431-3c6637f2-5830-4b7b-b0a3-c3c998899693.png" width="890" title="" crop="0,0,1,1" id="uc1db1bb6" class="ne-image">
_<font style="color:#595959;">图1-1 Cortex-M0架构图</font>_
<font style="color:#24292E;"></font>
<font style="color:#24292E;">CPU提供了中断向量端口、AHB-Lite端口以及DAP端口。</font>
<font style="color:#24292E;"></font>
<font style="color:#24292E;">关于AMBA3 AHBLite需要读者根据相关文档自行学习，由于Cortex-M0的特性，将不会需要AHBLite所有功能，在第二章将会有详细的说明。</font>

# 文档使用说明

<font style="color:#24292E;">“/CortexM0_SoC/docs/”提供了本手册所需要的所有参考文档，还需读者反复仔细阅读。</font>
<font style="color:#24292E;">“/CortexM0_SoC/Task*/rtl”提供了本手册每次实验对应代码。</font>

# 相关软硬件介绍

<font style="color:#24292E;">本手册将会用到三个软件：</font>

+ <font style="color:#24292E;">TD 5.6.2 （安路科技的FPGA开发软件）</font>
+ <font style="color:#24292E;">Modelsim</font>
+ <font style="color:#24292E;">Keil</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">本手册将会用到以下硬件平台：</font>
  [微处理器原理与片上系统设计简介](https://www.yuque.com/yingmuketang/01/vldg82n5zzx8mtgr)
  <font style="color:#24292E;">那么，FPGA、SoC以及这些软硬件工具的区别与联系在哪呢？请看下图1-2。</font>
  
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649151678751-7e15db22-e17f-486a-bb64-377fee6d2322.png" width="1267" title="" crop="0,0,1,1" id="EH32M" class="ne-image" style="font-size: 16px">
  _<font style="color:#595959;">图1-2 软硬件关系</font>_
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">可以看到，TD负责将硬件描述语言所描述的SoC（Verilog/VHDL）编译、综合、实现，将FPGA内部本身无序的各种逻辑资源（例如：查找表、触发器、RAM等）配置成为有序的电路，实现SoC功能。而keil负责将编写的软件编程语言（C/Assembler）编译成为机器码十六进制文件。</font><font style="color:#24292E;">在modelsim中将机器码作为Verilog描述的RAM的初始化内容</font><font style="color:#24292E;">，即可进行仿真，看到SoC工作时各个信号的波形。若将机器码通过工具下载进由FPGA实现的SoC中，那么就可以让SoC执行编写的程序，通过开发板看到执行结果。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">软硬件开发的层次结构如图1-3所示。</font>
  <img src="https://cdn.nlark.com/yuque/0/2022/png/23019172/1649151679271-9205c544-e5a5-495c-9e06-d2ea4624f010.png" width="751" title="" crop="0,0,1,1" id="BeR0k" class="ne-image" style="font-size: 16px">_<font style="color:#595959;">图1-3 软硬件开发层次</font>_
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">从下往上看（从硬件到软件），FPGA被配置成为SoC，SoC的工作依赖于一条一条的指令，而指令则是由对应的汇编代码生成，最后汇编代码又由编译器将高层次编程语言编译而来。</font>
  <font style="color:#24292E;"></font>
  <font style="color:#24292E;">从上往下看（从软件到硬件），如果想要运行编写好的软件，首先需要利用编译器将代码编译为汇编代码，然后将汇编代码与指令集对应生成机器码，接着将机器码存入SoC的存储器中，这时候SoC就能根据指令开始执行，最后SoC则需要利用FPGA构建。</font>

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
  <img src="https://cdn.nlark.com/yuque/0/2021/png/23019172/1637915212423-e7dc19be-fd80-421a-b8a5-adda96035560.png" width="317.75" title="" crop="0,0,1,1" id="JmzEh" class="ne-image">
+ **知识库**：硬木课堂知识库 [https://www.yuque.com/yingmuketang/01](https://www.yuque.com/yingmuketang/01)
+ **B站**：硬木课堂 [https://space.bilibili.com/506069950](https://space.bilibili.com/506069950)
+ **官网**：[http://www.emooc.cc/](http://www.emooc.cc/)
