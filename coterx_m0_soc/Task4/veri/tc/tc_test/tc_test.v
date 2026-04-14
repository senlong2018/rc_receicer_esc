module TC;
`include "../../tb/waveform.v"
`include "../../tb/task.v"

initial begin
  @(posedge tb.reset_n);
  #100;
  $display("[TC] Task3 verification: monitor LED outputs from SoC");

  // simple stimulus: wait and then finish
  repeat (5000) @(posedge tb.clk);

  $display("[TC] Done");
  $finish;
end

endmodule
