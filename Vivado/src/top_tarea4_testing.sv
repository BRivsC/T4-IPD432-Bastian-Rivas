`timescale 1ns / 1ps


module top_tarea4_testing #(
    parameter NUM_ELEMENTOS = 8,
    parameter FACTOR = 128
)(
    input CLK100MHZ,
    input CPU_RESETN,
    input UART_RX_USB,

    output logic UART_TX_USB,
    //output logic PMOD_UART_RX, PMOD_RX_RDY, PMOD_UART_TX, PMOD_TX_BUSY,
    output logic [6:0] SEG,
    output logic [7:0] AN,
    output logic [1:0] LED
    );

    logic           clk_input;      // reloj 100 mhz
    logic           clk_process;    // reloj 100 mhz
    logic           clk_output;     // reloj 100 mhz
    logic           reset_input;
    logic           reset_process;
    logic [7:0]     rx_data;        // byte recibido de uart
    logic           rx_ready;       // recepcion de 1 byte de uart terminada

    logic           tx_start;       // bit para iniciar transmision
    logic [7:0]     tx_data;        // byte de datos a transmitir
    logic           tx_busy;        // byte que indica que el canal de envio esta ocupado

    logic [2:0]     op_code;        // código de operación desde unidad de control
    logic [2:0]     command;        // comando decodificado, sigue mismo formato que op_code
    logic [31:0]    resultado;      // resultado de la operación del processing core
    //logic           write_start_src, write_start_dest;
    logic           op_done_src, op_done_dest;  //  para comunicación entre dominios de entrada y proce
    logic           write_done_src, write_done_dest;
    logic           command_ready_src, command_ready_dest;

    logic           tx_sent_src, tx_sent_dest;
    logic           read_mem_sel;
    logic           shift_mem;
    logic           load_mem;
    
    PB_Debouncer reset_in(
        .clk(clk_input),
        .rst(1'b0),
        .PB(~CPU_RESETN),
        .PB_pressed_status(reset_input)
    );
    
    PB_Debouncer reset_proc(
        .clk(clk_process),
        .rst(1'b0),
        .PB(~CPU_RESETN),
        .PB_pressed_status(reset_process)
    );
    
    clk_wiz_0 clk_gen
    (
        // Clock out ports
        .input_domain_clk(clk_input),     // output input_domain_clk
        .ctrl_domain_clk(clk_process),     // output ctrl_domain_clk
        .output_domain_clk(clk_output),     // output output_domain_clk
        // Status and control signals
        .reset(1'b0), // input reset
        // Clock in ports
        .clk_in1(CLK100MHZ)      // input clk_in1
    );
    
//    xpm_cdc_single/* #(
//    .DEST_SYNC_FF          (PL_DEST_SYNC_FF),
//    .REG_OUTPUT            (PL_REG_OUTPUT),
//    .RST_USED              (PL_RST_USED),
//    .SIM_ASSERT_CHK        (SIM_ASSERT_CHK)
//  )*/ 
//    single_write_start (
//        .src_clk               (clk_process),
//        .src_in                (write_start_src),
//        .dest_clk              (clk_input),
//        .dest_out              (write_start_dest)
//    );
    
    xpm_cdc_pulse/* #(
    .DEST_SYNC_FF          (PL_DEST_SYNC_FF),
    .REG_OUTPUT            (PL_REG_OUTPUT),
    .RST_USED              (PL_RST_USED),
    .SIM_ASSERT_CHK        (SIM_ASSERT_CHK)
  )*/ 
    pulse_write_done (
        .src_clk               (clk_input),
        .src_pulse             (write_done_src),
        .dest_clk              (clk_process),
        .src_rst               (reset_input),
        .dest_rst              (reset_process),
        .dest_pulse            (write_done_dest)
    );
    
    //command ready tambien
    
    xpm_cdc_pulse/* #(
    .DEST_SYNC_FF          (PL_DEST_SYNC_FF),
    .REG_OUTPUT            (PL_REG_OUTPUT),
    .RST_USED              (PL_RST_USED),
    .SIM_ASSERT_CHK        (SIM_ASSERT_CHK)
  )*/ 
    pulse_tx_sent (
        .src_clk               (clk_output),
        .src_pulse             (tx_sent_src),
        .dest_clk              (clk_process),
        .src_rst               (reset_input),
        .dest_rst              (reset_process),
        .dest_pulse            (tx_sent_dest)
    );
    
    xpm_cdc_pulse/* #(
    .DEST_SYNC_FF          (PL_DEST_SYNC_FF),
    .REG_OUTPUT            (PL_REG_OUTPUT),
    .RST_USED              (PL_RST_USED),
    .SIM_ASSERT_CHK        (SIM_ASSERT_CHK)
  )*/ 
    pulse_op_done (
        .src_clk               (clk_process),
        .src_pulse             (op_done_src),
        .dest_clk              (clk_output),
        .src_rst               (reset_process),
        .dest_rst              (reset_input),
        .dest_pulse            (op_done_dest)
    );

    logic           begin_tx_src, begin_tx_dest;
    xpm_cdc_pulse/* #(
    .DEST_SYNC_FF          (PL_DEST_SYNC_FF),
    .REG_OUTPUT            (PL_REG_OUTPUT),
    .RST_USED              (PL_RST_USED),
    .SIM_ASSERT_CHK        (SIM_ASSERT_CHK)
  )*/ 
    pulse_begin_transmision (
        .src_clk               (clk_process),
        .src_pulse             (begin_tx_src),
        .dest_clk              (clk_output),
        .src_rst               (reset_process),
        .dest_rst              (reset_input),
        .dest_pulse            (begin_tx_dest)
    );
    
    
    xpm_cdc_single /*#(
    .DEST_SYNC_FF          (S_DEST_SYNC_FF),
    .SIM_ASSERT_CHK        (SIM_ASSERT_CHK),
    .SRC_INPUT_REG         (S_SRC_INPUT_REG)
    )*/
    single_command (
        .src_clk               (clk_input),
        .src_in                (command_ready_src),
        .dest_clk              (clk_process),
        .dest_out              (command_ready_dest)
    );
    
    uart_basic #(
		.CLK_FREQUENCY(100_000_000), // reloj base de entrada
		//.CLK_FREQUENCY(50_000_000), // reloj base de entrada
		.BAUD_RATE(115200)
	) uart_basic_inst (
		.clk          (clk_input),
		.reset        (reset_input),
		.rx           (UART_RX_USB),
		.rx_data      (rx_data),
		.rx_ready     (rx_ready),
		.tx           (UART_TX_USB),
		.tx_start     (tx_start),
		.tx_data      (tx_data),
		.tx_busy      (tx_busy) //medible
    );
    assign LED[0] = op_done_dest;
    assign LED[1] = command_ready_dest;
    /*old
    sipoInputInterface #(
        .NUM_ELEMENTOS    (NUM_ELEMENTOS)
    ) input_interface (
        .input_domain_clk (clk_input),
        .reset            (reset_input),
        .rx_ready         (rx_ready),
        .write_start      (write_start_dest),
        .op_done          (op_done_dest),
        .rx_data          (rx_data),
        .write_done       (write_done_src),
        .command_ready    (command_ready_src),
        .command          (command),
        .data_a           (data_a),
        .data_b           (data_b)
    );
    */

    // Input Domain
    logic  [9:0]    data_a [NUM_ELEMENTOS-1:0];
    logic  [9:0]    data_b [NUM_ELEMENTOS-1:0];
    logic [31:0]    par_result [NUM_ELEMENTOS-1:0];
    logic [31:0]    single_result;
    logic           euc_start;
    logic           dot_start;
    logic           bram_sel;

    inputInterface #(
        .NUM_ELEMENTOS    (NUM_ELEMENTOS)
    ) u_inputInterface (
        .input_domain_clk (clk_input),
        .reset            (reset_input),
        .rx_ready         (rx_ready),
        //.write_start      (write_start_dest),
        //.op_done          (op_done_dest || begin_tx_dest),
        .op_done          (op_done_dest || begin_tx_dest),
        .rx_data          (rx_data),
        .write_done       (write_done_src),
        .command_ready    (command_ready_src),
        .bram_sel         (bram_sel),
        .command_out      (command),
        .data_a           (data_a),
        .data_b           (data_b)
    );



    // Processing Domain


    processingCore #(
        .NUM_ELEMENTOS          (NUM_ELEMENTOS),
        .FACTOR                 (FACTOR)
    ) u_processingCore (
        .data_A                 (data_a),
        .data_B                 (data_b),
        .op_code_in             (op_code),
        // read: 010, euc: 101, dot: 111 
        .clk                    (clk_process),
        .read_mem_sel           (read_mem_sel),
        .euc_start              (euc_start),
        .dot_start              (dot_start),
        .par_result             (par_result),
        // Vectores resultado en paralelo
        .single_result          (single_result),
        // Resultado de dist euclideana o prod punto
        .op_done                (op_done_src),      // Output: op lista
        .single_result_valid    ()
    );


    ctrlUnit #(
        .NUM_ELEMENTOS    (NUM_ELEMENTOS)
    ) u_ctrlUnit (
        .clk              (clk_process),
        .reset            (reset_process),
        .op_code_in       (command),            // read: 010, euc: 101, dot: 111 desde commandDecoder
        .bram_info_in     (bram_sel),           // 0: A, 1: B desde commandDecoder
        .op_vld           (command_ready_dest), // 1 si el código de operación recibido es válido
        .op_done          (op_done_src || write_done_dest), // Operación lista. Acá recibe op_done_src porque está en el mismo dominio de clk que el processing core
        .tx_sent          (tx_sent_dest),            // señal de que se envio un dato completo

        .op_code_out      (op_code),            // Último código de operación registrado
        .read_mem_sel     (read_mem_sel),       // señal para seleccionar qué memoria leer
        .euc_start        (euc_start),
        .dot_start        (dot_start),
        //.write_start      (write_start_src),
        .begin_tx         (begin_tx_src),            // señal para iniciar la transmision cuando hay un resultado listo
        .load_mem         (load_mem),            // señal para cargar memorias
        .shift_mem        (shift_mem)            // señal para shiftear memoria PISO a la salida del proc core
    );

    // Memoria de salida
    resultMem #(
        .NINPUTS           (NUM_ELEMENTOS)
    ) u_resultMem (
        .par_data_in       (par_result),
        .single_data_in    (single_result),
        .op_code           (op_code),
        .clk               (clk_process),
        // rst,
        .load_mem          (load_mem),
        .shift_mem         (shift_mem),
        .result_out        (resultado)
    );

    outputInterface #(
        .WAIT_FOR_REGISTER_DELAY    (100),
        .DISPLAY_DURATION           (100_000)
    ) u_outputInterface (
        .clk                        (clk_output),
        .reset                      (reset_input),
        .begin_tx                   (begin_tx_dest),
        .tx_busy                    (tx_busy),
        .op_code_in                 (op_code),          //  {read: 010, euc: 101, dot: 111} desde CtrlUnit
        .result_data_in             (resultado),
        .tx_start                   (tx_start),
        .tx_sent                    (tx_sent_src),
        .segments                   (SEG),
        .tx_data                    (tx_data),
        .AN                         (AN)
    );

    // Descomentar esto y lo del constraint para usar el analizador lógico externo
    //assign PMOD_UART_RX = rx_data;
    //assign PMOD_UART_TX = tx_data;
    //assign PMOD_RX_RDY = rx_ready;    
    //assign PMOD_TX_BUSY = tx_busy;

endmodule
