module datapath(input         clk, reset,
                input  [1:0]  RegSrc,
                input         RegWrite,
                input  [1:0]  ImmSrc,
                input         ALUSrc,
                input  [3:0]  ALUControl,
                input         MemtoReg,
                input         PCSrc,
                input         MemByte,
                output [3:0]  ALUFlags,
                output [31:0] PC,
                input  [31:0] Instr,
                output [31:0] ALUResult, WriteData,
                input  [31:0] ReadData);

wire [31:0] PCNext;
wire [31:0] PCPlus4; 
wire [31:0] PCPlus8;
wire [31:0] ExtImm, SrcA, SrcB, Result;
wire [3:0]  RA1, RA2;
wire [31:0] ReadDataByte, ReadDataRes;
wire [7:0] ByteToExtend;

// this flip-flop holds current PC value
ff_res #(32) pcreg(.clk(clk), .reset(reset), .d(PCNext), .q(PC));
// select next pc source
mux2 #(32)  pcmux(.a(PCPlus4), .b(Result), .sel(PCSrc), .y(PCNext));
// adders to calculate next instruction and R15 out
adder #(32) pcadd4(.a(PC), .b(32'b100), .y(PCPlus4));
adder #(32) pcadd8(.a(PCPlus4), .b(32'b100), .y(PCPlus8));

// select address for first port of reg file
mux2 #(4) ra1mux(.a(Instr[19:16]), .b(4'b1111), .sel(RegSrc[0]), .y(RA1));
// select address for second port of reg file
mux2 #(4) ra2mux(.a(Instr[3:0]), .b(Instr[15:12]), .sel(RegSrc[1]), .y(RA2));
// register file, for r15 always outputs pc+8
regs register_file(.clk(clk),
                   .we3(RegWrite),
                   .ra1(RA1),
                   .ra2(RA2),
                   .wa3(Instr[15:12]),
                   .wd3(Result),
                   .r15(PCPlus8),
                   .rd1(SrcA),
                   .rd2(WriteData));
// selects if result of op is memory read or alu                   
mux2 #(32) resmux(.a(ALUResult), .b(ReadDataRes), .sel(MemtoReg), .y(Result));

// select which byte to zero-extend
mux4 #(8) bytemux(.a(ReadData[7:0]), .b(ReadData[15:8]), .c(ReadData[23:16]), .d(ReadData[31:24]), .sel(ALUResult[1:0]), .y(ByteToExtend));

// zero-extends memory for byte-memory ops
extender memext(.x({16'd0, ByteToExtend}), 
             .src(2'b00),
             .y(ReadDataByte));

// selects either extended byte or non-extended word
mux2 #(32) memextmux(.a(ReadData), .b(ReadDataByte), .sel(MemByte), .y(ReadDataRes));

// extends immediate in different modes
extender ext(.x(Instr[23:0]), 
             .src(ImmSrc), 
             .y(ExtImm));

// select source of b operand of alu
mux2 #(32)  srcbmux(.a(WriteData), .b(ExtImm), .sel(ALUSrc), .y(SrcB));
// ALU
alu alu(.a(SrcA),
        .b(SrcB),
        .ctrl(ALUControl),
        .res(ALUResult),
        .flags(ALUFlags));

endmodule