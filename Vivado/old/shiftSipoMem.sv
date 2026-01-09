`timescale 1ns/1ps
// Memoria que recibe una palabra por vez y las retorna en una salida paralela
// Imita al funcionamiento de un puerto de BRAM con su dato y Write Enable

module shiftSipoMem#(
    parameter IWIDTH = 10,
    parameter NINPUTS = 8
)(
    input logic clk, enable,
    input logic [IWIDTH-1:0] in,
    output logic [IWIDTH-1:0] out [NINPUTS-1:0] 
);

always_ff @(posedge clk) begin
    if (enable) begin
        for (int i = 0; i < NINPUTS-1; i++) begin
            out[i] <= out[i+1];         // shift hacia abajo (LSB <- MSB)
        end
        out[NINPUTS-1] <= in;           // dato nuevo entra por MSB
    end
end



endmodule