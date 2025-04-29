/*Normalización de volumen*/
#include "normalize.h"
#include <algorithm> // Para std::max, std::abs
#include <omp.h>     // Para procesamiento en paralelo

std::vector<short> applyNormalization(const std::vector<short>& pcmData)
{
    const int totalSamples = static_cast<int>(pcmData.size());
    std::vector<short> result(totalSamples, 0);

    short maxVal = 1;

    // Crear una variable local por hilo
#pragma omp parallel
    {
        short localMax = 1;

#pragma omp for nowait
        for (int i = 0; i < totalSamples; ++i)
        {
            localMax = std::max(localMax, static_cast<short>(std::abs(pcmData[i])));
        }

        // Combinar los resultados en sección crítica
#pragma omp critical
        {
            maxVal = std::max(maxVal, localMax);
        }
    }

    // 2. Calcular el factor de normalización
    double targetAmplitude = 0.9 * 32767; // Queremos normalizar al 90% de la amplitud máxima
    double gain = targetAmplitude / maxVal;

    // 3. Aplicar normalización
#pragma omp parallel for
    for (int i = 0; i < totalSamples; ++i)
    {
        int normalized = static_cast<int>(pcmData[i] * gain);
        normalized = std::clamp(normalized, -32767, 32767);
        result[i] = static_cast<short>(normalized);
    }

    return result;
}

/*¿Qué hace esto?
Primero busca la amplitud máxima real del audio actual.

Luego calcula un factor de ganancia para escalar todo al 90% de 32767 (el valor máximo de un short).

Después multiplica cada muestra por ese factor para normalizar el volumen.

Todo en paralelo usando OpenMP.*/