//////////////////////////////////////////////////////////////////////////////////
// Company: GOODIX
// Engineer: John
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb;

    logic clk		        ;
    logic reset_n		    ;
    logic key_press  	    ;
    logic beep   		    ;

initial begin
    clk = 1'b0;
    key_press = 1'b0;
    reset_n = 1'b0;    
    #1000;
    reset_n = 1'b1;
end

always begin
    clk = #(`CLK_PERIOD/2) !clk;
    //clk = #10 !clk;
end

key_model #(
    .ZOOM(100) //0.2ms
)
key_model_inst(
    .key_press ( key_press ),
    .key_out   ( key_in    )
);


play_music#(
    .UPDATE_POINT(125),
    .CNT_20MS  (2_00),
    .REG_WIDTH ( 32 ),
    .ROM_DEPTH ( 512 ),
    .ROM_WIDTH ( 5 )
)play_music_inst(
    .clk       ( clk       ),
    .reset_n   ( reset_n   ),
    .key_in    ( key_in    ),
    .beep      ( beep      )
);

endmodule
