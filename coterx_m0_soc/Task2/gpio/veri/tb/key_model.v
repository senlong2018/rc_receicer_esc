//////////////////////////////////////////////////////////////////////////////////
// Company: �人о·��Ƽ����޹�˾
// Engineer: С÷���Ŷ�
// Web: www.corecourse.cn
// 
// Create Date: 2021/09/20 00:00:00
// Design Name: key_filter
// Module Name: key_model
// Project Name: key_filter
// Target Devices: xc7z020clg400-2
// Tool Versions: Vivado 2018.3
// Description: ��������ģ������ļ�
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module key_model#(
	parameter ZOOM = 1
)
(
	key_press,
	key_out
);
	input key_press;
	output key_out;
	
	reg key_out;
	reg [15:0]myrand;
	
	initial begin
	key_out = 1'b1;
    while(1)
		begin
		  @(posedge key_press);
		  key_gen;
		end
	end
	
	task key_gen;
	begin
    key_out = 1'b1;
    repeat(50)begin
      myrand = ({$random}%65536)/ZOOM;//0~65535;
      #myrand key_out = ~key_out;			
    end
    key_out = 0;
    #(25000000/ZOOM);
    
    repeat(50)begin
      myrand = ({$random}%65536)/ZOOM;//0~65535;
      #myrand key_out = ~key_out;			
    end
    key_out = 1;
    #(25000000/ZOOM);	
	end	
	endtask

endmodule
