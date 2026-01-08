#include "dot_prod.h"

// Función para calcular el producto punto entre dos vectores
void dot_prod(data_t_in A[N_ELEM], data_t_in B[N_ELEM], data_t_out *dot_prod_result) {
    #pragma HLS ARRAY_RESHAPE variable=A type=cyclic factor=128
    #pragma HLS ARRAY_RESHAPE variable=B type=cyclic factor=128
    //#pragma HLS ARRAY_PARTITION variable=A type=cyclic factor=128
    //#pragma HLS ARRAY_PARTITION variable=B type=cyclic factor=128

    // Variable para acumular el resultado del producto punto
    data_t_out prod_result = 0;

    // Bucle para calcular el producto punto
    dotProdLoop: for (int i = 0; i < N_ELEM; i++) {
        #pragma HLS UNROLL factor=128  
        prod_result += A[i] * B[i];
    }

    // Almacenar el resultado en la variable de salida
    *dot_prod_result = prod_result;
    return;
}
