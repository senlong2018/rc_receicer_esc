module TC;
`include "../../tb/waveform.v"
`include "../../tb/task.v"

event debug1;
event debug2;
event debug3;


initial begin
  @(posedge tb.reset_n);
  #100;
  repeat(20) begin
    key_press;
    #(P_1MS);
    #(P_1US*500);
  end

  SIMREPORT.terminate;
end 


endmodule
