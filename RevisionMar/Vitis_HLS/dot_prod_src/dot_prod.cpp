#include "dot_prod.h"
// Changelog:
//.- Agregado 'dim=1' en los pragmas
//.- Removida la parte del dummy read
//.- Diferenciado tipo de variables de resultado intermedio y resultado final
//.- Cambiada la entrada de tipo "ap_int" a "ap_uint"

// Función para calcular el producto punto entre dos vectores
void dot_prod(data_t_in A[N_ELEM], data_t_in B[N_ELEM], data_t_out *dot_prod_result) {
    #pragma HLS ARRAY_RESHAPE variable=A type=cyclic factor=128 dim = 1
    #pragma HLS ARRAY_RESHAPE variable=B type=cyclic factor=128 dim = 1


    // Variable para acumular el resultado 
    // Resultado intermedio de 30 bits (1023*1023*1024)
    uint30_t prod_result = 0;


    // Bucle para calcular el producto punto
    dotProdLoop: for (int i = 0; i < N_ELEM; i++) {
        #pragma HLS UNROLL factor=128
        #pragma HLS BIND_OP variable=prod_result op=mul impl=fabric
        prod_result += A[i] * B[i];

    }

    *dot_prod_result = prod_result;
    return;
}


