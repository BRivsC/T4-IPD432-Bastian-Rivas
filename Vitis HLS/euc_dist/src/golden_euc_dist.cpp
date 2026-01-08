#include "golden_euc_dist.h"
// Cálculo en software de la distancia euclideana

//void euc_dist (T A[N_ELEM], T B[N_ELEM], Tout *euc_dist_result)
void golden_euc_dist (data_t_in A[N_ELEM], data_t_in B[N_ELEM], float gold_euc_dist_result[1]){
	gold_euc_dist_result[0] = 0;
	for (int i = 0; i < N_ELEM; i++)
	{
		gold_euc_dist_result[0] = gold_euc_dist_result[0] + (A[i]-B[i])*(A[i]-B[i]);
	}
	gold_euc_dist_result[0] = std::sqrt(gold_euc_dist_result[0]);
	return;
}