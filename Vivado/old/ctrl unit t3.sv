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


module pipelineCtrlUnit #(parameter NUM_ELEMENTOS = 1024)(
    input logic clk,//reloj 100Mhz
    input logic reset,//reset sincronizado
    input logic command_ready,//señal para cambiar de comando de IDLE a una operacion
    input logic write_done,//señal que indica que se termino toda la operacion de escritura
    input logic tx_sent,//señal de que se envio un dato completo
    input logic [7:0] command,//dir memoria 0A, 1B, dot prod, man dist, euc dist, avg, sum, read y write. En ese orden
    output logic begin_transmission,//señal para iniciar la transmision cuando hay un resultado listo
    output logic begin_write,//señal para empezar la escritura
    output logic read_mem_sel,//señal para seleccionar qué memoria leer
    output logic shift_mem,//señal para shiftear memoria PISO
    output logic load_mem,//señal para cargar memorias
    output logic [5:0] enables//arreglo de enables para las distintas operaciones. Mismo orden que command
    );
    
    logic [7:0]operation;//operacion a realizar memoria activa, WRITE,READ, SUM, AVG,EUCDIST
    //MANDIST Y DOTPROD
    enum logic [8:0] {IDLE, WRITE, READ, SUM, AVG, MAN_DIST, STORE, SHIFT_MEM, SENDING} STATE, NEXT_STATE;
    logic [9:0]counter ,counter_next;
    logic [10:0]t;//timer para operaciones de estado
    
    // Retener operation hasta el siguiente idle
    always_ff @(posedge clk)begin
        if(reset) begin
            STATE <= IDLE;
            operation <= 8'h0;
        end
        else begin
            STATE <= NEXT_STATE;
            counter <= counter_next;
            if(STATE == IDLE & command_ready) operation <= command;
        end
    end
    
    // Timer
    always_ff @(posedge clk) begin
        if(reset) t <= 11'b0;
        else if (STATE != NEXT_STATE) t <= 11'b0;
        else t <= t + 1;
    end
    
    // FSM con tiempo
    always_comb begin
        NEXT_STATE = STATE;
        begin_write = 1'b0;
        counter_next = counter;
        begin_transmission = 1'b0;
        enables = 6'b0;
        load_mem = 1'b0;
        shift_mem = 1'b0;
        read_mem_sel = 0;

        case(STATE)
            IDLE: begin
                counter_next = 11'b0; // Contador para coordinar nro de elementos enviados
                if(command_ready)begin
                    if(command[0]) NEXT_STATE = WRITE;
                    else if(command[1]) NEXT_STATE = READ;
                    else if(command[2]) NEXT_STATE = SUM;
                    else if(command[3]) NEXT_STATE = AVG;
                    //else if(command[4]) NEXT_STATE = EUC_DIST;
                    else if(command[4]) NEXT_STATE = IDLE; // las ops no implementadas se ignoran
                    else if(command[5]) NEXT_STATE = MAN_DIST;
                    //else if(command[6]) NEXT_STATE = DOT_PROD;
                    else if(command[6]) NEXT_STATE = IDLE;
                end
            end
            
            WRITE: begin // Mantenerse en estado de escritura hasta recibir señal de listo
                begin_write = 1'b1;
                if(write_done) 
                    NEXT_STATE = IDLE;
            end
            
            READ: begin
                enables = 6'b000001;
                read_mem_sel = ~operation[7];
                //if(t >= 3) begin // ni idea de dónde sale ese 3 pero debe ser pa contar ciclos
                if(t >= 1) begin // ni idea de dónde sale ese 3 pero debe ser pa contar ciclos
                    NEXT_STATE = STORE;
                    //begin_transmission = 1'b1;
                end
            end
            
            SUM: begin
                enables = 6'b000010;
                if(t >= 1) begin // SUM toma 1 ciclo en teoría
                    NEXT_STATE = STORE;
                    //begin_transmission = 1'b1;
                end
            end
            
            AVG: begin
                enables = 6'b000100;
                if(t >= 2) begin
                    NEXT_STATE = STORE; // AVG toma 2 ciclos en teoría: 1 en suma y 1 en shift
                    //begin_transmission = 1'b1;
                end
            end
            
            
            MAN_DIST: begin
                enables = 6'b010000;
                //if(t >= 3) process_ctrl = 1'b1; // Ctrl acumula resultado de todas las restas
                                                // En paralelo no debería necesitarlo
                //if(t >= $clog2(NUM_ELEMENTOS) + 1) begin // Latencia de adder tree + resta
                if(t >= $clog2(NUM_ELEMENTOS) ) begin // Latencia de adder tree + resta
                    NEXT_STATE = STORE;
                end
            end
            


            STORE: begin
                // Cargar resultados en memorias
                load_mem = 1'b1; 
                enables = operation[6:1];
                read_mem_sel = ~operation[7];
                NEXT_STATE = SENDING;
            end

            SENDING: begin
                begin_transmission = 1'b1;
                //counter_next = counter + 1;
                enables = operation[6:1];
                // Si la operación es ManDist, volver a IDLE. Si no, shiftear!
                if (operation[5]) begin
                    if (tx_sent) NEXT_STATE = IDLE;
                end else begin
                    if (tx_sent) NEXT_STATE = SHIFT_MEM;
                end
            end

            SHIFT_MEM: begin
                shift_mem = 1'b1;
                counter_next = counter + 1;
                enables = operation[6:1];
                //if(operation[1] || operation[2] || operation[3]) begin // vectores
                if(counter >= NUM_ELEMENTOS - 1) 
                    NEXT_STATE = IDLE;
                else
                    NEXT_STATE = SENDING;
                //end
                
            end
            
            default: NEXT_STATE = IDLE;
        endcase
    end
endmodule