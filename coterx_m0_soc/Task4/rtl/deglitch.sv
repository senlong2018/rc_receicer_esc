module deglitch #(
    parameter RST_VAL = 1'b1
)(
    input deg_clk,
    input deg_rstn,
    input sig_in,
    output logic sig_out
);
    logic [2:0]deg_reg;

    always_ff @( posedge deg_clk or negedge deg_rstn ) begin 
        if(!deg_rstn)
            deg_reg <= {3{RST_VAL}};
        else
            deg_reg <= {deg_reg[1:0], sig_in};
    end

    always_ff @( posedge deg_clk or negedge deg_rstn ) begin 
        if(!deg_rstn)
            sig_out <= RST_VAL;
        else if(deg_reg[2:1] == 2'b11)
            sig_out <= 1'b1;
        else if(deg_reg[2:1] == 2'b00)
            sig_out <= 1'b0;
    end

endmodule