module SIMREPORT();

  integer Errors;
  integer Warnings;
  
  initial begin
    Errors = 'd0;
    Warnings = 'd0;
  end 
  
  task error;
    input [80*8 : 0] msg;
    begin
      $write("the ERROR at: %0t, %0s\n", $time, msg);
      Errors = Errors +1'b1;
    end 
  endtask
  
  task warning;
    input [80*8 : 0] msg;
    begin
      $write("the WARNING at: %0t, %0s\n", $time, msg);
      Warnings = Warnings +1'b1;
    end 
  endtask
  
  task terminate;
    begin
      $write("===========================================================================\n");
      $write("the simulation is finished at %0t\n", $time);
      if(Warnings == 'd0 && Errors == 'd0)begin
        $write("  \n");
        $write("  \n");
        $write(" PPPPPPPPPPPP             A              SSSSSSSSSS      SSSSSSSSSS      \n");
        $write(" P           P           A A            S               S                \n");
        $write(" P            P         A   A          S               S                 \n");
        $write(" P            P        A     A         S               S                 \n");
        $write(" P           P        A       A         S               S                \n");
        $write(" PPPPPPPPPPPP        A A A A A A         SSSSSSSSSS      SSSSSSSSSS      \n");
        $write(" P                  A           A                  S               S     \n");
        $write(" P                 A             A                  S               S    \n");
        $write(" P                A               A                 S               S    \n");
        $write(" P               A                 A               S               S     \n");
        $write(" P              A                   A   SSSSSSSSSSS     SSSSSSSSSSS      \n");
        $write("  \n");
        $write("  \n");
        $write("the TOTAL ERORRS is %0d \n", Errors);   
        $write("the TOTAL WARNINGS is %0d \n", Warnings);   
      end 
      else begin
        $write("  \n");
        $write("  \n");
        $write(" FFFFFFFFFFFF             A             IIIIIII     L                    \n");
        $write(" F                       A A               I        L                    \n");
        $write(" F                      A   A              I        L                    \n");
        $write(" F                     A     A             I        L                    \n");
        $write(" F                    A       A            I        L                    \n");
        $write(" FFFFFFFFFFFF        A A A A A A           I        L                    \n");
        $write(" F                  A           A          I        L                    \n");
        $write(" F                 A             A         I        L                    \n");
        $write(" F                A               A        I        L                    \n");
        $write(" F               A                 A       I        L          L         \n");
        $write(" F              A                   A   IIIIIII     LLLLLLLLLLL          \n");
        $write("  \n");
        $write("  \n");
        $write("the TOTAL ERORRS is %0d \n", Errors );   
        $write("the TOTAL WARNINGS is %0d \n", Warnings);   
      end 
      $write("===========================================================================\n");
      $finish;
    end 
  endtask
endmodule
