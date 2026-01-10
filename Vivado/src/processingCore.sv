`timescale 1ns / 1ps

module processingCore #(
    parameter NUM_ELEMENTOS = 1024,
    parameter FACTOR = 128
)(
    input logic [9:0] data_A [NUM_ELEMENTOS-1:0],
    input logic [9:0] data_B [NUM_ELEMENTOS-1:0],
    input logic [2:0] op_code_in, // read: 010, euc: 101, dot: 111 
    input logic clk,
    input logic read_mem_sel,
    input logic euc_start,
    input logic dot_start,

    output logic [31:0] par_result [NUM_ELEMENTOS- 1:0], // Vectores resultado en paralelo
    output logic [31:0] single_result, // Resultado de dist euclideana o prod punto
    output logic op_done,
    output logic single_result_valid
    );

    localparam IWIDTH = 10;
    localparam OWIDTH = IWIDTH + $clog2(NUM_ELEMENTOS);
    
    logic [31:0]result_euc;
    logic [31:0]result_dot;
    logic [31:0]result_read [NUM_ELEMENTOS-1:0];


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

    assign par_result = result_read;    // Esta es la única operación paralela




    // Adaptador de memoria para IP HLS
    logic [FACTOR*10-1:0] A_q0;
    logic [FACTOR*10-1:0] B_q0;
    logic [2:0] A_address0, A_address0_euc, A_address0_dot;
    logic [2:0] B_address0, B_address0_euc, B_address0_dot;
    logic A_ce0, A_ce0_euc, A_ce0_dot;
    logic B_ce0, B_ce0_euc, B_ce0_dot;
    

    always_comb begin
        if (op_code_in == 3'b101) begin // EucDist
            A_address0 = A_address0_euc;
            B_address0 = B_address0_euc;
            A_ce0 = A_ce0_euc;
            B_ce0 = B_ce0_euc;
        end else begin // DotProd
            A_address0 = A_address0_dot;
            B_address0 = B_address0_dot;
            A_ce0 = A_ce0_dot;
            B_ce0 = B_ce0_dot;
        end
    end

    mem_adapter #(
        .NUM_ELEMENTOS (NUM_ELEMENTOS),
        .ELEM_BITS     (10),
        .PACK          (FACTOR),
        .ADDR_BITS     (3)
    ) u_mem_adapter (
        .clk           (clk),
        //.rst           (rst),
        .A_flat        (data_A), // Memorias planas (1024 x 10 bits)
        .B_flat        (data_B), // Memorias planas (1024 x 10 bits)
        // Interfaz hacia IP HLS (puerto A)
        .A_ce0         (A_ce0),
        .A_address0    (A_address0),
        .A_q0          (A_q0),
        // Interfaz hacia IP HLS (puerto B)
        .B_ce0         (B_ce0),
        .B_address0    (B_address0),
        .B_q0          (B_q0)
    );


    // Distancia euclideana
    logic [31:0] euc_dist_result;
    logic        euc_done;
    euc_dist_0 EucDist (
      .A_ce0(A_ce0_euc),                                // output wire A_ce0
      .B_ce0(B_ce0_euc),                                // output wire B_ce0
      .euc_dist_result_ap_vld(euc_dist_result_ap_vld),  // output wire euc_dist_result_ap_vld
      .ap_clk(clk),                                     // input wire ap_clk
      .ap_rst(0),                                        // input wire ap_rst
      .ap_done(euc_done),                               // output wire ap_done
      .ap_idle(),                                       // output wire ap_idle
      .ap_ready(),                                      // output wire ap_ready
      .ap_start(euc_start),                             // input wire ap_start
      .A_address0(A_address0_euc),                      // output wire [2 : 0] A_address0
      .A_q0(A_q0),                                      // input wire [1279 : 0] A_q0
      .B_address0(B_address0_euc),                      // output wire [2 : 0] B_address0
      .B_q0(B_q0),                                      // input wire [1279 : 0] B_q0
      .euc_dist_result(euc_dist_result)                 // output wire [31 : 0] euc_dist_result
    );

    // Producto punto
    logic [31:0] dot_prod_result;
    logic        dot_done;
    dot_prod_0 DotProd (
      .A_ce0(A_ce0_dot),                                // output wire A_ce0
      .B_ce0(B_ce0_dot),                                // output wire B_ce0
      .dot_prod_result_ap_vld(dot_prod_result_ap_vld),  // output wire dot_prod_result_ap_vld
      .ap_clk(clk),                                     // input wire ap_clk
      .ap_rst(0),                                       // input wire ap_rst
      .ap_done(dot_done),                               // output wire ap_done
      .ap_idle(),                                       // output wire ap_idle
      .ap_ready(),                                      // output wire ap_ready
      .ap_start(dot_start),                             // input wire ap_start
      .A_address0(A_address0_dot),                      // output wire [2 : 0] A_address0
      .A_q0(A_q0),                                      // input wire [1279 : 0] A_q0
      .B_address0(B_address0_dot),                      // output wire [2 : 0] B_address0
      .B_q0(B_q0),                                      // input wire [1279 : 0] B_q0
      .dot_prod_result(dot_prod_result)                 // output wire [31 : 0] dot_prod_result
    );

    assign op_done = euc_done || dot_done;

    // Resultado single output
    assign single_result_valid = euc_dist_result_ap_vld || dot_prod_result_ap_vld;
    always_comb begin
        if (op_code_in == 3'b101) begin // EucDist
            single_result = euc_dist_result;
        end else begin // DotProd
            single_result = dot_prod_result;
        end
    end
    


endmodule
