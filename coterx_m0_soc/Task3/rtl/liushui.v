// liushui.v
// SystemVerilog implementation of WaterLight (流水灯) module
// - Each important signal uses a separate sequential block (one-signal-per-always)
// - Uses shadow/work registers for atomic config update
// - Supports left-rotate, right-rotate and flash modes

module liushui (
    input  logic        clk,
    input  logic        rstn,              // active-low reset (cpuresetn)
    input  logic [31:0] WaterLight_speed,  // configuration: speed (clock cycles)
    input  logic [1:0]  WaterLight_mode,   // configuration: mode (0..3)
    output logic [7:0]  light_o            // output GPIO pattern
);

    // design parameter: minimum speed threshold to consider 'running'
    localparam int MIN_SPEED = 100_000;

    // -------------------------
    // Internal registers (single-signal always_ff each)
    // -------------------------
    // shadow registers capture recent writes from CPU (staging area)
    logic [31:0] shadow_speed; // shadow copy of incoming speed (staged)
    logic [1:0]  shadow_mode;  // shadow copy of incoming mode (staged)
    logic        pending_update; // when 1, a config change is pending application

    // working registers used by the active running logic
    logic [31:0] work_speed; // active speed used by counter
    logic [1:0]  work_mode;  // active mode used by pattern update

    // counter and pattern
    logic [31:0] cnt;     // free-running counter used to compare with work_speed
    logic [7:0]  pattern; // internal 8-bit pattern rotated/toggled

    // -------------------------
    // Combinational helpers
    // -------------------------
    logic counting_active_when_shadow; // whether shadow config would allow counting
    logic counting_active_work;        // whether work config allows counting
    logic apply_event;                 // when 1, apply shadow -> work on next cycle
    logic pulse_event;                 // when 1, indicates a timing pulse to advance pattern

    // compute combinational status flags
    always_comb begin
        counting_active_when_shadow = (shadow_mode != 2'b00) && (shadow_speed >= MIN_SPEED);
        counting_active_work       = (work_mode   != 2'b00) && (work_speed   >= MIN_SPEED);
        // apply_event: when pending_update and shadow indicates runnable and counter reaches threshold
        // note: actual comparison uses cnt and shadow_speed (sequentially evaluated in cnt logic)
        apply_event = 1'b0;  // placeholder, resolved in sequential logic via handshake signals
        pulse_event = 1'b0;  // placeholder, resolved in sequential logic
    end

    // rotate helpers as pure functions (SystemVerilog)
    function automatic logic [7:0] rol8(logic [7:0] x);
        rol8 = {x[6:0], x[7]};
    endfunction

    function automatic logic [7:0] ror8(logic [7:0] x);
        ror8 = {x[0], x[7:1]};
    endfunction

    // -------------------------
    // Sequential: shadow_speed
    // capture external writes into shadow registers; independent always_ff for single-signal rule
    // -------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            shadow_speed <= '0;
        else if (WaterLight_speed != shadow_speed || WaterLight_mode != shadow_mode)
            shadow_speed <= WaterLight_speed;
        else
            shadow_speed <= shadow_speed;
    end

    // -------------------------
    // Sequential: shadow_mode
    // -------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            shadow_mode <= 2'd0;
        else if (WaterLight_speed != shadow_speed || WaterLight_mode != shadow_mode)
            shadow_mode <= WaterLight_mode;
        else
            shadow_mode <= shadow_mode;
    end

    // -------------------------
    // Sequential: pending_update
    // - set when config changes
    // - cleared when apply_event occurs (work registers updated)
    // -------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            pending_update <= 1'b0;
        else if (WaterLight_speed != shadow_speed || WaterLight_mode != shadow_mode)
            pending_update <= 1'b1;
        else if (apply_event)
            pending_update <= 1'b0;
        else
            pending_update <= pending_update;
    end

    // -------------------------
    // Sequential: cnt (single-signal block)
    // - handles counting for both shadow-apply and normal operation
    // - produces pulse_event when threshold reached
    // -------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt <= '0;
            // pulse_event is combinational placeholder; not stored here
        end else begin
            if (pending_update) begin
                if (counting_active_when_shadow) begin
                    if (cnt + 1 >= shadow_speed) begin
                        cnt <= '0; // will trigger apply_event in adjacent logic
                    end else begin
                        cnt <= cnt + 1;
                    end
                end else begin
                    cnt <= '0;
                end
            end else begin
                if (counting_active_work) begin
                    if (cnt + 1 >= work_speed) begin
                        cnt <= '0; // will trigger pulse_event
                    end else begin
                        cnt <= cnt + 1;
                    end
                end else begin
                    cnt <= '0;
                end
            end
        end
    end

    // -------------------------
    // Sequential: work_speed (applied when apply_event)
    // -------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            work_speed <= '0;
        else if (pending_update && (cnt == '0) && counting_active_when_shadow && shadow_speed != 0)
            work_speed <= shadow_speed; // apply shadow when counter reached
        else
            work_speed <= work_speed;
    end

    // -------------------------
    // Sequential: work_mode (applied when apply_event)
    // -------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            work_mode <= 2'd0;
        else if (pending_update && (cnt == '0) && counting_active_when_shadow && shadow_speed != 0)
            work_mode <= shadow_mode;
        else
            work_mode <= work_mode;
    end

    // -------------------------
    // Combinational: derive apply_event and pulse_event from cnt and contexts
    // -------------------------
    always_comb begin
        // apply_event: pending_update and previous cnt reached threshold (cnt==0 after wrap)
        // Note: rely on precise sequencing: we set work_* when pending_update and cnt wrapped to 0
        apply_event = pending_update && counting_active_when_shadow && (cnt == 32'd0);
        // pulse_event: no pending_update and cnt wrapped to 0 indicates a pattern advance
        pulse_event = (!pending_update) && counting_active_work && (cnt == 32'd0);
    end

    // -------------------------
    // Sequential: pattern (single-signal block)
    // - initiates on apply_event, advances on pulse_event
    // -------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pattern <= 8'h00;
        end else begin
            if (apply_event) begin
                unique case (shadow_mode)
                    2'b01: pattern <= 8'h01; // left start
                    2'b10: pattern <= 8'h80; // right start
                    2'b11: pattern <= 8'hFF; // flash start (all ones)
                    default: pattern <= 8'h00;
                endcase
            end else if (pulse_event) begin
                unique case (work_mode)
                    2'b01: pattern <= rol8(pattern); // left rotate
                    2'b10: pattern <= ror8(pattern); // right rotate
                    2'b11: pattern <= ~pattern;      // toggle
                    default: pattern <= 8'h00;
                endcase
            end else begin
                // when inactive, keep pattern at zero
                if (!counting_active_work && !pending_update)
                    pattern <= 8'h00;
                else
                    pattern <= pattern;
            end
        end
    end

    // -------------------------
    // Sequential: light_o (single-signal block)
    // drive output consistently from pattern
    // -------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            light_o <= 8'h00;
        else
            light_o <= pattern;
    end

endmodule

