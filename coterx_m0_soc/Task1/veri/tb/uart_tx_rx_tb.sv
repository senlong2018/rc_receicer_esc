//////////////////////////////////////////////////////////////////////////////////
// Company: �人о·��Ƽ����޹�˾
// Engineer: С÷���Ŷ�
// Web: www.corecourse.cn
// 
// Create Date: 2021/09/20 00:00:00
// Design Name: key_filter
// Module Name: key_filter_tb
// Project Name: key_filter
// Target Devices: xc7z020clg400-2
// Tool Versions: Vivado 2018.3
// Description: �����������Գ���
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module tb;

    parameter DATA_WIDTH = 64;
    parameter MSB_FIRST  = 1;

	logic  clk;
	logic  reset_n;
	logic  send_en;
	logic [7:0]data_byte;
	logic [2:0]baud_set;

	logic uart_tx;
	logic Tx_done;	
	logic uart_state;	

    logic uart_rx;
    logic [7:0]data_byte_out;
    logic [7:0]data_byte_in;
    logic [DATA_WIDTH-1:0]data;

    logic rx_done;
    logic rx_err;


	initial clk= 1;
	always#(`CLK_PERIOD/2) clk = ~clk;
	
	initial begin
		reset_n = 1'b0;
    repeat(100) @(posedge clk);
		reset_n = 1'b1;
	end


uart_multi_data_tx#(
    .DATA_WIDTH(DATA_WIDTH),
    .MSB_FIRST (MSB_FIRST)    
)
uart_multi_data_tx_inst
(
    /*input                 */ .Clk       (clk       ),
    /*input                 */ .Rst_n     (reset_n   ),
    /*input [2:0]           */ .Baud_set  (baud_set  ),
    /*input                 */ .send_en   (send_en   ),
    /*input [DATA_WIDTH-1:0]*/ .data      (data      ),
    /*output logic          */ .uart_tx   (uart_tx   ),
    /*output logic          */ .uart_state(uart_state),
    /*output logic          */ .Tx_done   (Tx_done   )
);


uart_data_tx#(
  .DATA_WIDTH(DATA_WIDTH),
  .MSB_FIRST (MSB_FIRST)
)
uart_data_tx_inst
(
	.Clk       (clk),
	.Rst_n     (reset_n),
	.data      (data),
	.send_en   (send_en),
	.Baud_Set  (baud_set), 
	.uart_tx   () ,
	.Tx_Done   () ,
	.uart_state()
);


//assign uart_rx = uart_tx;


uart_multi_data_rx #(
    .DATA_WIDTH (DATA_WIDTH),
    .MSB_FIRST  (MSB_FIRST )
)
uart_multi_data_rx_inst
(
    /*input                        */ .Clk         (clk),
    /*input                        */ .Rst_n       (reset_n),
    /*input [2:0]                  */ .Baud_Set    (baud_set),
    /*input                        */ .uart_rx     (uart_rx),
    /*output logic                 */ .Rx_Done     (),
    /*output logic                 */ .timeout_flag(),
    /*output logic [DATA_WIDTH-1:0]*/ .data        ()
);

uart_data_rx#(
	.DATA_WIDTH(DATA_WIDTH),
	.MSB_FIRST (MSB_FIRST )
)
uart_data_rx_inst
(
	.Clk         (clk),
	.Rst_n       (reset_n),
  	.uart_rx     (uart_rx),
	.Baud_Set    (baud_set),
	.data        (),
	.Rx_Done     (),
	.timeout_flag()    
);

endmodule
