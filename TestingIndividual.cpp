#include "Individual.hpp"
#include <iostream>

int main() {
    // Define parameters
    params p;

    // Define nest mean and neutral gene
    std::vector<double> nestMean = {0.5, 0.3, 0.8, 0.2, 0.6};
    double nestNeutral = 0.1;

    // Initialize individuals
    std::vector<Individual> individuals;
    for (int i = 0; i < 5; ++i) {
        Individual ind(i, p, nestMean, nestNeutral);
        individuals.push_back(ind);
    }

    // Print information about individuals before mutation
    std::cout << "Individuals before mutation:" << std::endl;
    for (const auto& ind : individuals) {
        std::cout << "ID: " << ind.ind_id << ", Neutral Gene: " << ind.NeutralGene << ", Cues: ";
        for (const auto& cue : ind.IndiCues) {
            std::cout << cue << " ";
        }
        std::cout << std::endl;
    }

    // Test mutate function
    for (auto& ind : individuals) {
        ind.mutate(p);
    }

    // Print information about individuals after mutation
    std::cout << "\nIndividuals after mutation:" << std::endl;
    for (const auto& ind : individuals) {
        std::cout << "ID: " << ind.ind_id << ", Neutral Gene: " << ind.NeutralGene << ", Cues: ";
        for (const auto& cue : ind.IndiCues) {
            std::cout << cue << " ";
        }
        std::cout << std::endl;
    }

    // Test distance functions
    std::vector<double> otherProfile = {0.4, 0.6, 0.7, 0.1, 0.5};
    std::cout << "\nDistance calculations:" << std::endl;
    for (const auto& ind : individuals) {
        double gestaltDist = ind.calculateGestaltDist(nestMean, otherProfile);
        double uAbsentDist = ind.calculateUAbsentDist(otherProfile);
        double dPresentDist = ind.calculateDPresentDist(otherProfile);
        std::cout << "ID: " << ind.ind_id << ", Gestalt Distance: " << gestaltDist
                  << ", U-Absent Distance: " << uAbsentDist
                  << ", D-Present Distance: " << dPresentDist << std::endl;
    }

    return 0;
}
