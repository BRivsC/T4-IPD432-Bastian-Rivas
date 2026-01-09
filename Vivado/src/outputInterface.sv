`timescale 1ns / 1ps
// Módulo de interfaz de salida con memorias, controlador de transmisión, y driver de 7 segmentos

module outputInterface #(
    parameter INTER_BYTE_DELAY = 1000000,   // ciclos de reloj de espera entre el envio de 2 bytes consecutivos
    parameter WAIT_FOR_REGISTER_DELAY = 100, // tiempo de espera para iniciar la transmision luego de registrar el dato a enviar
    parameter DISPLAY_DURATION = 100_000  // Duración de cada dígito en el display multiplexado
)(
    input logic clk, reset, begin_transmission, tx_busy,
    input logic [5:0] enables_in,    //  {dot, man, euc, avg, sum, read} desde CtrllUnit
    input logic [31:0] result_data,
    
    output logic       tx_start,  tx_sent,
    output logic [6:0] segments,
    output logic [7:0] tx_data,
    output logic [7:0] AN
    );

    logic register_result32, send_b0, send_b1, send_b2, send_b3;

    logic [5:0] enables;
    assign enables = enables_in;
    
    logic [31:0] result_data_in;
    assign result_data_in = result_data;
    
    txCtrl #(
        .INTER_BYTE_DELAY           (INTER_BYTE_DELAY),
        .WAIT_FOR_REGISTER_DELAY    (WAIT_FOR_REGISTER_DELAY)
    ) u_txCtrl (
        .clk                        (clk),
        .reset                      (reset),
        .begin_transmission         (begin_transmission),
        .tx_busy                    (tx_busy),
        .enables                    (enables), // Formato: {dot, man, euc, avg, sum, read} desde CtrllUnit
        .tx_start                   (tx_start),
        .tx_sent                    (tx_sent),
        .register_result32          (register_result32),
        .send_b0                    (send_b0),
        .send_b1                    (send_b1),
        .send_b2                    (send_b2),
        .send_b3                    (send_b3)
    );


    logic [31:0] bcd_data;
    byteHandler u_byteHandler (
        .clk                  (clk),
        .reset                (reset),
        .send_b0              (send_b0),
        .send_b1              (send_b1),
        .send_b2              (send_b2),
        .send_b3              (send_b3),
        .register_result32    (register_result32),
        .enables              (enables_in),
        .result_data          (result_data_in),
        .en_disp              (en_disp),
        .tx_data              (tx_data),
        .bcd_out              (bcd_data)
    );

    

    driver_7_seg_en #(
        .N                    (32),
        .count_max            (3),
        .clk_divider_count    (DISPLAY_DURATION)
    ) u_driver_7_seg_en (
        .clock                (clk),
        .reset                (reset),
        .enable               (en_disp),
        .BCD_in               (bcd_data),
        .segments             (segments),
        .anodos               (AN)// {AN7, AN6, AN5, AN4, AN3, AN2, AN1, AN0}
    );


endmodule

