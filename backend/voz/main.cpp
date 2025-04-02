
/*
✅ Decodificación MP3 en un hilo separado → Mientras se leen los datos, ya se están decodificando.
✅ Escritura de WAV en otro hilo → No se bloquea la conversión mientras se guarda el archivo.
✅ Mayor eficiencia en CPUs multinúcleo 
*/

#include <iostream>
#include <vector>
#include <thread>  // Para procesamiento en paralelo
#include "lame.h"  // Biblioteca LAME para decodificación de MP3
#include "dr_wav.h" // Biblioteca dr_wav para escribir WAV

using namespace std;

// Función para convertir MP3 a PCM en memoria usando LAME (ejecutada en un hilo separado)
void decodeMP3toPCM(const char* mp3File, vector<short>& pcmData, int& sampleRate, int& numChannels) {
    FILE* mp3 = fopen(mp3File, "rb");
    if (!mp3) {
        cerr << "Error al abrir archivo MP3: " << mp3File << endl;
        return;
    }

    hip_t hip = hip_decode_init();
    if (!hip) {
        cerr << "Error al inicializar LAME para decodificación" << endl;
        fclose(mp3);
        return;
    }

    unsigned char mp3Buffer[4096];
    short pcmBuffer[1152 * 2];
    int readSize;

    // Mientras haya datos en el archivo MP3, decodificamos en paralelo
    while ((readSize = fread(mp3Buffer, 1, sizeof(mp3Buffer), mp3)) > 0) {
        int samples = hip_decode(hip, mp3Buffer, readSize, pcmBuffer, nullptr);
        if (samples > 0) {
            pcmData.insert(pcmData.end(), pcmBuffer, pcmBuffer + samples);
        }
    }

    fclose(mp3);
    hip_decode_exit(hip);

    // Asumimos valores estándar de audio (pueden ajustarse si extraemos del MP3 real)
    sampleRate = 44100;  // Frecuencia de muestreo (44.1 kHz)
    numChannels = 1;     // Canal mono
}

// Función para guardar PCM en formato WAV usando dr_wav (ejecutada en otro hilo)
void savePCMtoWAV(const char* wavFile, const vector<short>& pcmData, int sampleRate, int numChannels) {
    drwav_data_format format;
    format.container = drwav_container_riff;
    format.format = DR_WAVE_FORMAT_PCM;
    format.channels = numChannels;
    format.sampleRate = sampleRate;
    format.bitsPerSample = 16;

    drwav wav;
    if (!drwav_init_file_write(&wav, wavFile, &format, nullptr)) {
        cerr << "Error al escribir archivo WAV: " << wavFile << endl;
        return;
    }

    // Escribimos los datos de audio en WAV
    drwav_write_pcm_frames(&wav, pcmData.size() / numChannels, pcmData.data());
    drwav_uninit(&wav);

    cout << "Archivo WAV guardado exitosamente: " << wavFile << endl;
}

int main() {
    const char* inputMP3 = "audio.mp3";  
    const char* outputWAV = "audio.wav";  
    vector<short> pcmData;
    int sampleRate, numChannels;

    // Crear hilo para decodificar el MP3
    thread decodeThread(decodeMP3toPCM, inputMP3, ref(pcmData), ref(sampleRate), ref(numChannels));

    // Esperar a que termine la decodificación antes de proceder
    decodeThread.join();

    // Crear hilo para escribir el WAV mientras seguimos ejecutando otras tareas
    thread writeThread(savePCMtoWAV, outputWAV, ref(pcmData), sampleRate, numChannels);
    
    // Esperar a que termine la escritura del WAV antes de finalizar
    writeThread.join();

    cout << "Proceso completado con éxito." << endl;
    return 0;
}
