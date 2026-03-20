`timescale 1ns/1ps
// Memoria que recibe datos en formato paralelo y los retorna de forma serial
// Funciona como un shift register que se carga con una señal 'load' y empieza
// a shiftear y retornar valores al recibir una señal 'en'.
// Para una entrada paralela retorna del menos significativo al más significativo

module pisoMem#(
    parameter IWIDTH = 10,
    parameter NINPUTS = 8
)(
    input logic clk,
    input logic load, en, //rst,
    input logic [IWIDTH-1:0] in [NINPUTS-1:0],
    output logic [IWIDTH-1:0] out
);
    logic [IWIDTH-1:0] shift_regs [NINPUTS-1:0];

    // Cargar y shiftear
    always_ff @(posedge clk) begin 
        if (load) begin
            for (int i = 0; i < NINPUTS; i++) begin
                shift_regs[i] <= in[i];
            end
        end else if (en) begin
        // Shiftear de más significativo a menos
            for (int i = 0; i < NINPUTS-1; i++) begin
                shift_regs[i] <= shift_regs[i+1];
            end
            shift_regs[NINPUTS-1] <= shift_regs[NINPUTS-1]; // Retiene el más significativo para no rellenar con X
        end 
    end

    // Tomar el menos significativo como salida
    always_ff @(posedge clk) begin
        out <= shift_regs[0];
    end

endmodule