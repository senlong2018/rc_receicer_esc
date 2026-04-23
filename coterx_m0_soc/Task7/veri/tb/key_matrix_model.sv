
module key_matrix_model (
    input  wire [3:0] row,    // 假设 FPGA 驱动 Row
    output wire [3:0] col     // 假设 FPGA 读取 Col
);

    // 内部状态：16个按键的状态，0表示按下，1表示释放
    // 对应关系：key_state[row_index * 4 + col_index]
    reg [15:0] key_state;

    initial begin
        key_state = 16'hffff;
    end

    // 模拟电路连接特性：
    // 当某一行为低电平(0)，且该行对应的按键被按下时，对应的列会被拉低。
    // 默认列由上拉电阻拉高(1)。
    assign col[0] = ~( (row[0] == 1'b0 && ~key_state[0])  || 
                       (row[1] == 1'b0 && ~key_state[4])  || 
                       (row[2] == 1'b0 && ~key_state[8])  || 
                       (row[3] == 1'b0 && ~key_state[12]) );

    assign col[1] = ~( (row[0] == 1'b0 && ~key_state[1])  || 
                       (row[1] == 1'b0 && ~key_state[5])  || 
                       (row[2] == 1'b0 && ~key_state[9])  || 
                       (row[3] == 1'b0 && ~key_state[13]) );

    assign col[2] = ~( (row[0] == 1'b0 && ~key_state[2])  || 
                       (row[1] == 1'b0 && ~key_state[6])  || 
                       (row[2] == 1'b0 && ~key_state[10]) || 
                       (row[3] == 1'b0 && ~key_state[14]) );

    assign col[3] = ~( (row[0] == 1'b0 && ~key_state[3])  || 
                       (row[1] == 1'b0 && ~key_state[7])  || 
                       (row[2] == 1'b0 && ~key_state[11]) || 
                       (row[3] == 1'b0 && ~key_state[15]) );

    // 辅助 Task：模拟一次带抖动的按键动作
    task press_key(input [3:0] index, input integer duration_ms);
        integer i;
        begin
            $display("[KEY_MODEL] Pressing Key %0d at %t", index, $time);
            // 1. 模拟按下抖动 (模拟 5ms 内随机跳变)
            for (i = 0; i < 30; i = i + 1) begin
                key_state[index] = ~key_state[index];
                #($urandom_range(10000, 50000)); // 0.1ms ~ 0.5ms 抖动
            end
            
            // 2. 稳定按下状态
            key_state[index] = 1'b0;
            #(duration_ms * 100); // 持续指定毫秒
            
            // 3. 模拟释放抖动
            for (i = 0; i < 30; i = i + 1) begin
                key_state[index] = ~key_state[index];
                #($urandom_range(10000, 50000));
            end
            
            // 4. 彻底释放
            key_state[index] = 1'b1;
            $display("[KEY_MODEL] Released Key %0d at %t", index, $time);
        end
    endtask

endmodule