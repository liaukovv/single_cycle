module mux4 #(parameter N = 8)
             (input[N-1:0] a, b, c, d,
              input[1:0] sel, 
              output[N-1:0] y);

assign y = sel == 00 ? a : 
           sel == 01 ? b :
           sel == 10 ? c :
                       d ;   

endmodule