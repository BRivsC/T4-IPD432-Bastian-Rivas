#include "golden_dot_prod.h"

void golden_dot_prod(data_t_in A[N_ELEM],
                        data_t_in B[N_ELEM],
                        data_t_out *result) {
    data_t_out acc = 0;
    for (int i = 0; i < N_ELEM; i++) {
        acc += A[i] * B[i];
    }
    *result = acc;
}
