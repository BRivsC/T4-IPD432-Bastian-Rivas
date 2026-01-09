`timescale 1ns / 1ps

module byteHandler(
    input logic clk, reset, send_b0, send_b1, send_b2, send_b3, register_result32,
    input logic [2:0] op_code,
    input logic [31:0] result_data,
    output logic en_disp,
    output logic [7:0] tx_data,
    output logic [31:0] bcd_out //  se llama bcd pero es hexa

    );
    
    logic [7:0] byte_0, byte_1, byte_2, byte_3;

    // Registros para los 32 bits de datos

    // Byte 0
    always_ff @(posedge clk) begin
		if (reset) begin
			byte_0 <= 0;
		end else if (register_result32) begin
			byte_0 <= result_data[7:0];
		end else begin
			byte_0 <= byte_0;
		end
	end

    // Byte 1
    always_ff @(posedge clk) begin
		if (reset) begin
			byte_1 <= 0;
		end else if (register_result32) begin
			byte_1 <= result_data[15:8];
		end else begin
			byte_1 <= byte_1;
		end
	end

    // Byte 2
    always_ff @(posedge clk) begin
		if (reset) begin
			byte_2 <= 0;
		end else if (register_result32) begin
			byte_2 <= result_data[23:16];
		end else begin
			byte_2 <= byte_2;
		end
	end

    // Byte 3
    always_ff @(posedge clk) begin
		if (reset) begin
			byte_3 <= 0;
		end else if (register_result32) begin
			byte_3 <= result_data[31:24];
		end else begin
			byte_3 <= byte_3;
		end
	end

    always_comb begin
        if (send_b0) begin
            tx_data = byte_0;
        end else if (send_b1) begin
            tx_data = byte_1;
        end else if (send_b2) begin
            tx_data = byte_2;
        end else if (send_b3) begin
            tx_data = byte_3;
        end else begin
            tx_data = 8'b0;
        end
    end

    assign bcd_out = {byte_3, byte_2, byte_1, byte_0};


    // Lógica para activar display. Se pasa por un FF también
    // Activar si se está en euc o dot
    logic en_disp_comb;

    always_ff @(posedge clk) begin
        if (reset) begin
            en_disp_comb <= 0;
        end else begin
            if (op_code == 3'b101 || op_code == 3'b111) begin
                    en_disp_comb <= 1;
                end else begin
                    en_disp_comb <= 0;
                end
        end
    end

    // Lógica para retener estado del display
    always_ff @(posedge clk) begin
        if (reset) begin
            en_disp <= 0;
        end else begin
            if (register_result32) begin
                en_disp <= en_disp_comb;
        end else begin
                en_disp <= en_disp;
            end
        end
    end

    
endmodule

