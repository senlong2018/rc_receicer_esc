
// task pwm_enable;
//      tb.pwm_gen_en = 1'b1;
// endtask

// task pwm_disable;
//      tb.pwm_gen_en = 1'b0;
// endtask

// task load_period_val;
// 	input [31:0]period;
// 	tb.counter_arr = period;
// endtask

// task load_duty_val;
// 	input [31:0]duty;
// 	tb.counter_crr = duty;
// endtask

// task key_press;
// 	tb.key_press = 0;
// 	#200;
// 	tb.key_press = 1;
// 	#200
// 	tb.key_press = 0;
// endtask