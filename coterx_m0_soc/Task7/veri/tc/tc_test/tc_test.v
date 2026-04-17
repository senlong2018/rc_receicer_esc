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
  tb.col = 4'b1110; // assert column 0 (active low)
  repeat (1000) @(posedge tb.clk);
  tb.col = 4'b1111; // release
  $display("[TC] Stim done");

  // wait additional cycles then finish
  repeat (5000) @(posedge tb.clk);
  $display("[TC] Done");
  $finish;
end

endmodule
