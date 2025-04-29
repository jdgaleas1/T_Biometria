/*convierten el audio en algo que una IA/SVM puede entender y comparar.*/
#include "mfcc.h"
#include <cmath>
#include <vector>
#include <algorithm>
#include <iostream>
#include <omp.h>
#include <fstream> // Para archivos
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


static double hzToMel(double hz) {
    return 2595.0 * std::log10(1.0 + hz / 700.0);
}

static double melToHz(double mel) {
    return 700.0 * (std::pow(10.0, mel / 2595.0) - 1.0);
}

static std::vector<std::vector<double>> createMelFilterbank(int sampleRate, int numFilters, int fftSize)
{
    std::vector<std::vector<double>> filterbank(numFilters, std::vector<double>(fftSize / 2 + 1, 0.0));

    double lowMel = hzToMel(300.0);
    double highMel = hzToMel(3400.0);

    std::vector<double> melPoints(numFilters + 2);
    for (int i = 0; i < numFilters + 2; ++i) {
        melPoints[i] = lowMel + (highMel - lowMel) * i / (numFilters + 1);
    }

    std::vector<int> bin(melPoints.size());
    for (size_t i = 0; i < melPoints.size(); ++i) {
        bin[i] = static_cast<int>(std::floor((melToHz(melPoints[i]) * (fftSize + 1)) / sampleRate));
    }

    for (int i = 0; i < numFilters; ++i) {
        for (int j = bin[i]; j < bin[i + 1]; ++j) {
            filterbank[i][j] = (j - bin[i]) / static_cast<double>(bin[i + 1] - bin[i]);
        }
        for (int j = bin[i + 1]; j < bin[i + 2]; ++j) {
            filterbank[i][j] = (bin[i + 2] - j) / static_cast<double>(bin[i + 2] - bin[i + 1]);
        }
    }

    return filterbank;
}

static std::vector<double> computeFFT(const std::vector<short>& frame)
{
    int N = static_cast<int>(frame.size());
    std::vector<double> spectrum(N / 2 + 1, 0.0);

    // FFT simulada simple (solo para espectro de energía, no precisa)
    for (int k = 0; k <= N / 2; ++k) {
        double sumReal = 0.0;
        double sumImag = 0.0;
        for (int n = 0; n < N; ++n) {
            double angle = 2.0 * M_PI * k * n / N;
            sumReal += frame[n] * std::cos(angle);
            sumImag -= frame[n] * std::sin(angle);
        }
        spectrum[k] = sumReal * sumReal + sumImag * sumImag;
    }

    return spectrum;
}

std::vector<std::vector<double>> extractMFCC(const std::vector<short>& pcmData, int sampleRate, int numCoefficients)
{
    const int frameSizeMs = 25;
    const int frameStrideMs = 10;
    const int frameSize = sampleRate * frameSizeMs / 1000;
    const int frameStride = sampleRate * frameStrideMs / 1000;
    const int numFilters = 26;

    std::vector<std::vector<double>> mfccFeatures;
    auto filterbank = createMelFilterbank(sampleRate, numFilters, frameSize);

    int numFrames = (static_cast<int>(pcmData.size()) - frameSize) / frameStride;

#pragma omp parallel for
    for (int frameIndex = 0; frameIndex < numFrames; ++frameIndex)
    {
        int start = frameIndex * frameStride;
        std::vector<short> frame(pcmData.begin() + start, pcmData.begin() + start + frameSize);

        auto powerSpectrum = computeFFT(frame);

        std::vector<double> filterEnergies(numFilters, 0.0);
        for (int i = 0; i < numFilters; ++i) {
            for (size_t j = 0; j < powerSpectrum.size(); ++j) {
                filterEnergies[i] += powerSpectrum[j] * filterbank[i][j];
            }
            if (filterEnergies[i] < 1.0) filterEnergies[i] = 1.0;
            filterEnergies[i] = std::log(filterEnergies[i]);
        }

        // DCT tipo II
        std::vector<double> mfcc(numCoefficients, 0.0);
        for (int k = 0; k < numCoefficients; ++k) {
            for (int n = 0; n < numFilters; ++n) {
                mfcc[k] += filterEnergies[n] * std::cos(M_PI * k * (n + 0.5) / numFilters);
            }
        }

        // Sección crítica para escribir en el vector compartido
#pragma omp critical
        mfccFeatures.push_back(mfcc);
    }

    return mfccFeatures;
}

void saveMFCCasCSV(const std::vector<std::vector<double>>& mfccs, const std::string& filename)
{
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error al abrir archivo CSV para escritura: " << filename << std::endl;
        return;
    }

    for (const auto& frame : mfccs) {
        for (size_t i = 0; i < frame.size(); ++i) {
            file << frame[i];
            if (i != frame.size() - 1)
                file << ",";
        }
        file << "\n";
    }

    file.close();
    std::cout << "MFCCs guardados exitosamente en CSV: " << filename << std::endl;
}

void saveMFCCasBIN(const std::vector<std::vector<double>>& mfccs, const std::string& filename)
{
    std::ofstream file(filename, std::ios::binary);
    if (!file.is_open()) {
        std::cerr << "Error al abrir archivo BIN para escritura: " << filename << std::endl;
        return;
    }

    int numFrames = static_cast<int>(mfccs.size());
    int numCoeffs = static_cast<int>(mfccs[0].size());

    // Guardar número de frames y coeficientes primero
    file.write(reinterpret_cast<const char*>(&numFrames), sizeof(int));
    file.write(reinterpret_cast<const char*>(&numCoeffs), sizeof(int));

    for (const auto& frame : mfccs) {
        file.write(reinterpret_cast<const char*>(frame.data()), numCoeffs * sizeof(double));
    }

    file.close();
    std::cout << "MFCCs guardados exitosamente en BIN: " << filename << std::endl;
}