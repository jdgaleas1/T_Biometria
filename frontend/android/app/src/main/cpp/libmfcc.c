#include <math.h>
#include <stdlib.h>
#include <stdio.h>

// NOTA: Este es un ejemplo MUY simplificado
// En producción usarías librerías como libmfcc completa
// Aquí solo te doy una función falsa para que puedas probar el flujo

double* compute_voice_mfcc(const char* filePath, int* numCoefficients) {
    // En una implementación real aquí leerías el archivo de audio
    // y calcularías los MFCCs reales (por ejemplo con librosa o libmfcc)

    // Para prueba → devolvemos un vector dummy
    *numCoefficients = 128; // por ejemplo 128 coeficientes

    double* mfcc = (double*) malloc(sizeof(double) * (*numCoefficients));
    for (int i = 0; i < *numCoefficients; i++) {
        mfcc[i] = (double) rand() / RAND_MAX; // Random temporal
    }

    return mfcc;
}

void free_mfcc(double* mfcc) {
    free(mfcc);
}
