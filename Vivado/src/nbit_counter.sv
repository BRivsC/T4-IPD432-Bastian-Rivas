`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
// University: Universidad Tecnica Federico Santa Maria
// Course: ELO212
// Students: Cristobal Caqueo, Bastian Rivas, Claudio Zanetta
// 
// Create Date: 03/05/2022
// Design Name: Guia 4
// Module Name: S4_actividad1
// Project Name: nbit_counter
// Target Devices: xc7a100tcsg324-1
// Tool Versions: Vivado 2021.1
// Description: Contador de N bits (por defecto 4)
// 
// Dependencies: Lab Digitales
// 
// Revision: 0.01
// Revision 0.01 - File Created
// Additional Comments: Obtenida de la pregunta 3.7, guía 2
//                      Modificado para incluir la función de contar y descontar
// 
//////////////////////////////////////////////////////////////////////////////////

module nbit_counter_inc #(parameter N = 10, MAX_COUNT = 1024)(
    input  logic          clk, reset, inc,
    output logic          count_done,
    output logic [N-1:0]  count
);
    always_ff @(posedge clk) begin
        // Se activa al pasar por el flanco de subida del reloj
        if (reset) begin
            count <= 'd0;          // Reinicia el contador
            count_done <= 1'b0;    // Señal de "done" en bajo
        end else if (inc) begin
            if (count == MAX_COUNT - 1) begin
                count <= 'd0;      // Reinicia el contador al alcanzar el máximo
                count_done <= 1'b1; // Señal de "done" en alto
            end else begin
                count <= count + 1; // Incrementa el contador
                count_done <= 1'b0; // Señal de "done" en bajo
            end
        end else begin
            count_done <= 1'b0;    // Mantiene "done" en bajo si no hay incremento
        end
    end
endmodule