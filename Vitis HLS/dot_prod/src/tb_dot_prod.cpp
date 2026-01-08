#include <iostream>
#include <math.h>
#include <cstdlib>

#include "dot_prod.h"
#include "golden_dot_prod.h"

using namespace std;

void genRandArray(int min, int max, int size, data_t_in *array);
int compare(data_t_out* gold, data_t_out* result, int size);

int main (){
    int errors = 0;
    int tests  = 100;

    data_t_in  A[N_ELEM], B[N_ELEM];
    data_t_out dut_res[1];
    data_t_out gold_res[1];

    int min = 0;
    int max = 254;

    cout << "Dot Product calculation:" << endl;

    for (int i = 0; i < tests; i++){
        genRandArray(min, max, N_ELEM, A);
        genRandArray(min, max, N_ELEM, B);

        golden_dot_prod(A, B, gold_res);
        dot_prod(A, B, dut_res);

        errors += compare(gold_res, dut_res, 1);

        cout << "gold_res: " << gold_res[0]
             << ", dut_res: " << dut_res[0] << endl;
    }

    cout << "Number of errors: " << errors << endl;

    if (errors){
        return 1;
    }
    return 0;
}

void genRandArray(int min, int max, int size, data_t_in *array){
    for(int i = 0; i < size; i++){
        array[i] = rand() % (max - min + 1) + min;
    }
}

int compare(data_t_out* gold, data_t_out* result, int size){
    int errors = 0;
    for (int i = 0; i < size; i++){
        if (gold[i] != result[i]){
            errors++;
        }
    }
    return errors;
}
