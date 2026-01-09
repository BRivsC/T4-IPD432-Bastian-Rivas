`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 11:28:27 PM
// Design Name: 
// Module Name: pipelineCtrlUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ctrlUnit #(parameter NUM_ELEMENTOS = 1024)(
    input logic clk, reset,
    input logic [7:0] op,           // byte con datos de operación. Formato: bram_sel, XXXX, [2:0] op_code
    input logic op_vld,             // 1 si la operación recibida es válida
    input logic op_done,            // Operación lista
    input logic tx_sent,            // señal de que se envio un dato completo
    //input logic [7:0] command,    // dir memoria 0A, 1B, dot prod, man dist, euc dist, avg, sum, read y write. En ese orden

    output logic [2:0] op_code_out,  // Último código de operación registrado
    output logic read_mem_sel,      // señal para seleccionar qué memoria leer
    output logic euc_start,
    output logic dot_start,
    output logic write_start,
    output logic read_start,
    output logic begin_tx,          // señal para iniciar la transmision cuando hay un resultado listo
    output logic load_mem,          // señal para cargar memorias
    output logic shift_mem,         // señal para shiftear memoria PISO a la salida del proc core
    //output logic [5:0] enables      //arreglo de enables para las distintas operaciones. Mismo orden que command
    );
    
    logic [7:0]operation;//operacion a realizar memoria activa, WRITE,READ, SUM, AVG,EUCDIST
    //MANDIST Y DOTPROD
    enum logic [8:0] {IDLE, WRITE, READ, SUM, AVG, MAN_DIST, STORE, SHIFT_MEM, SENDING} STATE, NEXT_STATE;
    logic [9:0]counter ,counter_next;
    logic [10:0]t;//timer para operaciones de estado
    
    /*
    // OLD: Retener operation hasta el siguiente idle
    always_ff @(posedge clk)begin
        if(reset) begin
            STATE <= IDLE;
            operation <= 8'h0;
        end
        else begin
            STATE <= NEXT_STATE;
            counter <= counter_next;
            if(STATE == IDLE & op_vld) operation <= command;
        end
    end
    */

    logic [3:0] op_reg; // Formato: bram_sel, [2:0] op_code
    logic load_op_reg; // Actualizar código de operación
    // Retener código de operación hasta el siguiente idle
    always_ff @(posedge clk)begin
        if(reset) begin
            STATE <= IDLE;
            op_reg <= 4'h0;
        end
        else begin
            STATE <= NEXT_STATE;
            counter <= counter_next;
            if(load_op_reg) op_reg <= {op[7],op[2:0]};
        end
    end
    assign op_code_out = op_reg[2:0];

    
    // Timer
    always_ff @(posedge clk) begin
        if(reset) t <= 11'b0;
        else if (STATE != NEXT_STATE) t <= 11'b0;
        else t <= t + 1;
    end
    
    // FSM con tiempo
    always_comb begin
        NEXT_STATE = STATE;
        write_start = 1'b0;
        counter_next = counter;
        begin_tx = 1'b0;
        load_mem = 1'b0;
        shift_mem = 1'b0;
        read_mem_sel = 0;
        euc_start = 0;
        dot_start = 0;
        read_start = 0;

        case(STATE)
            IDLE: begin
                counter_next = 11'b0; // Contador para coordinar nro de elementos enviados
                load_op_reg = 1;
                if(op_vld)begin
                    if(op[2:0] == 3'b001) NEXT_STATE = WRITE;
                    else if(op[2:0] == 3'b010) NEXT_STATE = READ;
                    else if(op[2:0] == 3'b101) NEXT_STATE = EUC_DIST;
                    else if(op[2:0] == 3'b111) NEXT_STATE = DOT_PROD;
                    else NEXT_STATE = IDLE;
                end
            end
            
            WRITE: begin // Mantenerse en estado de escritura hasta recibir señal de listo
                write_start = 1'b1;
                if(op_done) 
                    NEXT_STATE = IDLE;
            end
            
            READ: begin
                enables = 6'b000001;
                read_mem_sel = ~op_reg[3];
                if(t >= 1) begin 
                    NEXT_STATE = STORE;
                end
            end
            
            EUC: begin
                euc_start = 1;
                if(op_done) begin 
                    NEXT_STATE = STORE;
                end
            end

            DOT: begin
                dot_start = 1;
                if(op_done) begin 
                    NEXT_STATE = STORE;
                end
            end        


            STORE: begin
                // Cargar resultados en memorias
                load_mem = 1'b1; 
                op_code_out = op_reg[2:0] // quizás me genere un multi driven pin
                read_mem_sel = ~op_reg[3];
                NEXT_STATE = SENDING;
            end

            SENDING: begin
                begin_tx = 1'b1;
                //counter_next = counter + 1;
                enables = operation[6:1];
                // Si la operación es EucDit o DotProd, volver a IDLE. Si es lectura, shiftear!
                if (op_reg[2:0] == 3'b010) begin
                    if (tx_sent) NEXT_STATE = SHIFT_MEM;
                end else begin
                    if (tx_sent) NEXT_STATE = IDLE;
                end
            end

            SHIFT_MEM: begin
                shift_mem = 1'b1;
                counter_next = counter + 1;
                op_code_out = op_reg[2:0]
                if(counter >= NUM_ELEMENTOS - 1) 
                    NEXT_STATE = IDLE;
                else
                    NEXT_STATE = SENDING;
            end
            
            default: NEXT_STATE = IDLE;
        endcase
    end
endmodule