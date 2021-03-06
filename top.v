module top(input  clk, reset, 
           output [31:0] WriteData, DataAdr, 
           output MemWrite);

  wire [31:0] PC, Instr, ReadData;
  
  // instantiate processor and memories
  arm arm(clk, reset, PC, Instr, MemWrite, DataAdr, 
          WriteData, ReadData);

  instr_mem imem(.addr(PC), 
                 .d(Instr));

  data_mem dmem(.clk(clk), 
                .we(MemWrite), 
                .addr(DataAdr), 
                .wd(WriteData), 
                .rd(ReadData));
endmodule