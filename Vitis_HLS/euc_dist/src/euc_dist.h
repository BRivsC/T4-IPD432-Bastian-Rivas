//#include <cmath>
#include <hls_math.h>  
/* Se incluyue para el uso de la funcion hls::sqrt 
                        * que disminuye la latencia respecto a sdt::sqrt,
                        * con el costo de tener un mayor error.
                        */

#import <cstdint>	/* Se usa para tener acceso al tipo uint8_t y uint32_t
 	 	 	 	 	 */
#include "ap_int.h"
#define N_ELEM 1024 // largo en palabras de vectores a operar
//#define N_ELEM 8 // largo en palabras de vectores a operar
#define BITSIZE 10 // Ancho de bits

//typedef uint8_t T; // Tipo de variable para Vectores entrantes
typedef ap_int<BITSIZE> data_t_in;

typedef ap_uint<30> uint30_t;  // Tipo variable intermedia. Acá es pq se usan 30 bits pa representar 1023*1023*1024 (el máx. de euc dist antes de sqrt)
//typedef uint32_t Tout;  // Tipo variable resultante
typedef uint32_t data_t_out;  // Tipo variable resultado


//void euc_dist (T A[N_ELEM], T B[N_ELEM], Tout *C);
void euc_dist (data_t_in A[N_ELEM], data_t_in B[N_ELEM], data_t_out *euc_dist_result);
