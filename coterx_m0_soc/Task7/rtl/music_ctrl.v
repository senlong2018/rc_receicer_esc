module music_ctrl(
    input      clk,
    input      en,
    input      rstn,addr_finish,
    input      beat_finish,
    output reg addr_en,
    output reg addr_rstn,
    output reg tune_pwm_en,
    output reg tune_pwm_rstn,
    output reg beat_cnt_en,
    output reg beat_cnt_rstn
);

localparam IDLE = 2'b00,
           ADD  = 2'b01,
           WORK = 2'b10;

reg [1:0] cur_st;
reg [1:0] nxt_st;

always@(*) begin
    nxt_st = cur_st;
    case(cur_st)
        IDLE :  begin
                if(en)
                    nxt_st=ADD;
                end
        ADD:    begin
                if(addr_finish)
                    nxt_st=IDLE;
                else
                    nxt_st=WORK;
                end
        WORK:   begin
                if(beat_finish)
                    nxt_st=ADD;
                end
        default:nxt_st=IDLE;
     endcase
end

 always@(posedge clk or negedge rstn)
 begin
 if(!rstn)
    cur_st<=IDLE;
 else
    cur_st<=nxt_st;
 end
 
 always@(posedge clk or negedge rstn) begin
     if(!rstn) begin
         addr_en<=1'b0;
         addr_rstn<=1'b0;
         tune_pwm_en<=1'b0;
         tune_pwm_rstn<=1'b0;
         beat_cnt_en<=1'b0;
         beat_cnt_rstn<=1'b0;
     end     
     else begin
        case(nxt_st)
        IDLE:
                 begin
                 addr_en<=1'b0;
                 addr_rstn<=1'b0;
                 tune_pwm_en<=1'b0;
                 tune_pwm_rstn<=1'b0;
                 beat_cnt_en<=1'b0;
                 beat_cnt_rstn<=1'b0;
                 end
        ADD:     begin
                 addr_en<=1'b1;
                 addr_rstn<=1'b1;
                 tune_pwm_en<=1'b0;
                 tune_pwm_rstn<=1'b0;
                 beat_cnt_en<=1'b0;
                 beat_cnt_rstn<=1'b0;
                 end
        WORK:     begin
                 addr_en<=1'b0;
                 addr_rstn<=1'b1;
                 tune_pwm_en<=1'b1;
                 tune_pwm_rstn<=1'b1;
                 beat_cnt_en<=1'b1;
                 beat_cnt_rstn<=1'b1;
                 end
        default:begin
                 addr_en<=1'b0;
                 addr_rstn<=1'b0;
                 tune_pwm_en<=1'b0;
                 tune_pwm_rstn<=1'b0;
                 beat_cnt_en<=1'b0;
                 beat_cnt_rstn<=1'b0;
                 end
                 endcase
             end
 end
         
endmodule
