#include <iostream>
#include <vector>
#include <thread>
#include <chrono> // <--- Añadido para medir tiempo
#include <fstream>
#include "minimp3.h"
#include "minimp3_ex.h"
#include "dr_wav.h"
#include "preprocessing/vad.h"
#include "preprocessing/denoise.h"
#include "preprocessing/normalize.h"
#include "features/mfcc.h"

using namespace std;

// Función para decodificar MP3 a PCM en memoria
void decodeMP3toPCM(const char* mp3File, std::vector<short>& pcmData, int& sampleRate, int& numChannels) {
    mp3dec_t mp3d;
    mp3dec_file_info_t info;
    int load_result;

    mp3dec_init(&mp3d);

    load_result = mp3dec_load(&mp3d, mp3File, &info, nullptr, nullptr);
    if (load_result) {
        cerr << "Error al cargar o decodificar el MP3: " << mp3File << endl;
        return;
    }

    sampleRate = info.hz;
    numChannels = info.channels;
    pcmData.assign(info.buffer, info.buffer + info.samples);

    free(info.buffer);
}

// Función para guardar PCM en WAV
void savePCMtoWAV(const char* wavFile, const std::vector<short>& pcmData, int sampleRate, int numChannels) {
    drwav_data_format format;
    format.container = drwav_container_riff;
    format.format = DR_WAVE_FORMAT_PCM;
    format.channels = numChannels;
    format.sampleRate = sampleRate;
    format.bitsPerSample = 16;

    drwav wav;
    if (!drwav_init_file_write(&wav, wavFile, &format, nullptr)) {
        cerr << "Error al abrir WAV para escritura: " << wavFile << endl;
        return;
    }

    drwav_write_pcm_frames(&wav, pcmData.size() / numChannels, pcmData.data());
    drwav_uninit(&wav);

    cout << "Archivo WAV escrito exitosamente: " << wavFile << endl;
}

int main() {
    using namespace std::chrono; // <--- Para usar duración y steady_clock

    // Inicio de la medición
    auto start = steady_clock::now();


    const char* inputMP3 = "audio.mp3";   // Archivo que debes tener en la raíz
    const char* outputWAV = "audio.wav";  // Archivo WAV de salida

    std::vector<short> pcmData;
    int sampleRate = 0;
    int numChannels = 0;

    // Crear hilo para decodificar MP3
    thread decodeThread(decodeMP3toPCM, inputMP3, ref(pcmData), ref(sampleRate), ref(numChannels));
    decodeThread.join();

    // Crear hilo para guardar WAV
    thread saveThread(savePCMtoWAV, outputWAV, ref(pcmData), sampleRate, numChannels);
    saveThread.join();

    // Aplicar VAD para eliminar silencios - Preprosesamiento priemr etapa
    pcmData = applyVAD(pcmData, sampleRate, numChannels);

    // Aplicar reducción de ruido - Preprosesamiento segunda etapa
    pcmData = applyDenoise(pcmData, numChannels);

    // Aplicar normalización de volumen - Preprosesamiento tercer etapa
    pcmData = applyNormalization(pcmData);

    //Extraccion de caracteristicas MFCC
    std::vector<std::vector<double>> mfccs = extractMFCC(pcmData, sampleRate);

    // (opcional) imprimir número de frames y dimensiones
    std::cout << "Se extrajeron " << mfccs.size() << " vectores MFCC de " << mfccs[0].size() << " coeficientes cada uno." << std::endl;

    // Guardar en CSV
    saveMFCCasCSV(mfccs, "output_mfcc.csv");

    // Guardar en BIN
    saveMFCCasBIN(mfccs, "output_mfcc.bin");

    cout << "Proceso completado exitosamente." << endl;

    // Fin de la medición
    auto end = steady_clock::now();
    auto duration = duration_cast<milliseconds>(end - start);
    cout << "Tiempo total de ejecución: " << duration.count() << " ms" << endl;

    return 0;
}
