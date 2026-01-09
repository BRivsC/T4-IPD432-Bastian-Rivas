`timescale 1ns / 1ps

module txCtrl#(	
    parameter INTER_BYTE_DELAY = 1000000,   // ciclos de reloj de espera entre el envio de 2 bytes consecutivos
	parameter WAIT_FOR_REGISTER_DELAY = 100 // tiempo de espera para iniciar la transmision luego de registrar el dato a enviar
)(
    input logic clk, reset, begin_transmission, tx_busy,
    input logic [5:0] enables,  // Formato: {dot, man, euc, avg, sum, read} desde CtrllUnit
    output logic tx_start, tx_sent, register_result32, send_b0, send_b1, send_b2, send_b3

    
    );
    
    //assign enables = command[5:0];
    //logic [31:0]  tx_data32;
    logic [31:0]  hold_state_timer;
    enum logic [10:0] {IDLE, REGISTER_DATAIN32, SEND_BYTE_0, DELAY_BYTE_0, SEND_BYTE_1, DELAY_BYTE_1, SEND_BYTE_2, DELAY_BYTE_2, SEND_BYTE_3, DELAY_BYTE_3, TX_DONE} state, next_state;

    // combo logic of FSM
    always_comb begin
        //default assignments
        next_state = state;
		tx_start = 0;
        tx_sent = 0;
        register_result32 = 0;
		send_b0 = 0;
        send_b1 = 0;
        send_b2 = 0;
        send_b3 = 0;

        case (state)
            IDLE: 	begin
						if(begin_transmission) begin
							next_state=REGISTER_DATAIN32;
						end
					end

			REGISTER_DATAIN32:  begin
                                    register_result32 = 1;
                                    if(hold_state_timer >= WAIT_FOR_REGISTER_DELAY)
                                        next_state = SEND_BYTE_0;
                                    else
                                        next_state = REGISTER_DATAIN32;
			end

            SEND_BYTE_0:	begin
                                send_b0 = 1;
								tx_start = 1'b1;
								next_state = DELAY_BYTE_0;
			end
            
            DELAY_BYTE_0: 	begin // Esperar hasta que se envie el byte menos significativo
								//if(hold_state_timer >= INTER_BYTE_DELAY) begin
                                if (tx_busy == 0) begin
									next_state = SEND_BYTE_1;
                                end else begin
                                    next_state = DELAY_BYTE_0;
                                end
			end

            SEND_BYTE_1: begin
                            send_b1 = 1;
                            tx_start = 1'b1;
                            next_state = DELAY_BYTE_1;
			end

            // Todas las instrucciones envían al menos 2 bytes.
            // Euc, Read, Sum y Avg envían solo 2 bytes
			DELAY_BYTE_1: begin
                            if (tx_busy == 0) begin
                                if(enables[3] || enables[2] || enables[1] || enables[0]) // euc, avg, sum, read
                                    next_state = TX_DONE;
                                else
                                    next_state = SEND_BYTE_2;
                            end 
            end

            SEND_BYTE_2: begin
                            send_b2 = 1;
                            tx_start = 1'b1;
                            next_state = DELAY_BYTE_2;
            end

            DELAY_BYTE_2: begin
                           //if (tx_busy == 0) begin
                           //    if (enables[4]) // man
                           //        next_state = TX_DONE;
                           //    else
                           //        next_state = SEND_BYTE_3;

                           //end
                            if (tx_busy == 0) 
                                next_state = SEND_BYTE_3;
            end

            SEND_BYTE_3: begin
                            send_b3 = 1;
                            tx_start = 1'b1;
                            next_state = DELAY_BYTE_3;
            end

            DELAY_BYTE_3: begin
                            if (tx_busy == 0)
                                next_state = TX_DONE;
                        end

            TX_DONE: begin
                            tx_sent = 1;
                            next_state = IDLE;
            end
            
            default: next_state = IDLE;

        endcase
    end	

    //when clock ticks, update the state
    always_ff @(posedge clk) begin
    	if(reset)
    		state <= IDLE;
    	else
    		state <= next_state;
	end
	
    // Timer to hold states for a certain period
    always_ff @(posedge clk) begin
        if(reset)
            hold_state_timer <= 0;
        else if(state != next_state)
            hold_state_timer <= 0;
        else
            hold_state_timer <= hold_state_timer + 1;
    end


    
endmodule

