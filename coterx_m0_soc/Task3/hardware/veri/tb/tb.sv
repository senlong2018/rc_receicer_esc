`timescale 1ns/1ps

module tb;

    // clocks and reset
    logic clk;
    logic reset_n;

    // output from SoC (LEDs)
    wire [7:0] LED;

initial begin
    clk = 1'b0;
    reset_n = 1'b0;
    #1000;
    reset_n = 1'b1;
end

always #5 clk = ~clk; // 10ns period -> 50MHz

// instantiate SoC (uses liushui internally)
CortexM0_SoC soc (
    .clk    (clk),
    .RSTn   (reset_n),
    .SWDIO  (1'bz),
    .SWCLK  (1'b0),
    .LED    (LED)
);


endmodule
