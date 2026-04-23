module keyboard_filter#(
    parameter DEBOUNCE_VAL = 20'hfffff
)
(
    input           clk,
    input           rstn,
    input  [15: 0]  key_in,
    output [15: 0]  key_pulse // if key pushed, output 1
);

wire [15: 0] key;
assign key = ~key_in;

reg  [19 : 0] treg0;
reg  [19 : 0] treg1;
reg  [19 : 0] treg2;
reg  [19 : 0] treg3;
reg  [19 : 0] treg4;
reg  [19 : 0] treg5;
reg  [19 : 0] treg6;
reg  [19 : 0] treg7;
reg  [19 : 0] treg8;
reg  [19 : 0] treg9;
reg  [19 : 0] treg10;
reg  [19 : 0] treg11;
reg  [19 : 0] treg12;
reg  [19 : 0] treg13;
reg  [19 : 0] treg14;
reg  [19 : 0] treg15;
wire [19 : 0] treg0_nxt = treg0 + 1'b1;
wire [19 : 0] treg1_nxt = treg1 + 1'b1;
wire [19 : 0] treg2_nxt = treg2 + 1'b1;
wire [19 : 0] treg3_nxt = treg3 + 1'b1;
wire [19 : 0] treg4_nxt = treg4 + 1'b1;
wire [19 : 0] treg5_nxt = treg5 + 1'b1;
wire [19 : 0] treg6_nxt = treg6 + 1'b1;
wire [19 : 0] treg7_nxt = treg7 + 1'b1;
wire [19 : 0] treg8_nxt = treg8 + 1'b1;
wire [19 : 0] treg9_nxt = treg9 + 1'b1;
wire [19 : 0] treg10_nxt = treg10 + 1'b1;
wire [19 : 0] treg11_nxt = treg11 + 1'b1;
wire [19 : 0] treg12_nxt = treg12 + 1'b1;
wire [19 : 0] treg13_nxt = treg13 + 1'b1;
wire [19 : 0] treg14_nxt = treg14 + 1'b1;
wire [19 : 0] treg15_nxt = treg15 + 1'b1;

always @ (posedge clk or negedge rstn) begin
    if (~rstn) begin
        treg0 <= 20'b0;
        treg1 <= 20'b0;
        treg2 <= 20'b0;
        treg3 <= 20'b0;
        treg4 <= 20'b0;
        treg5 <= 20'b0;
        treg6 <= 20'b0;
        treg7 <= 20'b0;
        treg8 <= 20'b0;
        treg9 <= 20'b0;
        treg10 <= 20'b0;
        treg11 <= 20'b0;
        treg12 <= 20'b0;
        treg13 <= 20'b0;
        treg14 <= 20'b0;
        treg15 <= 20'b0;        
    end
    else begin
        if (key[0]) begin 
            if (treg0 != DEBOUNCE_VAL)
                treg0 <= treg0_nxt;
        end
        else begin
            treg0 <= 20'b0;
        end

        if (key[1]) begin
            if (treg1 != DEBOUNCE_VAL)
                treg1 <= treg1_nxt;
        end
        else begin   
            treg1 <= 20'b0;
        end

        if (key[2]) begin
            if (treg2 != DEBOUNCE_VAL)
                treg2 <= treg2_nxt;
        end
        else begin
            treg2 <= 20'b0;
        end

        if (key[3]) begin
            if (treg3 != DEBOUNCE_VAL) 
                treg3 <= treg3_nxt;
        end
        else begin        
            treg3 <= 20'b0;
        end

        if (key[4]) begin 
            if (treg4 != DEBOUNCE_VAL)
                treg4 <= treg4_nxt;
        end
        else begin
            treg4 <= 20'b0;
        end
        
        if (key[5]) begin 
            if (treg5 != DEBOUNCE_VAL)
                treg5 <= treg5_nxt;
        end
        else begin
            treg5 <= 20'b0;
        end

        if (key[6]) begin 
            if (treg6 != DEBOUNCE_VAL)
                treg6 <= treg6_nxt;
        end
        else begin
            treg6 <= 20'b0;
        end
        
        if (key[7]) begin 
            if (treg7 != DEBOUNCE_VAL)
                treg7 <= treg7_nxt;
        end
        else begin
            treg7 <= 20'b0;
        end

        if (key[8]) begin 
            if (treg8 != DEBOUNCE_VAL)
                treg8 <= treg8_nxt;
        end
        else begin
            treg8 <= 20'b0;
        end

        if (key[9]) begin
            if (treg9 != DEBOUNCE_VAL)
                treg9 <= treg9_nxt;
        end
        else begin   
            treg9 <= 20'b0;
        end

        if (key[10]) begin
            if (treg10 != DEBOUNCE_VAL)
                treg10 <= treg10_nxt;
        end
        else begin
            treg10 <= 20'b0;
        end

        if (key[11]) begin
            if (treg11 != DEBOUNCE_VAL) 
                treg11 <= treg11_nxt;
        end
        else begin        
            treg11 <= 20'b0;
        end

        if (key[12]) begin 
            if (treg12 != DEBOUNCE_VAL)
                treg12 <= treg12_nxt;
        end
        else begin
            treg12 <= 20'b0;
        end
        
        if (key[13]) begin 
            if (treg13 != DEBOUNCE_VAL)
                treg13 <= treg13_nxt;
        end
        else begin
            treg13 <= 20'b0;
        end

        if (key[14]) begin 
            if (treg14 != DEBOUNCE_VAL)
                treg14 <= treg14_nxt;
        end
        else begin
            treg14 <= 20'b0;
        end
        
        if (key[15]) begin 
            if (treg15 != DEBOUNCE_VAL)
                treg15 <= treg15_nxt;
        end
        else begin
            treg15 <= 20'b0;
        end                
    end
end

assign key_pulse[15] = (treg15 != DEBOUNCE_VAL) & (treg15_nxt == DEBOUNCE_VAL); 
assign key_pulse[14] = (treg14 != DEBOUNCE_VAL) & (treg14_nxt == DEBOUNCE_VAL);
assign key_pulse[13] = (treg13 != DEBOUNCE_VAL) & (treg13_nxt == DEBOUNCE_VAL);
assign key_pulse[12] = (treg12 != DEBOUNCE_VAL) & (treg12_nxt == DEBOUNCE_VAL);
assign key_pulse[11] = (treg11 != DEBOUNCE_VAL) & (treg11_nxt == DEBOUNCE_VAL); 
assign key_pulse[10] = (treg10 != DEBOUNCE_VAL) & (treg10_nxt == DEBOUNCE_VAL);
assign key_pulse[9] = (treg9 != DEBOUNCE_VAL) & (treg9_nxt == DEBOUNCE_VAL);
assign key_pulse[8] = (treg8 != DEBOUNCE_VAL) & (treg8_nxt == DEBOUNCE_VAL);
assign key_pulse[7] = (treg7 != DEBOUNCE_VAL) & (treg7_nxt == DEBOUNCE_VAL); 
assign key_pulse[6] = (treg6 != DEBOUNCE_VAL) & (treg6_nxt == DEBOUNCE_VAL);
assign key_pulse[5] = (treg5 != DEBOUNCE_VAL) & (treg5_nxt == DEBOUNCE_VAL);
assign key_pulse[4] = (treg4 != DEBOUNCE_VAL) & (treg4_nxt == DEBOUNCE_VAL);
assign key_pulse[3] = (treg3 != DEBOUNCE_VAL) & (treg3_nxt == DEBOUNCE_VAL); 
assign key_pulse[2] = (treg2 != DEBOUNCE_VAL) & (treg2_nxt == DEBOUNCE_VAL);
assign key_pulse[1] = (treg1 != DEBOUNCE_VAL) & (treg1_nxt == DEBOUNCE_VAL);
assign key_pulse[0] = (treg0 != DEBOUNCE_VAL) & (treg0_nxt == DEBOUNCE_VAL);

endmodule 