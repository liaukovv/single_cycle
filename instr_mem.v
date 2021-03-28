module instr_mem(input  [31:0] addr,
                 output [31:0] d);

  reg [31:0] mem[63:0];

  initial
      $readmemh("instrmem.dat",mem);

  assign d = mem[addr[31:2]]; // word aligned
endmodule