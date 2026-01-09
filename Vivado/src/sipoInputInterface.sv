`timescale 1ns / 1ps
// Módulo de interfaz de entrada con memorias, controlador de escritura, decodificador de comandos y contador de direcciones.

module sipoInputInterface#(
    parameter NUM_ELEMENTOS = 8
)(
    input logic input_domain_clk, reset, rx_ready, begin_write, op_done,
    input logic [7:0] rx_data,
    //input logic [9:0] read_mem_dir,
    output logic write_done, command_ready,
    output logic [7:0] command, //  Sigue formato para CtrlUnit (dir memoria 0A, 1B, write, read, sum, avg, euc dist, man dist y dot prod)
    output logic [9:0] data_a [NUM_ELEMENTOS-1:0],
    output logic [9:0] data_b [NUM_ELEMENTOS-1:0]
    );

    logic [9:0] write_data;
    //logic [9:0] write_address;
    logic [6:0] command_out;
    logic [7:0] recv_data;
    logic count_done;
    logic wea_a, wea_b, bram_sel;
    assign recv_data = rx_data;
    assign command = {bram_sel, command_out}; 


    writeCtrl u_writeCtrl (
        .clk           (input_domain_clk),
        .reset         (reset),
        .rx_ready      (rx_ready),
        .en            (begin_write),   
        .bram_sel      (bram_sel),
        .rx_data       (recv_data),
        .write_done    (write_done),
        .count_done    (count_done),
        .inc           (inc),
        .wea_a         (wea_a),
        .wea_b         (wea_b),
        .dout          (write_data)
    );

    nbit_counter_inc #(
        .N        (10),
        .MAX_COUNT(NUM_ELEMENTOS)
    ) write_address_counter (
        .clk      (input_domain_clk),
        .reset    (reset),
        .inc      (inc),
        //.count    (write_address), // edit: ahora sólo se usa para contar cuántos elem han sido escritos
        .count    (),
        .count_done (count_done)
    );
    
    // Nota: op_code y bram_info vienen del byte recibido por rx_data
    // Formato: [bram_sel(1 bit)][unused(4 bits)][op_code(3 bits)]
    logic [2:0] op_code_in;
    logic bram_info_in;
    assign op_code_in = rx_data[2:0];
    assign bram_info_in = rx_data[7];


    commandDecoder u_commandDecoder (
        .clk              (input_domain_clk),
        .reset            (reset),
        .rx_ready         (rx_ready),
        .op_done          (op_done || write_done),  // Se reinicia mientras se manda un dato (conectar op_done a begin_transmision)
        .bram_info_in     (bram_info_in),
        .op_code_in       (op_code_in),
        .bram_sel         (bram_sel),
        .command_out      (command_out), // {en_dot, en_man, en_euc, en_avg, en_sum, en_read, en_write}
        .command_ready    (command_ready)
    );

    shiftSipoMem #(
        .IWIDTH     (10),
        .NINPUTS    (NUM_ELEMENTOS)
    ) MemA (
        .clk        (input_domain_clk),
        .enable     (wea_a),
        .in         (write_data),
        .out        (data_a)
    );

    shiftSipoMem #(
        .IWIDTH     (10),
        .NINPUTS    (NUM_ELEMENTOS)
    ) MemB (
        .clk        (input_domain_clk),
        .enable     (wea_b),
        .in         (write_data),
        .out        (data_b)
    );

/*
    sipoMem #(
        .IWIDTH     (10),
        .NINPUTS    (NUM_ELEMENTOS)
    ) MemA (
        .clk        (input_domain_clk),
        .we         (wea_a),
        //.rst        (reset),
        .addr       (write_address),
        .in         (write_data),
        .out        (data_a)
    );

    sipoMem #(
        .IWIDTH     (10),
        .NINPUTS    (NUM_ELEMENTOS)
    ) MemB (
        .clk        (input_domain_clk),
        .we         (wea_b),
        //.rst        (reset),
        .addr       (write_address),
        .in         (write_data),
        .out        (data_b)
    );
*/


endmodule