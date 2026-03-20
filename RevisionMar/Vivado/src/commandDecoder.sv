`timescale 1ns / 1ps

module commandDecoder(
	input 	logic clk, reset, rx_ready, op_done, //bram_info_in,
	//input 	logic [2:0] op_code_in,
	input 	logic [7:0] rx_data,
	output 	logic bram_sel,
	output 	logic [2:0] cmd_out, // read: 010, euc: 101, dot: 111
    output  logic en_write,
	//output logic [3:0] LED,	// Formato: [bram_sel(1 bit)][op_code(3 bits)]
	output 	logic command_ready
	);
// Nota: op_code_in y bram_info vienen del byte recibido por rx_data
// Formato: [bram_sel(1 bit)][unused(4 bits)][op_code_in(3 bits)]
//logic [2:0] op_code_in;
//assign op_code_in = rx_data[2:0];
//logic bram_info_in;
//assign bram_info_in = rx_data[7];

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
	en_write = 0;
	command_ready = 0;
    cmd_out = 3'b000;
	//LED = 7'b0000000;

	case (CurrentState)
		WAIT: begin
			//LED = 4'b0000;
			if (rx_ready) NextState = DECODE;
			else NextState = WAIT;
		end

		DECODE: begin
			case (rx_data)
				8'b0000_0001: begin // Write2dev A
					cmd_out = 3'b001;
                    //en_write = 1;
					bram_sel = 0; // 0 para A, 1 para B. Este va hacia writeCtrl
					//LED = 4'b0001;
                    command_ready = 1;
				end
				8'b1000_0001: begin // Write2dev B
					cmd_out = 3'b001;
                    //en_write = 1;
					bram_sel = 1; // 0 para A, 1 para B. Este va hacia writeCtrl
					//LED = 4'b1001;
                    command_ready = 1;
				end
				8'b0000_0010: begin // ReadVect A
					cmd_out = 3'b010;
					bram_sel = 0;
					//LED = 4'b0010;
                    command_ready = 1;
				end
				8'b1000_0010: begin // ReadVect B
					cmd_out = 3'b010;
					bram_sel = 1;
					//LED = 4'b1010;
                    command_ready = 1;
				end
				8'b0000_0101: begin // EucDist
                    cmd_out = 3'b101;
                    command_ready = 1;
					//LED = 4'b0101;
				end

				8'b0000_0111: begin // DotProd
                    cmd_out = 3'b111;
                    command_ready = 1;
					//LED = 4'b0111;
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
