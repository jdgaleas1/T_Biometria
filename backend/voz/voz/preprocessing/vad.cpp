/*Eliminación de silencios*/ 
#include "vad.h"
#include <cmath>    // Para std::abs
#include <numeric>  // Para std::accumulate

std::vector<short> applyVAD(const std::vector<short>& pcmData, int sampleRate, int numChannels)
{
    const int frameSize = sampleRate / 100; // Tamaño de frame de 10 ms (por ejemplo, si 44100 Hz ? 441 muestras)
    const double energyThreshold = 500.0;   // Umbral de energía para considerar "voz" (ajustable)
    std::vector<short> result;

    int totalSamples = static_cast<int>(pcmData.size());

    for (int i = 0; i < totalSamples; i += frameSize * numChannels)
    {
        double energy = 0.0;
        int frameSamples = std::min(frameSize * numChannels, totalSamples - i);

        // Calcula la energía de este frame
        for (int j = 0; j < frameSamples; ++j)
        {
            energy += std::abs(pcmData[i + j]);
        }
        energy /= frameSamples;

        // Si la energía es suficiente, lo consideramos como "voz" y lo copiamos al resultado
        if (energy > energyThreshold)
        {
            result.insert(result.end(), pcmData.begin() + i, pcmData.begin() + i + frameSamples);
        }
    }

    return result;
}
/*Divide el audio en frames pequeños (por ejemplo, 10ms).

Calcula la energía promedio en cada frame.

Si la energía supera un umbral, se mantiene ? Es "voz".

Si no ? Se descarta ? Es "silencio".*/