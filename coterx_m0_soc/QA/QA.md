1.在Keil中添加GPIO汇编代码，startup_CMSDK_CM0.s文件作用是什么？
“CortexM0_SoC/Task1/keil/startup_CMSDK_CM0.s”的软件代码是SoC的启动文件，起到初始化SoC的作用。
内容包括划分堆栈大小、定义中断向量表、以及进入复位中断并执行我们所写的一段简单的汇编程序


2.cm0 CPU端口有哪些？各是什么含义？应该如何集成？

SLEEPHOLDREQn：外设/PMU 发出的低有效“保持睡眠/延长睡眠”请求（input）。当拉低时请 CPU/系统不要退出或进入更深睡眠，常用于在某些外设/调试期间阻止关断或延长休眠。处理建议：采样并在时钟域内判断，异步断言、同步释放或做敲定计数以避免毛刺。

WICENREQ：Wake‑up Interrupt Controller 使能请求（input）。请求将中断控制器置于低功耗的 WIC 模式以支持更低功耗下的唤醒中断。处理建议：当被置位时先准备/使能 WIC，然后允许进入对应的低功耗状态；清除/确认需在同一时钟域内完成。

CDBGPWRUPREQ：核或调试逻辑输出的“调试域上电请求”（output）。当调试器需要对 debug 域供电/就绪（例如连接调试会话）时核会拉高该信号请求 PMU 上电。处理建议：PMU 接到请求后上电并返回 CDBGPWRUPACK；两端需通过握手（ack）确认并在域间做同步。

CDBGPWRUPACK：PMU 对调试域上电的应答（input）。为 CDBGPWRUPREQ 的确认，表示 debug 电源与时钟已稳定，可以进行调试访问。处理建议：核收到该 ack 后才允许走调试访问路径，且 ack 应在接收域内同步。

SYSRESETREQ：核内部发出的“系统复位请求”（output）。由软件或核内部条件（如 NVIC_SystemReset）触发，要求复位控制器对系统/CPU 产生复位。处理建议：把它作为复位源之一（通常与外部 POR/板级复位合并），在复位生成逻辑中做去抖/延展（异步断言 + 同步释放），并保证复位宽度满足硬件需求。

NMI： 非屏蔽中断（Non‑Maskable Interrupt）。1 位输入，触发不可屏蔽的 NMI 异常，优先级高于普通外部中断。通常由硬件故障、看门狗或紧急故障源驱动。建议将异步外部源经过两级同步到 CPU 时钟域，或保证源为稳态电平以避免毛刺。

IRQLATENCY： 中断响应延迟（Interrupt Latency）参数输入，常见为 8 位（在本工程中用 8'h0 连接）。核心用它来建模从中断产生到真正进入中断处理的周期延迟（用于仿真/时序估算）。在 SoC 中可用常量或由 PMU/中断控制器根据运行模式配置；若不需要建模延迟，保持 0 即可。

ECOREVNUM： 核心版本号/标识（ECore Revision Number），这里通常为 28 位只读输入（本工程写作 28'h0）。用于固件或调试器识别核的实现/修订号（报告给软件或调试工具）。建议在产品化时写入厂内约定的常量值，以便追踪核版本。

STCLKEN：SysTick 时钟使能输入。用来告诉核是否给 SysTick 定时器提供时钟/使能其计数（在某些实现中用于选择/门控 SysTick 时钟）。方向：input。常见做法：由 SoC 时钟管理或 PMU 在特定低功耗模式下置零以停止 SysTick 计数，或恒连 1 以保持传统行为。

STCALIB：SysTick 校准字（Calibration word）输入，遵循 Cortex‑M SysTick CALIB 寄存器语义。它用于给 SysTick 提供参考周期/校准信息（例如用于表示“10ms 对应的时钟周期数”或包含无参考/偏差标志）。方向：input（通常把常量或来自时钟/PMU 子模块的值连进来）。作用要点：

提供一个重装/参考值以便固件/内核能生成标准时间基（如 10ms）；
也可包含标志位（在 ARM 规范中有 TENMS、NOREF/SKEW 等含义），表明参考是否存在或是否有校准偏差；
在仿真/板级设计中可把它设为常量（例如：核心频率 / 100 = 每 10ms 的周期数），或设为 0 表示无外部参考。

debug接口兼容JTAG和SWD 2种方式，JTAG接口包括TCK,TMS,TDI,TDO，SWD接口包括SWCLK,SWDIO(inout,三态门)：

nTRST：JTAG TAP 的异步复位（active low）。
TDI：JTAG 数据输入（Test Data In）。
SWCLKTCK：时钟，既是 JTAG 的 TCK 也可作 SWD 的 SWCLK。
SWDITMS：输入引脚，复用为 JTAG 的 TMS 或 SWD 的输入方向（SWDIO 读入）。核把这个当作单个输入信号。
SWDO：核的调试数据输出（复用为 JTAG 的 TDO 或 SWD 的输出到 SWDIO）。
SWDOEN：输出使能，用来把 SWDO 驱动到双向 SWDIO 引脚（高则驱动，低则三态），这是实现 SWDIO 双向总线的常见方式。

DBGRESTART：调试“重启/继续”请求（通常作为来自调试器/调试逻辑的输入到核）。当断点/单步结束后，调试控制器通过此信号请求核退出 debug-halt 并继续执行。处理要点：把它作为调试控制信号对待，需在 CPU 时钟域内同步并与调试握手（CDBGPWRUPACK 等）配合使用，避免毛刺导致意外继续执行。

RXEV：事件接收信号（Receive Event，输入到核）。用于给核一个“事件”通知（可被 WFE/WFI 等指令响应以唤醒或触发事件路径），常由 DMA/外设或系统事件驱动以实现低开销唤醒。处理要点：如果外设是异步源，先做两级同步或保证稳态脉冲宽度；固件层面会通过 WFE/SEV 与此配合。

EDBGRQ：外部调试请求（External Debug Request，输入）。用于请求把核（或多核群）强制进入调试/停止状态，常用于 JTAG/SWD 或外部调试器发起的“全局停机”/多核同步 halt。处理要点：这类请求通常需要以同步、安全的方式把核停下（可做握手/状态上报），并在多核系统里实现同步停机策略以避免竞态。


3.指令是什么？指令集又是什么？

4.为什么有code sram 和 data sram？ 它们分别存储什么内容？

5.控制流水灯，难道不需要CPU控制start寄存器使得流水灯硬件开始工作吗？

6.为什么要产生cpuresetn？ 什么时候使用cpuresetn，什么时候使用RSTn？
always @(posedge clk or negedge RSTn)begin
        if (~RSTn) cpuresetn <= 1'b0;
        else if (SYSRESETREQ) cpuresetn <= 1'b0;
        else cpuresetn <= 1'b1;
end

cpuresetn就是AHB时钟域的复位，RSTn是外部总复位，RSTn需要同步到cpuresetn；
对于AHB时钟域的相关复位都需要使用cpuresetn,源头复位使用RSTn；


7.介绍一下CPU运行中的取指，译码，执行 3个步骤都在做什么？如何流水起来的？

8.从硬件层面来看，Cortex-M0 流水灯 SoC 控制流是什么？
1. 初始化阶段 (Hardware Boot)：
复位释放： CPU 发起 AHB 取指请求；
向量提取： 总线译码器选中指令存储器（BRAM），CPU 提取栈顶地址与复位函数地址；
2. 配置阶段 (Configuration)：
GPIO 模式设置： CPU 发起 AHB 写操作，地址指向 0x40000028 (outEn)，写入控制字以配置 GPIO 引脚为输出状态；
3. 执行循环 (Main Loop)：
点灯操作： CPU 发起 AHB 写操作，将 0x01 写入 0x40000020 (oData)，激活对应的硬件引脚输出高电平；
延时消耗： CPU 执行减法或比较指令进行软件循环计数，占用时钟周期以实现视觉上的停留；
逻辑移位： CPU 对寄存器中的值执行逻辑左移（LSLS）；
循环往复： 当检测到第 8 位溢出或达到预设边界时，PC 跳转回循环起始点；
4. 硬件交互：
所有写操作均需遵循 AHB-Lite 协议：地址阶段（Address Phase）发出地址和控制信号，数据阶段（Data Phase）传输实际的电平控制字；


我认为Task3中AHB GPIO的工作起来的流程为：
1.芯片上电, POR-> cpuresetn;
2.读取中断向量表，读取SP和Reset Handler，CPU从Reset Handler开始执行3级流水；
3.CPU通过AHB读code sram中加载好的code.hex文件，此步为取指，然后经过译码，进入执行；
4.CPU写WaterLight的speed和mode寄存器；
5.WaterLight硬件模块自己控制8个LED的工作；
这是硬件运行的基础，startup_CMSDK_SM0.s中可以再使用汇编语言进行较为复杂的流水灯控制；

6.汇编程序控制流水灯模式切换，speed切换，每进入一个模式delay一段时间，在此期间进行流水，时间到达后切换到下一个模式，在进行新的流水，如此循环（mode 1 -> 2 -> 3 -> 1 ...）;


寄存器是软硬件之间的接口：
    ┌──────────────────┐
    │   软件（汇编）    │    STR R0, [0x40000000]   ← 软件只知道"往地址写数据"
    └────────┬─────────┘
             │
             │  AHB 总线
             │
    ┌────────▼─────────┐
    │  WaterLight 寄存器 │    ← 这就是你说的"软硬件接口"
    │  0x40000000: mode │
    │  0x40000004: speed│
    └────────┬─────────┘
             │
    ┌────────▼─────────┐
    │  WaterLight 硬件  │    自动根据 mode/speed 驱动 LED[7:0]
    └──────────────────┘


读取初始栈指针有何作用？
读取复位向量有何作用？
PC有何作用？


CPU中断处理过程如下：
● CPU接收到中断信号（IRQ、NMI、Systick等等）；
● 将R0,R1,R2,R3,R12,LR,PC,xPSR寄存器入栈，如图1-1所示；
● 根据中断信号查找中断向量表（对应汇编启动代码中的__Vector段），跳转至中断处理函数，如图1-2所示；
● 中断处理函数执行完成后，利用链接寄存器返回，寄存器出栈，PC跳转。

我有疑问：
1.什么是栈？
2.入栈是什么意思？
3.中断向量表是什么，有什么含义？
4.链接寄存器是什么？
5.什么是出栈？
6.PC跳转是什么意思？


按键消抖(key_filter) 和 deglitch 有什么区别？各自是如何实现的？

两者本质上都是滤除毛刺：信号必须稳定足够长的时间，才认为是有效变化。

区别在于：
1. 滤除对象不同：deglitch 滤除电气毛刺（EMI、串扰等ns级噪声），key_filter 滤除机械按键弹跳（ms级抖动）；
2. 滤除手段不同：
   - deglitch：3级移位寄存器采样，连续2拍一致才更新输出，滤除窗口为2~3个时钟周期；
   - key_filter：4状态FSM(KEY_UP→FILTER_DN→KEY_DN→FILTER_UP) + 20ms计数器，等抖动自然结束后再采信；
3. 输出不同：
   - deglitch：仅输出净化后的信号（波形一一对应，不理解信号含义）；
   - key_filter：在滤除毛刺的基础上额外提取事件语义，输出 key_state（按键当前状态）和 key_flag（状态变化的单周期脉冲），可直接用于触发下游逻辑；

总结：两者核心思想相同（信号稳定足够久才算有效变化），但 key_filter 在消抖之上还做了事件识别，输出的是结构化的状态+事件信息，而非简单的净化波形。



这些机器码是如何控制CPU进行取指，译码，执行的？

