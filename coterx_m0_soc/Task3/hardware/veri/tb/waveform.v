//=====================================================
//
//generate the waves
//
//=====================================================


`ifdef VPD
  initial begin
    $vcdpluson(0,        TC);
    $vcdpluson(0,        TB);
    $vcdpluson(0, SIMREPORT);
    $vcdplustraceon;
  end 

`else
  initial begin
    $fsdbDumpon;
    $fsdbDumpvars(0,tb);
    $fsdbDumpvars(0,TC);
    $fsdbDumpvars(0,SIMREPORT);
  end 
`endif