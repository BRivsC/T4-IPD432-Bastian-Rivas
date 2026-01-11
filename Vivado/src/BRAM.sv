`timescale 1ns / 1ps
// Módulo de memoria BRAM parametrizable
// Recibe 1 elemento por vez para escritura, guardándolo en base a la dirección dada
// Retorna los datos almacenados completos en un arreglo

module BRAM #(parameter NUM_ELEMENTOS = 1024, SIZE = 10, NBITS = 10)(
    
    input clk, rst,
    input write,
    input logic [SIZE-1:0] addr,
    input logic [NBITS-1:0] din,

    output  logic [NBITS-1:0] out [NUM_ELEMENTOS-1:0] 
    );
    
    
    logic [NBITS-1:0] out_next [NUM_ELEMENTOS-1:0];

    always_ff @(posedge clk) begin
        if (rst)
            out <= '{NUM_ELEMENTOS{0}};                        
        else                            
            out <= out_next;                                              
    end
    always_comb begin
        if(write) begin
            out_next = out;
            out_next[addr] = din;
            end
        else
            out_next = out;
    end
    
endmodule
