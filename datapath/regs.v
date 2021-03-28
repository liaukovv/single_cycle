module regs(input clk, 
            input we3, 
            input  [3:0] ra1, ra2, wa3, 
            input  [31:0] wd3, r15,
            output [31:0] rd1, rd2);

reg [31:0] rf[14:0];

// three ported register file
// read two ports combinationally
// write third port on rising edge of clock
// register 15 reads PC+8 instead

always @(posedge clk)
  if (we3) rf[wa3] <= wd3;	

assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];

endmodule