module ff_resen #(parameter N = 8)
                (input clk, reset, en,
                 input [N-1:0] d, 
                 output reg [N-1:0] q);

always @(posedge clk, posedge reset)
    if (reset)   
        q <= 0;
    else 
        if(en) 
            q <= d;

endmodule