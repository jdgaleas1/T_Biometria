#include <math.h>

double compare_ear_features(const double* stored, const double* current, int length) {
    double dot = 0, normStored = 0, normCurrent = 0;

    for (int i = 0; i < length; i++) {
        dot += stored[i] * current[i];
        normStored += stored[i] * stored[i];
        normCurrent += current[i] * current[i];
    }

    double similarity = dot / (sqrt(normStored) * sqrt(normCurrent));
    return similarity;
}
