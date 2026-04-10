//////////////////////////////////////////////////////////////////////////////////
// Task2 top-level testbench: instantiate SoC and dump waveform
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb;

    // clocks and reset
    logic clk;
    logic reset_n;

    // GPIO pins exposed from SoC
    wire [7:0] ioPin;

initial begin
    clk = 1'b0;
    reset_n = 1'b0;
    #1000;
    reset_n = 1'b1;
end

always #5 clk = ~clk; // 10ns period

// instantiate the Cortex-M0 SoC from Task2/rtl
CortexM0_SoC soc (
    .clk    (clk),
    .RSTn   (reset_n),
    .SWDIO  (1'bz),
    .SWCLK  (1'b0),
    .ioPin  (ioPin)
);


endmodule
