module key_filter(
    input clk             ,
    input reset_n         ,
    input key_in          ,

    output logic key_flag ,
    output logic key_state
);

localparam KEY_UP    = 2'b00,
           FILTER_DN = 2'b01,
           KEY_DN    = 2'b10,
           FILTER_UP = 2'b11;

logic [1:0]cur_st;
logic [1:0]nxt_st;
logic first_neg;
logic first_pos;
logic key_neg;
logic key_pos;
logic [19:0]cnt_20ms;
logic cnt_20ms_done;
logic first_key_neg_flag;
logic first_key_pos_flag;
//----------------FSM trig signal-------------------
genpart_sync#(
  .edge_type_p (2'h2),
  .rstval_p    (1'b0)
)
key_neg_inst
(
  /*input */ .clk_i   (clk),
  /*input */ .rst_an_i(reset_n),
  /*input */ .d_i     (key_in),
  /*output*/ .q_o     (),
  /*output*/ .edge_o  (key_neg)
);

//use to select first_neg
always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
        first_key_neg_flag <= 1'b0;
    else if(key_neg && cur_st==KEY_UP)
        first_key_neg_flag <= 1'b1;
    else if(cur_st==FILTER_DN && nxt_st!=FILTER_DN)
        first_key_neg_flag <= 1'b0;
end

assign first_neg = key_neg && ~first_key_neg_flag;

genpart_sync#(
  .edge_type_p (2'h1),
  .rstval_p    (1'b0)
)
key_pos_inst
(
  /*input */ .clk_i   (clk),
  /*input */ .rst_an_i(reset_n),
  /*input */ .d_i     (key_in),
  /*output*/ .q_o     (),
  /*output*/ .edge_o  (key_pos)
);

//use to select first_pos
always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
        first_key_pos_flag <= 1'b0;
    else if(key_pos && cur_st==KEY_DN)
        first_key_pos_flag <= 1'b1;
    else if(cur_st==FILTER_UP && nxt_st!=FILTER_UP)
        first_key_pos_flag <= 1'b0;
end

assign first_pos = key_pos && ~first_key_pos_flag;

//use to count filter glitch time,typically 20ms
always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
        cnt_20ms <= 'd0;
    else if(cnt_20ms_done)
        cnt_20ms <= 'd0;
    else if((cur_st==FILTER_DN && nxt_st!=FILTER_DN) || 
            (cur_st==FILTER_UP && nxt_st!=FILTER_UP)
           )
        cnt_20ms <= 'd0;
    else if(first_key_neg_flag || first_key_pos_flag)  //first_key_neg_flag and first_key_pos_flag 
        cnt_20ms <= cnt_20ms + 'd1;          //will not exist simultaneously        
end

assign cnt_20ms_done = cnt_20ms == 20'd100_0000;

//----------------key deglitch FSM------------------
always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
        cur_st <= KEY_UP;
    else
        cur_st <= nxt_st;
end

always@(*) begin
    nxt_st = cur_st;
    case(cur_st)
        KEY_UP :   begin 
                    if(first_neg) 
                        nxt_st = FILTER_DN;
                   end
        FILTER_DN: begin 
                    if(cnt_20ms_done)
                        nxt_st = KEY_DN;
                    else if(key_pos)
                        nxt_st = KEY_UP;
                   end
        KEY_DN:    begin
                    if(first_pos)
                        nxt_st = FILTER_UP;
                   end
        FILTER_UP: begin
                    if(cnt_20ms_done)
                        nxt_st = KEY_UP;
                    else if(key_neg)
                        nxt_st = KEY_DN;
                   end
        default  : begin
                    nxt_st = KEY_UP;
                   end
    endcase
end

//output signals
always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
        key_state <= 1'b1;
    else if(cur_st==FILTER_DN && nxt_st==KEY_DN)
        key_state <= 1'b0; 
    else if(cur_st==FILTER_UP && nxt_st==KEY_UP)
        key_state <= 1'b1;
end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
        key_flag <= 1'b0;
    else if(cur_st==FILTER_DN && nxt_st==KEY_DN)
        key_flag <= 1'b1;
    else if(cur_st==FILTER_UP && nxt_st==KEY_UP)
        key_flag <= 1'b1;
    else
        key_flag <= 1'b0;
end

endmodule

module genpart_sync#(
 parameter  [1:0]edge_type_p = 2'h0,
 parameter       rstval_p    = 1'b0
)(
  input clk_i,
  input rst_an_i,
  input d_i,
  output q_o,
  output reg edge_o
);

`define dly 0
  reg firststage_sync_line_r;
  reg sync_line_r;
  wire d_s;
  assign d_s = d_i;

  always@(posedge clk_i or negedge rst_an_i) begin:proc_sync
    if(rst_an_i == 1'b0) begin
      firststage_sync_line_r <= #`dly {rstval_p};
      sync_line_r            <= #`dly {rstval_p};
    end else begin
      firststage_sync_line_r <= #`dly d_s;
      sync_line_r            <= #`dly firststage_sync_line_r;
    end
  end

  assign q_o =  sync_line_r;

  //Edge Detection
  wire q_s;
  reg  q_r;
  assign q_s = sync_line_r;
  
  always@(posedge clk_i or negedge rst_an_i) begin:proc_stage
    if(rst_an_i == 1'b0) begin
      q_r <= #`dly {rstval_p};
    end else begin
      q_r <= #`dly q_s;
    end
  end

  always@(*) begin:proc_edge
    case(edge_type_p)
      2'd3:edge_o = q_r ^ q_s; //any edge
      2'd2:edge_o = q_r & ~q_s; //falling edge
      2'd1:edge_o = ~q_r & q_s; //rising edge
      default:edge_o = 1'b0; //no egde
    endcase
  end

endmodule
