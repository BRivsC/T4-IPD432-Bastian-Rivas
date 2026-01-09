`timescale 1ns/1ps
// Suma paralela de vectores A y B
// Parecida al Adder tree pero es de solo 1 etapa
//  (A)sum(0) --|\  sum(8)
//              |+|-------
//  (B)sum(1) --|/        
//                        
//  (A)sum(2) --|\	 sum(9)
//              |+|-------
//  (B)sum(3) --|/         
//                         
//  (A)sum(4) --|\	 sum(10)
//              |+|--------
//  (B)sum(5) --|/			
//						
//  (A)sum(6) --|\	 sum(11)
//              |+|--------
//  (B)sum(7) --|/
//
module parallelSumVec #(
    parameter IWIDTH = 10,      
    parameter NINPUTS = 8       
)(
    input  logic clk,
    input  logic [IWIDTH-1:0] data_A [NINPUTS-1:0], 
    input  logic [IWIDTH-1:0] data_B [NINPUTS-1:0], 
    output logic [31:0] out [NINPUTS-1:0]
);
    genvar i;
    generate
        for (i=0; i < NINPUTS ; i++) begin
            always_ff @(posedge clk) begin
                    out[i] <= data_A[i] + data_B[i];
            end
        end
    endgenerate
endmodule