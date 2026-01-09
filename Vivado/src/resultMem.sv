`timescale 1ns / 1ps
// Memoria que guarda los resultados en forma vectorial y escalar
// Por ahora el único escalar es el de manDist
module resultMem #(
    parameter NINPUTS = 8
)(
    input [31:0] par_data_in [NINPUTS-1:0],
    input [31:0] man_data_in,
    input [5:0] enables,
    input clk,// rst,
    input load_mem, shift_mem,

    output logic [31:0] result_out
    );

    logic [31:0] ser_result;
    logic [31:0] man_result_ff;

    pisoMem #(
        .IWIDTH     (32),
        .NINPUTS    (NINPUTS)
    ) u_pisoMem (
        .clk        (clk),
        .load       (load_mem),
        .en         (shift_mem),
        //.rst        (rst),
        .in         (par_data_in),
        .out        (ser_result)
    );

    // Registro para Manhattan
    always_ff @(posedge clk) begin
        //if (rst) begin
        //    man_result_ff <= 1'b0;
        //end else
        if (load_mem) begin
            man_result_ff <= man_data_in;
        end
    end

    // Seleccionar entre resultado de Manhattan y los otros
    always_comb begin
        if (enables[0] || enables[1] || enables[2]) begin // read, sum o avg
            result_out = ser_result;
        end else begin
            result_out = man_result_ff;
        end
    end

endmodule
