`timescale 1ns / 1ps
// Memoria que guarda los resultados en forma vectorial y escalar
// Los escalares son Euc y Dot, mientras que el vector es Read
// Las señales de control importantes vienen del ctrl unit, pero los datos vienen del processing core

module resultMem #(
    parameter NINPUTS = 1024
)(
    input [31:0] par_data_in [NINPUTS-1:0],
    input [31:0] single_data_in,
    input [2:0] op_code,
    input clk,// rst,
    input load_mem, shift_mem,

    output logic [31:0] result_out
    );

    logic [31:0] piso_result;
    logic [31:0] single_data_ff;

    pisoMem #(
        .IWIDTH     (32),
        .NINPUTS    (NINPUTS)
    ) u_pisoMem (
        .clk        (clk),
        .load       (load_mem),
        .en         (shift_mem),
        //.rst        (rst),
        .in         (par_data_in),
        .out        (piso_result)
    );

    // Registro para dato escalar
    always_ff @(posedge clk) begin
        if (load_mem) begin
            single_data_ff <= single_data_in;
        end
    end

    // Seleccionar entre resultado de Manhattan y los otros
    always_comb begin
        if (op_code == 3'b010 ) begin // read
            result_out = piso_result;
        end else begin              // euc o dot 
            result_out = single_data_ff;
        end
    end

endmodule
