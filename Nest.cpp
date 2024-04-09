#include <iostream>
#include "Nest.hpp"

int main() {
    // Define parameters
    params p;
    // Initialize nest ID
    unsigned int nestID = 1;

    // Create a new nest with initial mean cues
    Nest initialNest(nestID, p);
    std::cout << "Initial Nest ID: " << initialNest.nest_id << std::endl;
    std::cout << "Initial Nest Mean Cues: ";
    for (auto cue : initialNest.NestMean) {
        std::cout << cue << " ";
    }
    std::cout << std::endl;

    // Print individual cues in the initial nest
    std::cout << "Individual Cues in Initial Nest:" << std::endl;
    for (const auto& worker : initialNest.NestWorkers) {
        std::cout << "Individual ID: " << worker.nest_id << worker.ind_id << " Cues: ";
        for (auto cue : worker.IndiCues) {
            std::cout << cue << " ";
        }
        std::cout << std::endl;
    }

    // Simulate reproduction and create a new nest with mutated mean cues
    CuesArray prevNestMean = initialNest.NestMean;
    Nest reproducedNest(nestID + 1, p, prevNestMean);
    std::cout << "Reproduced Nest ID: " << reproducedNest.nest_id << std::endl;
    std::cout << "Reproduced Nest Mean Cues: ";
    for (auto cue : reproducedNest.NestMean) {
        std::cout << cue << " ";
    }
    std::cout << std::endl;

    // Print individual cues in the reproduced nest
    std::cout << "Individual Cues in Reproduced Nest:" << std::endl;
    for (const auto& worker : reproducedNest.NestWorkers) {
        std::cout << "Individual ID: " << worker.nest_id << worker.ind_id << " Cues: ";
        for (auto cue : worker.IndiCues) {
            std::cout << cue << " ";
        }
        std::cout << std::endl;
    }

    return 0;
}
