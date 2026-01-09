`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: Universidad Tecnica Federico Santa Maria
// Course: ELO212
// Students: Cristobal Caqueo, Bastian Rivas, Claudio Zanetta
// 
// Create Date: 03/05/2022
// Design Name: guia5_alu
// Module Name: Hex_to_7seg_driver
// Project Name: guia5_alu
// Target Devices: xc7a100tcsg324-1
// Tool Versions: Vivado 2021.1
// Description: Display de numeros hexadecimales en 8 displays de 7 segmentos
// 
// Dependencies: Lab Digitales
// 
// Revision: 1.11 - Parametrizado el contador del driver 7 seg
// Additional Comments: Puede recibir un numero de hasta 32 bits y rellena los no
//                      utilizados con ceros
// 
//////////////////////////////////////////////////////////////////////////////////

//Maximo: 32 bits

module driver_7_seg_en#(parameter N = 32, count_max = 3, clk_divider_count = 200_000)(
    input  logic        clock,
    input  logic        reset,
    input  logic        enable,
    input  logic [N-1:0]BCD_in,     // informacion a mostrar
    output logic [6:0]  segments,   // {CA, CB, CC, CD, CE, CF, CG}
    output logic [7:0]  anodos      // {AN7, AN6, AN5, AN4, AN3, AN2, AN1, AN0}
    );
    // nro anodos=nroBCD/4
    
    // Concatenacion de numeros para rellenar por si es menor a 32 bits (8 segmentos)
    logic [31:0] data; //numero a tratar

    
    
    
    if (N == 32) 
        assign data = BCD_in;    
    else 
        assign data = {'d0,BCD_in};
    

    logic clock_div ;
    
    
    //***Primera parte: Separar digitos del numero, convertir 1 digito a 7seg por la vez***
    
    //Digitos (hex) del numero ingresado:
    logic [3:0]sevenSeg_in; //Cable que conecta Mux con conversor BCD->7Seg
    logic [count_max-1:0]sel; //sel coordina al decodificador y al mux que maneja los digitos
    logic [3:0] BCD_1, BCD_2, BCD_3, BCD_4,
                BCD_5, BCD_6, BCD_7, BCD_8;
    //logic [7:0] anodos;

//Separacion por digito. BCD_n es el digito n
    assign BCD_1 = data[3:0]; 
    assign BCD_2 = data[7:4];
    assign BCD_3 = data[11:8];
    assign BCD_4 = data[15:12];

    assign BCD_5 = data[19:16];
    assign BCD_6 = data[23:20];
    assign BCD_7 = data[27:24];
    assign BCD_8 = data[31:28];    


    
    mux_8_1#(.N(count_max)) mux_8_1(                    //mux para separar digitos
         .A(BCD_1),
         .B(BCD_2),
         .C(BCD_3),
         .D(BCD_4),
         
         .E(BCD_5),
         .F(BCD_6),
         .G(BCD_7),
         .H(BCD_8),
         
         .sel(sel),
         .out(sevenSeg_in)
         );  
    
    logic [6:0] sevenSeg;
    BCD_to_sevenSeg BCD_to_sevenSeg(    //conversor por digitos
        .BCD_in(sevenSeg_in),
        .sevenSeg(sevenSeg)
        );
    
    always_comb begin
        if (enable) begin
            segments = sevenSeg;
        end else begin
            segments = 7'b1111111; //apagar display si no está habilitado
        end
    end
        
    //***Segunda parte: mostrar un numero unico y escoger su display***
    
    nbit_counter#(.N(count_max)) counter_n_bit( //contador que coordina al mux y al decodificador 
         .clk(clock_div),
         .reset(reset),
         .count(sel)
         ); 
        
    deco_binario_3_cold#(.N(count_max)) decoder(        //decodificador que maneja los anodos
        .sel(sel),
        .out(anodos)
        );
        
        
    clock_divider #(
        .COUNTER_MAX(clk_divider_count) 
    ) u_clock_divider(
        .clk_in(clock),
        .reset(reset),
        .clk_out(clock_div)
    );


endmodule

// === Modulos auxiliares === //

//////////////////////////////////////////////////////////////////////////////////
// University: Universidad Tecnica Federico Santa Maria
// Course: ELO212
// Students: Cristobal Caqueo, Bastian Rivas, Claudio Zanetta
// 
// Create Date: 03/05/2022
// Design Name: Guia 4
// Module Name: mux_8_1
// Project Name: mux_multiples_displays
// Target Devices: xc7a100tcsg324-1
// Tool Versions: Vivado 2021.1
// Description: Multiplexor de 8 entradas de 4 bits 
// 
// Dependencies: Lab Digitales
// 
// Revision: 1.02 parametrizao de pana
// Revision 0.01 - File Created
// Additional Comments: Usado para separar digitos hexadecimales de una palabra de 32 bits
// 
//////////////////////////////////////////////////////////////////////////////////
module mux_8_1#(parameter N = 3)(	//8 entradas, 1 salida
    input logic [3:0] A, B, C, D, E, F, G, H, //N entradas de 4b
    input logic [N-1:0] sel, //selector de N-1b
    output logic [3:0]out //salida 4b
    
 );
 
    always_comb begin
        case (sel)
            'd0: out = A;
            'd1: out = B;
            'd2: out = C;
            'd3: out = D;
            'd4: out = E;
            'd5: out = F;
            'd6: out = G;
            'd7: out = H;
        endcase
    end
endmodule




//////////////////////////////////////////////////////////////////////////////////
// University: Universidad Tecnica Federico Santa Maria
// Course: ELO212
// Students: Cristobal Caqueo, Bastian Rivas, Claudio Zanetta
// 
// Create Date: 03/05/2022
// Design Name: Guia 4
// Module Name: BCD_to_sevenSeg
// Project Name: mux_multiples_displays
// Target Devices: xc7a100tcsg324-1
// Tool Versions: Vivado 2021.1
// Description: Conversor de nibbles a numeros legibles en displays de 7 segmentos
// 
// Dependencies: Lab Digitales
// 
// Revision: 0.01
// Revision 0.01 - File Created
// Additional Comments: Módulo conversor BCD a 7seg de la pregunta 3.3 en la guía 2. 
//                      Modificado con 0 como ON para coincidir con la Nexys A7
// 
//////////////////////////////////////////////////////////////////////////////////
module BCD_to_sevenSeg(
    input logic [3:0] BCD_in, //números del 0 al F, 4bits. 
    output logic [6:0] sevenSeg //salida abcdefg según el datasheet de la plaquita, 7bits
    );
    
    always_comb begin
    
        //0:ON, 1:OFF
        case (BCD_in)
            4'd0: sevenSeg = 7'b0000001;
            4'd1: sevenSeg = 7'b1001111;
            4'd2: sevenSeg = 7'b0010010;
            4'd3: sevenSeg = 7'b0000110;
            4'd4: sevenSeg = 7'b1001100;
            4'd5: sevenSeg = 7'b0100100;
            4'd6: sevenSeg = 7'b0100000;
            4'd7: sevenSeg = 7'b0001111;
            4'd8: sevenSeg = 7'b0000000;
            4'd9: sevenSeg = 7'b0000100;
            4'd10:sevenSeg = 7'b0001000; //A
            4'd11:sevenSeg = 7'b1100000; //b
            4'd12:sevenSeg = 7'b0110001; //C
            4'd13:sevenSeg = 7'b1000010; //d
            4'd14:sevenSeg = 7'b0110000; //E
            4'd15:sevenSeg = 7'b0111000; //F
            default: sevenSeg = 7'b1111111; //por defecto apagaría todos 
        endcase
    end
endmodule


//Contador de N bits (por defecto 4)
//Pregunta 3.7 guía 2

module nbit_counter #(parameter N=4)(
     input  logic          clk, reset,
     output logic [N-1:0]  count

    );
    always_ff @(posedge clk) begin //flip flop
    //se activa al pasar por el canto de subida del reloj
        if (reset) //si señal reset es 1...
            count <= 'd0; //contador se reinicia
        else
            count <= count+1; //sino, va sumando en cada canto positivo
    end
endmodule




//////////////////////////////////////////////////////////////////////////////////
// University: Universidad Tecnica Federico Santa Maria
// Course: ELO212
// Students: Cristobal Caqueo, Bastian Rivas, Claudio Zanetta
// 
// Create Date: 03/05/2022
// Design Name: Guia 4
// Module Name: deco_binario_3_cold
// Project Name: mux_multiples_displays
// Target Devices: xc7a100tcsg324-1
// Tool Versions: Vivado 2021.1
// Description: Decodificador de 3 bits, funciona con configuracion One-Cold
// 
// Dependencies: Lab Digitales
// 
// Revision: 0.01
// Revision 0.01 - File Created
// Additional Comments: Adaptado para trabajar con los 8 displays de la actividad 4.1
// 
//////////////////////////////////////////////////////////////////////////////////

module deco_binario_3_cold#(parameter N = 3)(
    input  logic [N-1:0]sel,
    output logic [7:0]out
    );

    always_comb begin

        case (sel)
            'd0: out = 8'b11111110;
            'd1: out = 8'b11111101;
            'd2: out = 8'b11111011;
            'd3: out = 8'b11110111;
            'd4: out = 8'b11101111;
            'd5: out = 8'b11011111;
            'd6: out = 8'b10111111;
            'd7: out = 8'b01111111;
        endcase

    end
    
endmodule


`timescale 1ns / 1ps
//Pregunta 5.2


module clock_divider
#(parameter COUNTER_MAX = 200_000) //nro de cantos de subida hasta invertir clk_out
( input logic clk_in,
  input logic reset,
  output logic clk_out );

  localparam DELAY_WIDTH = $clog2(COUNTER_MAX); //clog define el nro de bits necesarios pa representar el contador
  logic [DELAY_WIDTH-1:0] counter = 'd0; //le epic contador

  always_ff @(posedge clk_in) begin //se pasea por los cantos de reloj
    if (reset == 1'b1) begin //reiniciar si hay reset

        counter <= 'd0;
        clk_out <= 0;
    end else if (counter == COUNTER_MAX-1) begin

        counter <= 'd0;
        clk_out <= ~clk_out; //invierte en vez de subir y bajar cada cierta cantidad de cantos de subida
    end else begin

        counter <= counter + 'd1;
        clk_out <= clk_out;
    end
    end
endmodule