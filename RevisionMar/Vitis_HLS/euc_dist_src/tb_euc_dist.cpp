
#include <iostream>
#include <hls_math.h>  
//#include <math.h>
#include "euc_dist.h"
//#include "euc_dist.cpp"
//#include "golden_euc_dist.cpp"
#include "golden_euc_dist.h"

using namespace std;

void genRandArray(int min, int max, int size, data_t_in *array);
int compare(float* gold, data_t_out* result, int size, double th);

int main (){
	int errors = 0;
	int tests = 100;

	data_t_in A[N_ELEM], B[N_ELEM];
	data_t_out dut_res[1];
	float gold_res[1];

	double diff;
	double th = 0.9; // vamos a aceptar un error bastante alto, el cual se reduce considerablemente con el uso de flotantes en el resultado.
	int min = 0;
	int max = 254;
	cout << "Euc Dist calculation: "<< endl;
	for (int i=0; i<tests; i++){
		genRandArray(min, max, N_ELEM, A);
		genRandArray(min, max, N_ELEM, B);

		golden_euc_dist (A, B, gold_res);
		euc_dist (A, B, dut_res);

		errors += compare(gold_res, dut_res, 1, th);
		cout << "gold_res: " << gold_res[0] << ", dut_res: " << dut_res[0] << endl;
	}
	cout <<"Number of errors: " << errors << endl;
	if (errors){
		return 1;
	}
	return 0;
}


void genRandArray(int min, int max, int size, data_t_in *array){
    for(int i=0; i<size; i++){
        array[i] = rand()%255; // min + static_cast <data_t_in> (rand()) / ( static_cast <data_t_in> (RAND_MAX/(max-min)));
    }
}

int compare(float* gold, data_t_out* result, int size, double th){
        int errors = 0;
        double dif = 0;
        for (int i=0; i<size; i++){
                dif = fabs((double)gold[i] - (double)result[i]);
                // a comparison with NaN will always be false
                if (!(dif <= (double)th)){
                        errors++;
                }
        }
        return errors;
}