`timescale 1ns / 1ps

module commandDecoder(
	input 	logic clk, reset, rx_ready, op_done, bram_info_in,
	input 	logic [2:0] op_code_in,
	output 	logic bram_sel,
	output 	logic [2:0] cmd_out, // read: 010, euc: 101, dot: 111
    output  logic en_write,
	output 	logic command_ready
	);
// Nota: op_code_in y bram_info vienen del byte recibido por rx_data
// Formato: [bram_sel(1 bit)][unused(4 bits)][op_code_in(3 bits)]

 //FSM states type:
enum logic [1:0] {WAIT, DECODE} CurrentState, NextState;

 //Statements:--------------------------------

 //FSM state register:
always_ff @(posedge clk)
	if (reset) CurrentState <= WAIT;
	else CurrentState <= NextState;

 //FSM combinational logic:
always_comb begin
	NextState = WAIT;  //Optional default state assigment
	bram_sel = 0;
	command_ready = 0;
    cmd_out = 3'b000;

	case (CurrentState)
		WAIT: begin
			if (rx_ready) NextState = DECODE;
			else NextState = WAIT;
		end

		DECODE: begin
			case (op_code_in)
				3'b001: begin // Write2dev
					cmd_out = 3'b001;
                    en_write = 1;
					bram_sel = bram_info_in; // 0 para A, 1 para B. Este va hacia writeCtrl
                    command_ready = 1;
				end
				3'b010: begin // ReadVect
					cmd_out = 3'b010;
					bram_sel = bram_info_in;
                    command_ready = 1;
				end
				/*
				3'b011: begin // SumVect
					en_sum   = 1; 
				end
				3'b100: begin // AvgVect
					en_avg   = 1; 
				end
				*/
				3'b101: begin // EucDist
                    cmd_out = 3'b101;
                    command_ready = 1;
				//	en_euc   = 1; 
				end
				/*
				3'b110: begin // ManDist
					en_man   = 1; 
				end
				*/
				3'b111: begin // DotProd
                    cmd_out = 3'b111;
                    command_ready = 1;
				//	en_dot   = 1;
				end
				default: begin
					NextState = WAIT;
				end
			endcase

            if (op_done) NextState = WAIT;  
            else NextState = DECODE;
		end

		default: NextState = WAIT;


	endcase

	
end
endmodule
