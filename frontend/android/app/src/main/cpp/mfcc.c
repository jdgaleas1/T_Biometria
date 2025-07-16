#include "mfcc.h"
#include "libmfcc.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <string.h>

#define NUM_MFCC 13
#define SAMPLE_RATE 16000
#define NUM_FILTERS 48
#define FRAME_SIZE 512

static double* read_wav_file(const char* filePath, int* numSamples) {
    FILE* file = fopen(filePath, "rb");
    if (!file) {
        printf("❌ Error al abrir archivo WAV: %s\n", filePath);
        *numSamples = 0;
        return NULL;
    }

    fseek(file, 0, SEEK_END);
    long fileSize = ftell(file);
    fseek(file, 44, SEEK_SET);

    long dataSize = fileSize - 44;
    if (dataSize <= 0) {
        printf("❌ Tamaño de datos inválido\n");
        fclose(file);
        *numSamples = 0;
        return NULL;
    }

    int16_t* buffer = (int16_t*) malloc(dataSize);
    fread(buffer, 1, dataSize, file);
    fclose(file);

    int count = dataSize / 2;
    double* samples = (double*) malloc(sizeof(double) * count);

    for (int i = 0; i < count; i++) {
        samples[i] = (double) buffer[i] / 32768.0;
    }

    free(buffer);
    *numSamples = count;
    printf("🔊 Leídos %d samples del WAV\n", count);
    return samples;
}

double* compute_voice_mfcc(const char* filePath, int* numCoefficients) {
    int totalSamples = 0;
    double* audio = read_wav_file(filePath, &totalSamples);

    if (!audio || totalSamples < FRAME_SIZE) {
        printf("⚠️ No hay suficientes datos de audio para MFCC\n");
        *numCoefficients = 0;
        return NULL;
    }

    int numFrames = totalSamples / FRAME_SIZE;
    if (numFrames == 0) numFrames = 1;  // Previene división por cero

    double* result = (double*) calloc(NUM_MFCC, sizeof(double));

    for (int i = 0; i < numFrames; i++) {
        double* frame = audio + (i * FRAME_SIZE);
        for (int m = 0; m < NUM_MFCC; m++) {
            result[m] += GetCoefficient(frame, SAMPLE_RATE, NUM_FILTERS, FRAME_SIZE, m);
        }
    }

    for (int m = 0; m < NUM_MFCC; m++) {
        result[m] /= numFrames;
    }

    *numCoefficients = NUM_MFCC;
    free(audio);

    printf("✅ MFCCs generados correctamente\n");
    return result;
}

void free_mfcc(double* mfcc) {
    if (mfcc) {
        free(mfcc);
    }
}
