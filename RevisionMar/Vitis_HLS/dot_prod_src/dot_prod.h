#include <cstdint>
#include "ap_int.h"

#define N_ELEM 1024  // Largo de los vectores
#define BITSIZE 10   // Ancho de bits de los vectores

typedef ap_uint<BITSIZE> data_t_in;   // Tipo de datos para los vectores de entrada
typedef ap_uint<30> uint30_t;  // Tipo variable intermedia. Acá es pq se usan 30 bits pa representar 1023*1023*1024


typedef uint32_t data_t_out;      // Tipo de datos para el resultado (puede variar según los valores esperados)

void dot_prod(data_t_in A[N_ELEM], data_t_in B[N_ELEM], data_t_out *dot_prod_result);
