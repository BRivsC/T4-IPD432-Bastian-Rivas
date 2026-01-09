`timescale 1ns / 1ps


module top_tarea4 #(parameter NUM_ELEMENTOS = 1024)(
    input CLK100MHZ,
    input CPU_RESETN,
    input UART_RX_USB,

    output logic UART_TX_USB,
    //output logic PMOD_UART_RX, PMOD_RX_RDY, PMOD_UART_TX, PMOD_TX_BUSY,
    output logic [6:0] SEG,
    output logic [7:0] AN
    );
    
    logic clk_input;//reloj 100 mhz
    logic clk_process;//reloj 100 mhz
    logic clk_output;//reloj 100 mhz
    logic reset_input;
    logic reset_process;
    logic [7:0]rx_data;//byte recibido de uart
    logic rx_ready;//recepcion de 1 byte de uart terminada
    
    logic tx_start;//bit para iniciar transmision
    logic [7:0]tx_data;//byte de datos a transmitir
    logic tx_busy;//byte que indica que el canal de envio esta ocupado

    logic [5:0]enables;//flags que indican la operacion a realizar
    logic [31:0]resultado;//resultado de la operacin del processing core
    logic begin_write_src, begin_write_dest;
    logic op_done_src, op_done_dest;
    logic write_done_src, write_done_dest;
    logic command_ready_src, command_ready_dest;
    logic [7:0] command;
    logic [9:0] data_a [NUM_ELEMENTOS-1:0];
    logic [9:0] data_b [NUM_ELEMENTOS-1:0];
    logic tx_sent_src, tx_sent_dest;
    logic read_mem_sel;
    logic shift_mem;
    logic load_mem;
    
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
    
    xpm_cdc_single/* #(
    .DEST_SYNC_FF          (PL_DEST_SYNC_FF),
    .REG_OUTPUT            (PL_REG_OUTPUT),
    .RST_USED              (PL_RST_USED),
    .SIM_ASSERT_CHK        (SIM_ASSERT_CHK)
  )*/ 
    single_begin_write (
        .src_clk               (clk_process),
        .src_in                (begin_write_src),
        .dest_clk              (clk_input),
        .dest_out              (begin_write_dest)
    );
    
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
    pulse_begin_transmision (
        .src_clk               (clk_process),
        .src_pulse             (op_done_src),
        .dest_clk              (clk_output),
        .src_rst               (reset_process),
        .dest_rst              (reset_input),
        .dest_pulse            (op_done_dest)
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

    /*old
    sipoInputInterface #(
        .NUM_ELEMENTOS    (NUM_ELEMENTOS)
    ) input_interface (
        .input_domain_clk (clk_input),
        .reset            (reset_input),
        .rx_ready         (rx_ready),
        .begin_write      (begin_write_dest),
        .op_done          (op_done_dest),
        .rx_data          (rx_data),
        .write_done       (write_done_src),
        .command_ready    (command_ready_src),
        .command          (command),
        .data_a           (data_a),
        .data_b           (data_b)
    );
    */

    
    logic [31:0] par_result [NUM_ELEMENTOS-1:0];
    logic [31:0] man_result;

    pipelinedProcessingCore #(
        .NINPUTS(NUM_ELEMENTOS)
    ) processing_core (
        .data_A(data_a),
        .data_B(data_b),
        .enables(enables),
        .clk(clk_process),
        .read_mem_sel(read_mem_sel),
        .par_result(par_result),
        .man_result(man_result)
    );

	pipelineCtrlUnit #(
		.NUM_ELEMENTOS         (NUM_ELEMENTOS)
    ) ctrl_unit (
		.clk                   (clk_process),
		.reset                 (reset_process),
		.command_ready         (command_ready_dest),
		.write_done            (write_done_dest),
		.tx_sent               (tx_sent_dest),
		.command               (command),
		.begin_transmission    (op_done_src),
		.begin_write           (begin_write_src),
		.read_mem_sel          (read_mem_sel),
		.shift_mem             (shift_mem),
		.load_mem              (load_mem),
		.enables               (enables)
	);


    // Memoria de salida
    resultMem #(
        .NINPUTS        (NUM_ELEMENTOS)
    ) result_mem (
        .par_data_in    (par_result),
        .man_data_in    (man_result),
        .enables        (enables),
        .clk            (clk_process),
        //.rst            (reset_process),
        .load_mem       (load_mem),
        .shift_mem      (shift_mem),
        .result_out     (resultado)
    );


    
    outputInterface #(
        .INTER_BYTE_DELAY(1000000),   // ciclos de reloj de espera entre el envio de 2 bytes consecutivos
        .WAIT_FOR_REGISTER_DELAY(100), // tiempo de espera para iniciar la transmision luego de registrar el dato a enviar
        .DISPLAY_DURATION(100_000)  // Duración de cada dígito en el display multiplexado
    )
    output_interface_instance(
        .clk(clk_output),
        .reset(reset_input),
        .begin_transmission(op_done_dest),
        .tx_busy(tx_busy),
        .enables_in(enables),    //  {dot, man, euc, avg, sum, read} desde CtrllUnit
        .result_data(resultado),
    
        .tx_start(tx_start),
        .tx_sent(tx_sent_src),
        .segments(SEG),
        .tx_data(tx_data),
        .AN(AN)
    );

    // Descomentar esto y lo del constraint para usar el analizador lógico externo
    //assign PMOD_UART_RX = rx_data;
    //assign PMOD_UART_TX = tx_data;
    //assign PMOD_RX_RDY = rx_ready;    
    //assign PMOD_TX_BUSY = tx_busy;

endmodule
