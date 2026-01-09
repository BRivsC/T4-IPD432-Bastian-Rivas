`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 11:28:27 PM
// Design Name: 
// Module Name: pipelinedProcessingCore
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Recibe datos en paralelo y los retorna serial
// 
//////////////////////////////////////////////////////////////////////////////////


module pipelinedProcessingCore #(
    parameter NINPUTS = 8
)(
    input [9:0] data_A [NINPUTS-1:0],
    input [9:0] data_B [NINPUTS-1:0],
    input [5:0] enables,
    input clk,
    input read_mem_sel,

    output logic [31:0] par_result [NINPUTS- 1:0], // Vectores resultado en paralelo
    output logic [31:0] man_result // Resultado de manhattan como escalar
    );

    localparam IWIDTH = 10;
    localparam OWIDTH = IWIDTH + $clog2(NINPUTS);
    
    
    logic [31:0]result_read [NINPUTS-1:0];
    logic [31:0]result_sum  [NINPUTS-1:0];
    logic [31:0]result_avg  [NINPUTS-1:0];
    logic [9:0]result_resta[NINPUTS-1:0];


    // Lectura: escoger memoria a leer
    always_comb begin: readVec
        if (read_mem_sel) begin
            foreach (result_read[i]) begin 
                result_read[i] = {22'd0,data_B[i]};
            end
        end else begin
            foreach (result_read[i]) begin
                result_read[i] = {22'd0,data_A[i]};
            end
        end
    end: readVec


    // Suma por elementos, usada x sum y avg
    // Revisar si me conviene más comb o ff!
    // En teoría toma 1 ciclo
    parallelSumVec #(
        .IWIDTH     (IWIDTH),
        .NINPUTS    (NINPUTS)
    ) suma_paralela (
        .clk        (clk),
        .data_A     (data_A),
        .data_B     (data_B),
        .out        (result_sum)
    );


    // Dividir vector por 2, usada solo por avg
    // Acá me aprovecho de los sumadores ya existentes
    // En teoría agrega 1 ciclo a lo ya obtenido con la suma
    divBy2Vec #(
        .IWIDTH     (32),
        .NINPUTS    (NINPUTS)
    ) u_divBy2Vec (
        .clk        (clk),
        .data       (result_sum),
        .out        (result_avg)
    );


    // Distancia Manhattan
    // Tiene 2 etapas: una de resta y otra de sumatoria 
    absSubVec #(
        .IWIDTH     (10),
        .NINPUTS    (NINPUTS)
    ) u_absSubVec (
        .clk        (clk),
        .data_A     (data_A),
        .data_B     (data_B),
        .out        (result_resta)
    );

    AdderTree #(
        .IWIDTH     (10),
        .NINPUTS    (NINPUTS)
    ) u_AdderTree (
        .clk        (clk),
        .data       (result_resta),
        .out        (man_result)
    );



    // Mux para decidir qué operación se verá desde el puerto paralelo
    genvar i;
    always_comb begin: def_salida_paralela
        if(enables[0]) par_result = result_read;
        else if(enables[1]) par_result = result_sum;
        else if(enables[2]) par_result = result_avg;
        else 
            foreach (par_result[i]) par_result[i] = 'd0;
    end: def_salida_paralela



endmodule
