`timescale 1ns / 1ps

module writeCtrl(
    input logic clk, reset, rx_ready, en, bram_sel, count_done,
    input logic [7:0]rx_data,
    output logic write_done, inc, wea_a, wea_b,
    output logic [9:0] dout

    );

    enum logic [8:0] {IDLE, WAIT_LSB, STORE_LSB, WAIT_MSB, STORE_MSB, WRITE_BRAM, INC_ADDR, CHECK_COUNTER, WRITE_DONE} state, next_state;
    always_ff @(posedge clk) begin
        if(reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    logic update_bram_sel, bram_sel_mem, load_lsb, load_msb;
    logic [7:0] data_lsb;
    logic [1:0] data_msb;
    logic block;

    always_comb begin
        next_state = state;

        // Default control signals
        load_lsb = 0;
        load_msb = 0;
        update_bram_sel = 0;
        
        // Default outputs
        dout = 0;
        write_done = 0;
        inc = 0;
        wea_a = 0;  
        wea_b = 0;

        case(state)
            IDLE: begin
                if(en & ~block) begin
                    update_bram_sel = 1;    //  Actualizar apenas se reciba el enable
                    next_state = WAIT_LSB;
                end else
                    next_state = IDLE;
            end 

            WAIT_LSB: begin
                if(rx_ready)
                    next_state = STORE_LSB;
            end

            STORE_LSB: begin
                load_lsb = 1;
                next_state = WAIT_MSB;
            end

            WAIT_MSB: begin
                if(rx_ready)
                    next_state = STORE_MSB;
            end

            STORE_MSB: begin
                load_msb = 1;
                next_state = WRITE_BRAM;
            end

            WRITE_BRAM: begin
                dout = {data_msb, data_lsb};
                wea_a = ~bram_sel_mem; //  Escribir en BRAM A si bram_sel_mem es 0
                wea_b = bram_sel_mem;  //  Escribir en BRAM B si bram_sel_mem es 1
                next_state = INC_ADDR;
            end

            INC_ADDR: begin
                inc = 1;
                next_state = CHECK_COUNTER;
            end

            CHECK_COUNTER: begin
                if (count_done)
                    next_state = WRITE_DONE;
                else
                    next_state = WAIT_LSB;
            end

            WRITE_DONE: begin
                write_done = 1;
                next_state = IDLE;
            end

            default : next_state = IDLE;
        endcase
    end
    
// Recibe los datos de rx_data y los almacena en un registro de 10 bits
// Controlado por las señales load_lsb y load_msb    
    // Registros para los 10 bits de datos
    // 8 menos significativos:
    always_ff @(posedge clk) begin
		if (reset) begin
			data_lsb <= 0;
		end else if (load_lsb) begin
			data_lsb <= rx_data;
		end else begin
			data_lsb <= data_lsb;
		end
	end
    // 2 más significativos
    always_ff @(posedge clk) begin
		if (reset) begin
			data_msb <= 0;
		end else if (load_msb) begin
			data_msb <= rx_data[1:0];
		end else begin
			data_msb <= data_msb;
		end
	end

    
    // Registro para mantener la BRAM a escribir
    
    always_ff @(posedge clk) begin
        if (reset) begin
            bram_sel_mem <= 0;
        end else if (update_bram_sel) begin
            bram_sel_mem <= bram_sel;
        end else begin
            bram_sel_mem <= bram_sel_mem;
        end
    end
    
    always_ff@(posedge clk) begin
        if(reset) block <= 1'b0;
        else if(en) block <= 1'b1;
        else block <= 1'b0;
    end

    
endmodule

