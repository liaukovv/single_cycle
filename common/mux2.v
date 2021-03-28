module mux2 #(parameter N = 8)
             (input[N-1:0] a, b, 
              input sel, 
              output[N-1:0] y);

assign y = sel ? b : a; 

endmodule