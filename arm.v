module arm(input  clk, reset,
           output [31:0] PC,
           input  [31:0] Instr,
           output        MemWrite,
           output [31:0] ALUResult, WriteData,
           input  [31:0] ReadData);

wire [3:0] ALUFlags;
wire RegWrite, ALUSrc, MemtoReg, PCSrc;
wire [1:0] RegSrc, ImmSrc; 
wire [3:0] ALUControl;

controller c(.clk(clk), 
             .reset(reset), 
             .Instr(Instr[31:12]), 
             .ALUFlags(ALUFlags), 
             .RegSrc(RegSrc), 
             .RegWrite(RegWrite), 
             .ImmSrc(ImmSrc), 
             .ALUSrc(ALUSrc), 
             .ALUControl(ALUControl),
             .MemWrite(MemWrite), 
             .MemtoReg(MemtoReg), 
             .PCSrc(PCSrc),
             .MemByte(MemByte));

datapath dp(.clk(clk),
            .reset(reset),
            .RegSrc(RegSrc),
            .RegWrite(RegWrite),
            .ImmSrc(ImmSrc),
            .ALUSrc(ALUSrc),
            .ALUControl(ALUControl),
            .MemtoReg(MemtoReg),
            .PCSrc(PCSrc),
            .ALUFlags(ALUFlags),
            .MemByte(MemByte),
            .PC(PC),
            .Instr(Instr),
            .ALUResult(ALUResult),
            .WriteData(WriteData),
            .ReadData(ReadData));

endmodule