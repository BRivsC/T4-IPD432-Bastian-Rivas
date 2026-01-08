#include "euc_dist.h"

//void euc_dist (T A[N_ELEM], T B[N_ELEM], Tout *euc_dist_result)
void euc_dist (data_t_in A[N_ELEM], data_t_in B[N_ELEM], data_t_out *euc_dist_result){
	#pragma HLS ARRAY_RESHAPE variable=A type=cyclic factor=128 dim=1 //512  // original: type=cyclic
	#pragma HLS ARRAY_RESHAPE variable=B type=cyclic factor=128 dim=1 //512 
	//#pragma HLS ARRAY_PARTITION variable=A type=cyclic factor=256 dim=1 //512  // original: type=cyclic
	//#pragma HLS ARRAY_PARTITION variable=B type=cyclic factor=256 dim=1 //512 

	//uint26_t square_result=0;
	uint30_t square_result=0;
	
	//#pragma HLS PIPELINE
	squareSum:for(int i=0;i<N_ELEM;i++)	{
	
		#pragma HLS UNROLL factor=128 //512
		square_result+=  (A[i]-B[i])*(A[i]-B[i]);
	}

	*euc_dist_result =  hls::sqrt(square_result);
	//*euc_dist_result = sqrt(square_result);
	return;
}