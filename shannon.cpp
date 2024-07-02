#include <iostream>
#include <vector>
#include <cmath>
#include <iomanip> // For setting precision
// Function to calculate Shannon's diversity index
double calculateShannonDiversity(const std::vector<std::vector<double>>& antProfiles) {
    int numAnts = antProfiles.size();
    if (numAnts == 0) return 0.0;

    int numCues = antProfiles[0].size();
    std::vector<double> totalConcentrations(numCues, 0.0);

    // Sum up concentrations for each cue across all ants
    for (const auto& profile : antProfiles) {
        for (int j = 0; j < numCues; ++j) {
            totalConcentrations[j] += profile[j];
        }
    }

    // Calculate the total sum of all cues
    double totalSum = 0.0;
    for (double concentration : totalConcentrations) {
        totalSum += concentration;
    }

    // Calculate the proportions and then the diversity index
    double diversityIndex = 0.0;
    for (double concentration : totalConcentrations) {
        if (concentration > 0) {
            double proportion = concentration / totalSum;
            diversityIndex -= proportion * std::log(proportion);
        }
    }

    return diversityIndex;
}

// Function to calculate Simpson's diversity index
double calculateSimpsonDiversity(const std::vector<std::vector<double>>& antProfiles) {
    int numAnts = antProfiles.size();
    if (numAnts == 0) return 0.0;

    int numCues = antProfiles[0].size();
    std::vector<double> totalConcentrations(numCues, 0.0);

    // Sum up concentrations for each cue across all ants
    for (const auto& profile : antProfiles) {
        for (int j = 0; j < numCues; ++j) {
            totalConcentrations[j] += profile[j];
        }
    }

    // Calculate the total sum of all cues
    double totalSum = 0.0;
    for (double concentration : totalConcentrations) {
        totalSum += concentration;
    }

    // Calculate the proportions and then the diversity index
    double sumProportionsSquared = 0.0;
    for (double concentration : totalConcentrations) {
        if (concentration > 0) {
            double proportion = concentration / totalSum;
            sumProportionsSquared += proportion * proportion;
        }
    }

    double diversityIndex = 1.0 - sumProportionsSquared;
    return diversityIndex;
}

int main() {
    std::vector<std::vector<double>> antProfiles = {
        // {1579, 1890, 69, 393, 770},
        // {1580, 1891, 70, 394, 771},
        // {1578, 1889, 68, 392, 769},
        // {1579, 1890, 69, 393, 770},
        // {1579, 1890, 69, 393, 770}
        {1500, 1500, 1500, 1500, 1500}
    };

    std::cout << std::fixed << std::setprecision(5);

    double shannonIndex = calculateShannonDiversity(antProfiles);
    double simpsonIndex = calculateSimpsonDiversity(antProfiles);

    std::cout << "Shannon's Diversity Index: " << shannonIndex << std::endl;
    std::cout << "Simpson's Diversity Index: " << simpsonIndex << std::endl;

    return 0;
}
