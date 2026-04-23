module Keyboard(
    input                 clk,
    input                 rstn,
    input                 key_clear,
    input        [3 :0]   col,
    output       [3 :0]   row,
    output                key_interrupt,
    output       [15:0]   key_reg
    // input        [15:0]   key
);

wire  [15:0]  key;
keyboard_scan #(
    .SCAN_VAL(32'd100)
)keyboard_scan(
     .clk(clk)
    ,.rstn(rstn)
    ,.col(col)
    ,.row(row)
    ,.key(key)
);

//16个按键，每按下一个按键，产生对于key_pulse,拉高对应key_reg的位，直到AHB写1清除key_reg[15:0]
wire [15:0] key_pulse;
keyboard_filter #(
    .DEBOUNCE_VAL(20'd1000)
)
keyboard_filter(
     .clk(clk)
    ,.rstn(rstn)
    ,.key_in(key)
    ,.key_pulse(key_pulse)
);

assign key_interrupt = |key_pulse ;

keyboard_reg keyboard_reg(
     .clk(clk)
    ,.rstn(rstn)
    ,.key_clear(key_clear)
    ,.key_pulse(key_pulse)
    ,.key_reg(key_reg)
);

endmodule