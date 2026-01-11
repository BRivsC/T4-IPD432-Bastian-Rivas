`timescale 1ns / 1ps

module ctrlUnit #(parameter NUM_ELEMENTOS = 1024)(
    input logic clk, reset,
    input logic [2:0] op_code_in,   // read: 010, euc: 101, dot: 111 desde commandDecoder
    input logic bram_info_in,       // 0: A, 1: B desde commandDecodere
    input logic op_vld,             // 1 si la operación recibida es válida
    input logic op_done,            // Operación lista
    input logic tx_sent,            // señal de que se envio un dato completo
    

    output logic [2:0] op_code_out,  // Último código de operación registrado
    output logic read_mem_sel,      // señal para seleccionar qué memoria leer
    output logic euc_start,
    output logic dot_start,
    //output logic write_start,
    //output logic read_start,
    output logic begin_tx,          // señal para iniciar la transmision cuando hay un resultado listo
    output logic load_mem,          // señal para cargar memorias
    output logic shift_mem         // señal para shiftear memoria PISO a la salida del proc core
    );
    
    enum logic [8:0] {IDLE, WRITE, READ, EUC, DOT, STORE, SHIFT_MEM, SENDING} STATE, NEXT_STATE;
    logic [10:0]counter ,counter_next;
    logic [2:0] op_reg; // Formato: bram_sel, [2:0] op_code
    logic load_op_reg;  // Actualizar código de operación
    
    // Retener código de operación hasta el siguiente idle
    always_ff @(posedge clk)begin
        if(reset) begin
            STATE <= IDLE;
            op_reg <= 3'h0;
            read_mem_sel <= 1'b0;
            counter <= 0;
            //counter_next <= 0;
        end
        else begin
            STATE <= NEXT_STATE;
            counter <= counter_next;
            if(load_op_reg) begin
                op_reg <= op_code_in;
                read_mem_sel <= bram_info_in;
            end
        end
    end
    assign op_code_out = op_reg[2:0];

    
    // Timer
    /*
    logic [10:0]t;      //timer para operaciones de estado
    always_ff @(posedge clk) begin
        if(reset) t <= 11'b0;
        else if (STATE != NEXT_STATE) t <= 11'b0;
        else t <= t + 1;
    end
    */
    // FSM 
    always_comb begin
        NEXT_STATE = STATE;
        //write_start = 1'b0;
        counter_next = counter;
        begin_tx = 1'b0;
        load_mem = 1'b0;
        shift_mem = 1'b0;
        //read_mem_sel = 0;
        euc_start = 0;
        dot_start = 0;
        load_op_reg = 0;
        //read_start = 0;

        case(STATE)
            IDLE: begin
                counter_next = 11'b0; // Contador para coordinar nro de elementos enviados
                load_op_reg = 1;
                if(op_vld)begin
                    if(op_code_in == 3'b001) NEXT_STATE = WRITE;
                    else if(op_code_in == 3'b010) NEXT_STATE = READ;
                    else if(op_code_in == 3'b101) NEXT_STATE = EUC;
                    else if(op_code_in == 3'b111) NEXT_STATE = DOT;
                    else NEXT_STATE = IDLE;
                end
            end
            
            WRITE: begin // Mantenerse en estado de escritura hasta recibir señal de listo
                //write_start = 1'b1; // esta señal se maneja dentro de la misma inputInterface
                if(op_done) 
                    NEXT_STATE = IDLE;
            end
            
            READ: begin
                //enables = 6'b000001;
                // Instrucción de lectura se gatilla con el op_code registrado
                NEXT_STATE = STORE;
                /*
                if(t >= 1) begin 
                    NEXT_STATE = STORE;
                end
                */
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
                //op_code_out = op_reg[2:0] // quizás me genere un multi driven pin
                //read_mem_sel = ~op_reg[3];
                NEXT_STATE = SENDING;
            end

            SENDING: begin
                begin_tx = 1'b1;
                //op_code_out = op_reg[2:0];
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
                //op_code_out = op_reg[2:0]
                if(counter >= NUM_ELEMENTOS - 1) 
                    NEXT_STATE = IDLE;
                else
                    NEXT_STATE = SENDING;
            end
            
            default: NEXT_STATE = IDLE;
        endcase
    end
endmodule