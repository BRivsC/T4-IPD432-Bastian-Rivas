`timescale 1ns / 1ps
// Módulo de interfaz de salida con memorias, controlador de transmisión, y driver de 7 segmentos

module outputInterface #(
    parameter WAIT_FOR_REGISTER_DELAY = 100, // tiempo de espera para iniciar la transmision luego de registrar el dato a enviar
    parameter DISPLAY_DURATION = 100_000  // Duración de cada dígito en el display multiplexado
)(
    input logic clk, reset, begin_tx, tx_busy,
    input logic [2:0] op_code_in,    //  {read: 010, euc: 101, dot: 111} desde CtrlUnit
    input logic [31:0] result_data_in,
    
    output logic       tx_start,  tx_sent,
    output logic [6:0] segments,
    output logic [7:0] tx_data,
    output logic [7:0] AN
    );

    logic register_result32, send_b0, send_b1, send_b2, send_b3;

    // Renombrado de señales para que la herramienta no conecte un puro cable
    logic [2:0] op_code;
    assign op_code = op_code_in;
    
    logic [31:0] result_data;
    assign result_data = result_data_in;
    
    txCtrl #(
        .WAIT_FOR_REGISTER_DELAY    (WAIT_FOR_REGISTER_DELAY)
    ) u_txCtrl (
        .clk                        (clk),
        .reset                      (reset),
        .begin_tx                   (begin_tx),
        .tx_busy                    (tx_busy),
        .op_code                    (op_code), // {read: 010, euc: 101, dot: 111} desde CtrllUnit
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
        .op_code              (op_code),
        .result_data          (result_data),
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

