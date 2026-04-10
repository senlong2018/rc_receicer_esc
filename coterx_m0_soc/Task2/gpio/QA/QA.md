1.在Keil中添加GPIO汇编代码，startup_CMSDK_CM0.s文件作用是什么？
“CortexM0_SoC/Task1/keil/startup_CMSDK_CM0.s”的软件代码是SoC的启动文件，起到初始化SoC的作用。
内容包括划分堆栈大小、定义中断向量表、以及进入复位中断并执行我们所写的一段简单的汇编程序

2.cm0 CPU端口有哪些？各是什么含义？应该如何集成？

3.指令是什么？指令集又是什么？

4.为什么有code sram 和 data sram？ 它们分别存储什么内容？

5.控制流水灯，难道不需要CPU控制start寄存器使得流水灯硬件开始工作吗？

6.为什么要产生cpuresetn？ 什么时候使用cpuresetn，什么时候使用RSTn？
always @(posedge clk or negedge RSTn)begin
        if (~RSTn) cpuresetn <= 1'b0;
        else if (SYSRESETREQ) cpuresetn <= 1'b0;
        else cpuresetn <= 1'b1;
end