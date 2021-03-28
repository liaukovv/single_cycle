module controller(input          clk, reset,
	                input  [31:12] Instr,
                  input  [3:0]   ALUFlags,
                  output [1:0]   RegSrc,
                  output         RegWrite,
                  output [1:0]   ImmSrc,
                  output         ALUSrc, 
                  output [3:0]   ALUControl,
                  output         MemWrite, MemtoReg,
                  output         PCSrc,
                  output         MemByte);

wire [1:0] FlagW;
wire       PCS, RegW, MemW;
  
decode dec(.Op(Instr[27:26]),
           .Funct(Instr[25:20]),
           .Rd(Instr[15:12]),
           .FlagW(FlagW),
           .PCS(PCS),
           .RegW(RegW), 
           .MemW(MemW),
           .MemtoReg(MemtoReg),
           .ALUSrc(ALUSrc), 
           .ImmSrc(ImmSrc),
           .RegSrc(RegSrc), 
           .ALUControl(ALUControl),
           .MemByte(MemByte));

condlogic cl(.clk(clk),
             .reset(reset),
             .Cond(Instr[31:28]), 
             .ALUFlags(ALUFlags),
             .FlagW(FlagW),
             .PCS(PCS),
             .RegW(RegW),
             .MemW(MemW),
             .PCSrc(PCSrc),
             .RegWrite(RegWrite),
             .MemWrite(MemWrite));

endmodule

module decode(input  [1:0] Op,
              input  [5:0] Funct,
              input  [3:0] Rd,
              output reg [1:0] FlagW,
              output       PCS, RegW, MemW,
              output       MemtoReg, ALUSrc,
              output [1:0] ImmSrc, RegSrc,
              output reg [3:0] ALUControl,
              output MemByte);

  reg [10:0] controls;
  wire Branch, ALUOp;

  // Main Decoder
  always @(*)
  	casex(Op)
  	                        // Data processing immediate
  	  2'b00: if (Funct[5])  controls = 11'b00001010010; 
  	                        // Data processing register
  	         else           controls = 11'b00000010010; 
  	                        // L
  	  2'b01: if (Funct[0])  begin
                                if (Funct[2]) // LDRB
                                    controls = 11'b00011110001;
                                else // LDR
                                    controls = 11'b00011110000;
                            end  
  	                        // STR
  	         else           controls = 11'b10011101000; 
  	                        // B
  	  2'b10:                controls = 11'b01101000100; 
  	                        // Unimplemented
  	  default:              controls = 11'bx;          
  	endcase

  assign {RegSrc, ImmSrc, ALUSrc, MemtoReg, 
          RegW, MemW, Branch, ALUOp, MemByte} = controls; 
          
  // ALU Decoder             
  always @(*)
    if (ALUOp) begin                 // which DP Instr?
      case(Funct[4:1]) 
  	    4'b0100: ALUControl = 4'b0000; // ADD
  	    4'b0010: ALUControl = 4'b0010; // SUB
        4'b0000: ALUControl = 4'b0100; // AND
  	    4'b1100: ALUControl = 4'b0101; // ORR
        4'b0001: ALUControl = 4'b0110; // EOR  
  	    default: ALUControl = 4'bx;  // unimplemented
      endcase
    // update flags if S bit is set 
	// (C & V only updated for arith instructions)
      FlagW[1] = Funct[0]; // FlagW[1] = S-bit
	// FlagW[0] = S-bit & (ADD | SUB)
      FlagW[0] = Funct[0] & 
        (ALUControl == 4'b0000 | ALUControl == 4'b0010); 
    end else begin
      ALUControl = 4'b0000; // add for non-DP instructions
      FlagW      = 2'b00; // don't update Flags
    end
              
  // PC Logic
  assign PCS  = ((Rd == 4'b1111) & RegW) | Branch; 
endmodule

module condlogic(input        clk, reset,
                 input  [3:0] Cond,
                 input  [3:0] ALUFlags,
                 input  [1:0] FlagW,
                 input        PCS, RegW, MemW,
                 output       PCSrc, RegWrite, MemWrite);
                 
  wire [1:0] FlagWrite;
  wire [3:0] Flags;
  wire       CondEx;

  ff_resen #(2)flagreg1(.clk(clk), 
                       .reset(reset), 
                       .en(FlagWrite[1]), 
                       .d(ALUFlags[3:2]), 
                       .q(Flags[3:2]));
  ff_resen #(2)flagreg0(.clk(clk),
                       .reset(reset),
                       .en(FlagWrite[0]),
                       .d(ALUFlags[1:0]),
                       .q(Flags[1:0]));

  // write controls are conditional
  condcheck cc(Cond, Flags, CondEx);

  assign FlagWrite = FlagW & {2{CondEx}};
  assign RegWrite  = RegW  & CondEx;
  assign MemWrite  = MemW  & CondEx;
  assign PCSrc     = PCS   & CondEx;

endmodule    

module condcheck(input  [3:0] Cond,
                 input  [3:0] Flags,
                 output reg   CondEx);
  
  wire neg, zero, carry, overflow, ge;
  
  assign {neg, zero, carry, overflow} = Flags;
  assign ge = (neg == overflow);
                  
  always @(*)
    case(Cond)
      4'b0000: CondEx = zero;             // EQ
      4'b0001: CondEx = ~zero;            // NE
      4'b0010: CondEx = carry;            // CS
      4'b0011: CondEx = ~carry;           // CC
      4'b0100: CondEx = neg;              // MI
      4'b0101: CondEx = ~neg;             // PL
      4'b0110: CondEx = overflow;         // VS
      4'b0111: CondEx = ~overflow;        // VC
      4'b1000: CondEx = carry & ~zero;    // HI
      4'b1001: CondEx = ~(carry & ~zero); // LS
      4'b1010: CondEx = ge;               // GE
      4'b1011: CondEx = ~ge;              // LT
      4'b1100: CondEx = ~zero & ge;       // GT
      4'b1101: CondEx = ~(~zero & ge);    // LE
      4'b1110: CondEx = 1'b1;             // Always
      default: CondEx = 1'bx;             // undefined
    endcase

endmodule