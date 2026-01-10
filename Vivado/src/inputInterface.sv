`timescale 1ns / 1ps
// Módulo de interfaz de entrada con memorias, controlador de escritura, decodificador de comandos y contador de direcciones.
// Versión tarea 4

module inputInterface#(
    parameter NUM_ELEMENTOS = 1024
)(
    input logic input_domain_clk, reset, rx_ready, write_start, op_done,
    input logic [7:0] rx_data,

    output logic write_done, command_ready, bram_sel,
    output logic [2:0] command_out, // read: 010, euc: 101, dot: 111
    output logic [9:0] data_a [NUM_ELEMENTOS-1:0],
    output logic [9:0] data_b [NUM_ELEMENTOS-1:0]
    );

    logic [9:0] write_data;
    logic [7:0] recv_data;
    logic count_done;
    logic wea_a, wea_b;
    assign recv_data = rx_data;



    writeCtrl u_writeCtrl (
        .clk           (input_domain_clk),
        .reset         (reset),
        .rx_ready      (rx_ready),
        .en            (write_start),   
        .bram_sel      (bram_sel),
        .rx_data       (recv_data),
        .write_done    (write_done),
        .count_done    (count_done),
        .inc           (inc),
        .wea_a         (wea_a),
        .wea_b         (wea_b),
        .dout          (write_data)
    );


    logic [9:0] write_address;
    nbit_counter_inc #(
        .N        (10),
        .MAX_COUNT(NUM_ELEMENTOS)
    ) write_address_counter (
        .clk        (input_domain_clk),
        .reset      (reset),
        .inc        (inc),
        .count      (write_address),
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
        .op_done          (op_done || write_done),
        .bram_info_in     (bram_info_in),
        .op_code_in       (op_code_in),
        .bram_sel         (bram_sel),
        .cmd_out          (command_out), // read: 010, euc: 101, dot: 111
        .en_write         (en_write),
        .command_ready    (command_ready)
    );


    BRAM #(
        .NUM_ELEMENTOS    (NUM_ELEMENTOS),
        .SIZE             (10),
        .NBITS            (10)
    ) BRAM_A (
        .clk              (input_domain_clk),
        .write            (wea_a),
        .addr             (write_address),
        .din              (write_data),
        .out              (data_a)
    );

    BRAM #(
        .NUM_ELEMENTOS    (NUM_ELEMENTOS),
        .SIZE             (10),
        .NBITS            (10)
    ) BRAM_B (
        .clk              (input_domain_clk),
        .write            (wea_b),
        .addr             (write_address),
        .din              (write_data),
        .out              (data_b)
    );

endmodule