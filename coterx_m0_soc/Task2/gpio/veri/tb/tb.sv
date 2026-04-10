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

// AHB bus monitor: print reads/writes and highlight GPIO addresses
always @(posedge clk) begin
    // HTRANS != IDLE indicates an active transfer
    if (soc.HTRANS !== 2'b00) begin
        if (soc.HWRITE) begin
            $display("[AHB WRITE] time=%0t addr=0x%08h data=0x%08h HSEL_P4=%b HSEL_P0=%b", $time, soc.HADDR, soc.HWDATA, soc.HSEL_P4, soc.HSEL_P0);
            if (soc.HADDR == 32'h40000028) begin
                $display("[GPIO CONFIG] CPU writes outEn <= 0x%0h", soc.HWDATA);
            end
            if (soc.HADDR == 32'h40000020) begin
                $display("[GPIO ODATA] CPU writes oData <= 0x%0h", soc.HWDATA);
            end
        end else begin
            $display("[AHB READ]  time=%0t addr=0x%08h HSEL_P0=%b HSEL_P4=%b", $time, soc.HADDR, soc.HSEL_P0, soc.HSEL_P4);
        end
    end
end


endmodule
