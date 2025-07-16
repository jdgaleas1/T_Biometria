#include <cmath>
#include <cstdint>
#include <cstring>

extern "C" void extract_ear_features(uint8_t* imageData, int width, int height, double* output128) {
    for (int i = 0; i < 128; ++i) {
        output128[i] = static_cast<double>((i % 16) + (imageData[i % (width * height)] / 255.0));
    }
}
