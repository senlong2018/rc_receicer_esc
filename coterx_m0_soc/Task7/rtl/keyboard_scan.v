module keyboard_scan#(
    parameter SCAN_VAL = 100
)
(
    input clk,
    input [3:0] col,
    input rstn,           
    output reg [3:0] row,
    output reg [15:0] key
);

    reg [31:0] cnt;
    reg scan_clk;

    always@(posedge clk or negedge rstn) begin
       if(!rstn)
            cnt <= 0;
       else if(cnt == SCAN_VAL)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end

    wire update_point;
    assign update_point = (cnt == SCAN_VAL);

    always@(posedge clk or negedge rstn)begin
        if(!rstn)
            row = 4'b1110;
        else if(update_point)
            row <= {row[2:0],row[3]}; 
    end
    
    always@(posedge clk or negedge rstn)begin
        if(!rstn)   
            key <= 16'hffff;
        else if(update_point)begin 
            case(row)
                4'b1110 : key[3:0]   <= col;
                4'b1101 : key[7:4]   <= col;
                4'b1011 : key[11:8]  <= col;
                4'b0111 : key[15:12] <= col;
                default : key        <= 16'hffff;
            endcase
        end
    end

endmodule