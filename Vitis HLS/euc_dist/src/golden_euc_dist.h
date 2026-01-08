//#include <cmath>
#include <hls_math.h>  

#include "ap_int.h"
#define N_ELEM 1024 // largo en palabras de vectores a operar
#define BITSIZE 10 // Ancho de bits

//typedef uint8_t T; // Tipo de variable para Vectores entrantes
typedef ap_int<BITSIZE> data_t_in;

void golden_euc_dist (data_t_in A[N_ELEM], data_t_in B[N_ELEM], float gold_euc_dist_result[1]);