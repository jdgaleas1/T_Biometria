#pragma once

#include <vector>
#include <string> e

std::vector<std::vector<double>> extractMFCC(const std::vector<short>& pcmData, int sampleRate, int numCoefficients = 13);
void saveMFCCasCSV(const std::vector<std::vector<double>>& mfccs, const std::string& filename);
void saveMFCCasBIN(const std::vector<std::vector<double>>& mfccs, const std::string& filename);
