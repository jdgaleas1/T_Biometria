#include "mfcc.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <string.h>

// Simplified WAV reader → solo para WAV PCM16 mono
// Esta función lee el PCM y devuelve un array de doubles
static double* read_wav_file(const char* filePath, int* numSamples) {
    FILE* file = fopen(filePath, "rb");
    if (!file) {
        printf("Error opening WAV file: %s\n", filePath);
        *numSamples = 0;
        return NULL;
    }

    // Skip WAV header (44 bytes)
    fseek(file, 44, SEEK_SET);

    // Get file size
    fseek(file, 0, SEEK_END);
    long fileSize = ftell(file);
    long dataSize = fileSize - 44;
    fseek(file, 44, SEEK_SET);

    int16_t* buffer = (int16_t*) malloc(dataSize);
    fread(buffer, 1, dataSize, file);
    fclose(file);

    int numSamplesInt16 = dataSize / 2; // 2 bytes per sample
    double* samples = (double*) malloc(sizeof(double) * numSamplesInt16);

    for (int i = 0; i < numSamplesInt16; i++) {
        samples[i] = (double) buffer[i] / 32768.0; // Normalize to [-1, 1]
    }

    free(buffer);
    *numSamples = numSamplesInt16;
    return samples;
}

// Dummy MFCC calculation → returns N random values
// You can replace this with a real MFCC implementation
double* compute_voice_mfcc(const char* filePath, int* numCoefficients) {
    int numSamples = 0;
    double* samples = read_wav_file(filePath, &numSamples);

    if (!samples || numSamples == 0) {
        *numCoefficients = 0;
        return NULL;
    }

    // For demo → return 128 random MFCCs
    *numCoefficients = 128;
    double* mfcc = (double*) malloc(sizeof(double) * (*numCoefficients));

    for (int i = 0; i < *numCoefficients; i++) {
        mfcc[i] = (double) rand() / RAND_MAX; // Random for now
    }

    //
