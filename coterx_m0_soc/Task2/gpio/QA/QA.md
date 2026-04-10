1.在Keil中添加GPIO汇编代码，startup_CMSDK_CM0.s文件作用是什么？
“CortexM0_SoC/Task1/keil/startup_CMSDK_CM0.s”的软件代码是SoC的启动文件，起到初始化SoC的作用。
内容包括划分堆栈大小、定义中断向量表、以及进入复位中断并执行我们所写的一段简单的汇编程序

2.cm0 CPU端口有哪些？各是什么含义？应该如何集成？

3.指令是什么？指令集又是什么？