#include "dot_prod.h"

// Función para calcular el producto punto entre dos vectores
void dot_prod(data_t_in A[N_ELEM], data_t_in B[N_ELEM], data_t_out *dot_prod_result) {
    #pragma HLS ARRAY_RESHAPE variable=A type=cyclic factor=128
    #pragma HLS ARRAY_RESHAPE variable=B type=cyclic factor=128

    // --------------------------------------------------
    // Dummy read (warm-up de la memoria)
    // --------------------------------------------------
    volatile data_t_in dummyA = A[0];
    volatile data_t_in dummyB = B[0];

    // Variable para acumular el resultado
    data_t_out prod_result = 0;

    // Bucle para calcular el producto punto
    dotProdLoop: for (int i = 0; i < N_ELEM; i++) {
        #pragma HLS UNROLL factor=128
        #pragma HLS BIND_OP variable=prod_result op=mul impl=fabric
        prod_result += A[i] * B[i];
    }

    *dot_prod_result = prod_result;
}



/*#include "dot_prod.h"

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
        #pragma HLS BIND_OP variable=prod_result op=mul impl=fabric
        #pragma HLS UNROLL factor=128  
        prod_result += A[i] * B[i];
    }

    // Almacenar el resultado en la variable de salida
    *dot_prod_result = prod_result;
    return;
}

*/

/*

#include "dot_prod.h"

void dot_prod(data_t_in A[N_ELEM],
              data_t_in B[N_ELEM],
              data_t_out *dot_prod_result){
#pragma HLS ARRAY_RESHAPE variable=A type=cyclic factor=128 dim=1
#pragma HLS ARRAY_RESHAPE variable=B type=cyclic factor=128 dim=1

    data_t_out prod_result = 0;

    data_t_out partial_sum[128];
#pragma HLS ARRAY_PARTITION variable=partial_sum complete

    // Inicialización
    for (int k = 0; k < 128; k++) {
#pragma HLS UNROLL
        partial_sum[k] = 0;
    }

    // Loop por bloques EXPLÍCITO
    for (int blk = 0; blk < 8; blk++) {

        // Loop interno totalmente desenrollado
        for (int i = 0; i < 128; i++) {
        #pragma HLS UNROLL
        #pragma HLS BIND_OP variable=partial_sum op=mul impl=fabric
            int idx = blk * 128 + i;
            partial_sum[i] += A[idx] * B[idx];
        }
    }

    // Reducción final
    for (int k = 0; k < 128; k++) {
#pragma HLS UNROLL
        prod_result += partial_sum[k];
    }

    *dot_prod_result = prod_result;
}
*/