#pragma once

#ifdef __cplusplus
extern "C" {
#endif

double* compute_voice_mfcc(const char* filePath, int* numCoefficients);

void free_mfcc(double* mfcc);

#ifdef __cplusplus
}
#endif
