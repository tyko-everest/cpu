module tb;
  reg [31:0] a, b;
  reg [2:0] mode;
  wire [31:0] q;
  
  alu alu_test (.a(a), .b(b), .q(q), .mode(mode));
  
  initial
    begin
      $dumpfile("test.vcd");
  	  $dumpvars;
      a = 32'h11;
      b = 32'h10;
      mode = 3'b000;
      #5;
      mode = 3'b001;
      #5;
    end
endmodule