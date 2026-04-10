module TC;
`include "../../tb/waveform.v"
`include "../../tb/task.v"

event debug1;
event debug2;
event debug3;


initial begin
  @(posedge tb.reset_n);
  #100;

  $display("[TC] Monitoring tb.ioPin for CPU-driven GPIO changes...");

  // wait until SoC drives ioPin to a non-zero value
  wait (tb.ioPin !== 8'h00);
  #10;
  $display("[TC] Detected ioPin = 0x%0h", tb.ioPin);

  // give some time to observe additional changes
  repeat (1000) @(posedge tb.clk);

  SIMREPORT.terminate;
end 


endmodule
