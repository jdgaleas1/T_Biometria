#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Calcula los MFCCs de un archivo WAV
double* compute_voice_mfcc(const char* filePath, int* numCoefficients);

// Libera la memoria del array de MFCCs
void free_mfcc(double* mfcc);

#ifdef __cplusplus
}
#endif
