`timescale 1ns/1ps

module tb;

    // clocks and reset
    logic clk;
    logic reset_n;

    // keyboard iface
    logic [3:0] col;
    wire  [3:0] row;

    // SoC outputs (beep or LEDs may exist)
    wire beep;

initial begin
    clk = 1'b0;
    reset_n = 1'b0;
    col = 4'b1111; // idle (no key pressed)
    // wait a few cycles then release reset synchronized to clk
    repeat(5) @(posedge clk);
    reset_n = 1'b1;
end

always #(`CLK_PERIOD/2) clk = ~clk;

// instantiate SoC
CortexM0_SoC soc (
    .clk    (clk),
    .RSTn   (reset_n),
    .col    (col),
    .row    (row),
    .SWDIO  (1'bz),
    .SWCLK  (1'b0),
    .beep   (beep)
);

// stimulus and monitors moved to TC (tc_test.v)

endmodule
