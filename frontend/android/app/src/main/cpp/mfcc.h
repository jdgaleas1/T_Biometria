#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Calcula los MFCCs de un archivo WAV
// Devuelve un array de doubles con los MFCCs concatenados
// El número total de coeficientes se guarda en numCoefficients
double* compute_voice_mfcc(const char* filePath, int* numCoefficients);

// Libera la memoria del array de MFCCs
void free_mfcc(double* mfcc);

#ifdef __cplusplus
}
#endif
