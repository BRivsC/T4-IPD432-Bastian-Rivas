`timescale 1ns / 1ps

module BRAM #(parameter WIDTH = 1024,SIZE = 10, NBITS = 10)(
    
    input clk, //rst,
    input write,
    input logic [SIZE-1:0] addr,
    input logic [NBITS-1:0] din, //dato de entrada
 
    output  logic [NBITS-1:0] out [WIDTH-1:0] 
    );
    
    
    logic [NBITS-1:0] out_next [WIDTH-1:0];
    /*
    always_ff @(posedge clk) begin
        if (rst)
           out <= '{WIDTH{0}};                        
        else                            
            out <= out_next;                                              
    end
    */
    always_comb begin
        if(write) begin
            out_next = out;
            out_next[addr] = din;
            end
        else
            out_next = out;
    end
    
endmodule
