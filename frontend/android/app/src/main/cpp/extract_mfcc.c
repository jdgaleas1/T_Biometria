#include "libmfcc.h"
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

// Simulación sencilla para generar un vector de 13 MFCC
double* extract_mfcc_from_array(const double* spectrum, int length, int sample_rate) {
    int num_coeffs = 13;
    double* mfccs = (double*) malloc(sizeof(double) * num_coeffs);

    for (int m = 0; m < num_coeffs; m++) {
        mfccs[m] = GetCoefficient((double*)spectrum, sample_rate, 48, length, m);
    }

    return mfccs;
}

#ifdef __cplusplus
}
#endif
