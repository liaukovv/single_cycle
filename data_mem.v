module data_mem(input clk, we,
                input [31:0] addr, wd,
                output [31:0] rd);

  reg [31:0] mem[63:0];

  assign rd = mem[addr[31:2]]; // word aligned

  always @(posedge clk)
    if(we) 
        mem[addr[31:2]] <= wd;

endmodule