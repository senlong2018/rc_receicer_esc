module TC;
`include "../../tb/waveform.v"
`include "../../tb/task.v"

initial begin
  @(posedge tb.reset_n);
  #100;
  $display("[TC] Task7 verification: start");

  // stimulus: wait for boot then press col0
  repeat (200) @(posedge tb.clk);
  $display("[TC] Stim: press key on col[0]");
  // use key_matrix_model task to simulate a real key press with debounce
  // index: 0..15 (row * 4 + col), duration in ms
  tb.key_matrix_model_inst.press_key(0, 100); // press key 0 for 100 ms
  $display("[TC] Stim done");

  // wait additional cycles then finish
  repeat (5000) @(posedge tb.clk);
  $display("[TC] Done");
  SIMREPORT.terminate();
end

endmodule
