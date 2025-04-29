/*Reducción de ruido*/
#include "denoise.h"
#include <vector>
#include <algorithm> // Para std::clamp
#include <omp.h>     // Para procesamiento en paralelo

std::vector<short> applyDenoise(const std::vector<short>& pcmData, int numChannels)
{
    const int windowSize = 5; // Tamaño de ventana de media móvil (ajustable)
    const int totalSamples = static_cast<int>(pcmData.size());
    std::vector<short> result(totalSamples, 0);

#pragma omp parallel for
    for (int i = 0; i < totalSamples; ++i)
    {
        int sum = 0;
        int count = 0;

        // Para cada muestra, hacemos la media en una ventana alrededor
        for (int j = -windowSize; j <= windowSize; ++j)
        {
            int idx = i + j;
            if (idx >= 0 && idx < totalSamples)
            {
                sum += pcmData[idx];
                count++;
            }
        }

        result[i] = static_cast<short>(sum / count);
    }

    return result;
}
/*
*  ¿Qué hace este filtro?
Para cada muestra del audio:

Mira las muestras vecinas (ventana de 5 a la izquierda y 5 a la derecha).

Calcula el promedio de esas muestras.

Reemplaza la muestra actual por ese promedio.

 Elimina ruido aleatorio y suaviza la señal, dejando solo la voz real.

Todo el bucle principal corre en paralelo usando OpenMP (#pragma omp parallel for).


*/