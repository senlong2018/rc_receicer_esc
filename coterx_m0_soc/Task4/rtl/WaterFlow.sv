module WaterFlow(
    input [1:0] WaterLight_mode,
    input [31:0] WaterLight_speed,
    input clk,
    input RSTn,
    //output logic LEDclk
    output logic [7:0] LED
);

//------------------------------------------------------
//  PWM
//------------------------------------------------------

logic [31:0] pwm_cnt;
logic flow_update_pulse;

always@(posedge clk or negedge RSTn) begin
    if(~RSTn) pwm_cnt <= 32'b0;
    else if(pwm_cnt == WaterLight_speed) pwm_cnt <= 32'b0;
    else pwm_cnt <= pwm_cnt + 1'b1;
end

assign flow_update_pulse = (pwm_cnt == WaterLight_speed);

//------------------------------------------------------
//  LEFT MODE
//------------------------------------------------------

logic [7:0] mode1;

always@(posedge clk or negedge RSTn) begin
    if(~RSTn) 
        mode1 <= 8'h01;
    else if(flow_update_pulse)begin
        case(mode1)
            8'h01 : mode1 <= 8'h02;
            8'h02 : mode1 <= 8'h04;
            8'h04 : mode1 <= 8'h08;
            8'h08 : mode1 <= 8'h10;
            8'h10 : mode1 <= 8'h20;
            8'h20 : mode1 <= 8'h40;
            8'h40 : mode1 <= 8'h80;
        default : mode1 <= 8'h01;
        endcase
    end
end

//------------------------------------------------------
//  RIGHT MODE
//------------------------------------------------------

logic [7:0] mode2;

always@(posedge clk or negedge RSTn) begin
    if(~RSTn) 
        mode2 <= 8'h80;
    else if(flow_update_pulse)begin
        case(mode2)
            8'h80 : mode2 <= 8'h40;
            8'h40 : mode2 <= 8'h20;
            8'h20 : mode2 <= 8'h10;
            8'h10 : mode2 <= 8'h08;
            8'h08 : mode2 <= 8'h04;
            8'h04 : mode2 <= 8'h02;
            8'h02 : mode2 <= 8'h01;
        default : mode2 <= 8'h80;
        endcase
    end
end

//------------------------------------------------------
//  FLASH MODE
//------------------------------------------------------

logic [7:0] mode3;

always@(posedge clk or negedge RSTn) begin
    if(~RSTn) 
        mode3 <= 8'h00;
    else if(flow_update_pulse)begin
        mode3 <= ~mode3;
    end
end

//------------------------------------------------------
//  OUTPUT MUX
//------------------------------------------------------
always@(*) begin
 case(WaterLight_mode)
 2'h1 : begin LED = mode1;end 
 2'h2 : begin LED = mode2;end
 2'h3 : begin LED = mode3;end
 default : begin LED = 8'h00;end
 endcase
end


endmodule
