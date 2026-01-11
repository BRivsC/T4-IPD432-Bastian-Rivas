`timescale 1ns / 1ps

module mem_adapter #(
    parameter NUM_ELEMENTOS = 1024,
    parameter ELEM_BITS     = 10,
    parameter PACK          = 128,
    parameter ADDR_BITS     = 3   // log2(1024/128) = 3
)(
    input   logic  clk,
    //input   logic  rst,

    // ----------------------------------------------------------
    // Memorias planas (1024 x 10 bits)
    // ----------------------------------------------------------
    input    logic [ELEM_BITS-1:0]  A_flat [NUM_ELEMENTOS-1:0],
    input    logic [ELEM_BITS-1:0]  B_flat [NUM_ELEMENTOS-1:0],

    // ----------------------------------------------------------
    // Interfaz hacia IP HLS (puerto A)
    // ----------------------------------------------------------
    input   logic                       A_ce0,
    input   logic [ADDR_BITS-1:0]       A_address0,
    output  logic [PACK*ELEM_BITS-1:0]  A_q0,

    // ----------------------------------------------------------
    // Interfaz hacia IP HLS (puerto B)
    // ----------------------------------------------------------
    input  logic                        B_ce0,
    input  logic [ADDR_BITS-1:0]        B_address0,
    output logic [PACK*ELEM_BITS-1:0]   B_q0
);

    // ----------------------------------------------------------
    // Empaquetado síncrono (modelo BRAM)
    // ----------------------------------------------------------
    integer i;

    always_ff @(posedge clk) begin
        //if (rst) begin
        //    A_q0 <= '0;
        //    B_q0 <= '0;
        //end else begin

            // -------- Puerto A --------
            if (A_ce0) begin
                for (i = 0; i < PACK; i++) begin
                    A_q0[i*ELEM_BITS +: ELEM_BITS]
                        <= A_flat[(unsigned'(A_address0) * PACK) + i];
                end
            end

            // -------- Puerto B --------
            if (B_ce0) begin
                for (i = 0; i < PACK; i++) begin
                    B_q0[i*ELEM_BITS +: ELEM_BITS]
                        <= B_flat[(unsigned'(B_address0) * PACK) + i];
                end
            end

//            // -------- Puerto A --------
//            if (A_ce0) begin
//                for (i = 0; i < PACK; i++) begin
//                    A_q0[i*ELEM_BITS +: ELEM_BITS]
//                        <= A_flat[A_address0*PACK + i];
//                end
//            end

//            // -------- Puerto B --------
//            if (B_ce0) begin
//                for (i = 0; i < PACK; i++) begin
//                    B_q0[i*ELEM_BITS +: ELEM_BITS]
//                        <= B_flat[B_address0*PACK + i];
//                end
//            end
        //end
    end

endmodule