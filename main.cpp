#include <iostream>
#include "Individual.hpp"
#include <iomanip> // For std::setprecision
#include <sstream> // For std::ostringstream

int main() {
    // Create an Individual with parameterized constructor
    CuesArray colony_mean;
    // Assume some values for ColonyMean array
    for (int i = 0; i < iNumCues; i++) {
        colony_mean[i] = i * 10.0; // Just for demonstration
    }
    params p; // Assuming default parameter values for now
    gtime = 10.0;
    Individual<1> new_individual(2, p, colony_mean);
    // Print out the values of the newly created individual
    std::cout << "New Individual:" << std::endl;
    std::cout << "ID: " << new_individual.ind_id << std::endl;
    std::cout << "Is Alive: " << new_individual.is_alive << std::endl;
    std::cout << "Birth Time: " << new_individual.t_birth << std::endl;
    std::cout << "Next Time: " << new_individual.t_next << std::endl;
    std::cout << "Cues:" << std::endl;
    for (const auto& cue : new_individual.IndiCues) {
        std::cout << cue << " ";
    }
    std::cout << std::endl << std::endl;
    
    // Print out the values after mutation
    std::cout << "After Mutation:" << std::endl;
    std::cout << "Cues:" << std::endl;
    for (const auto& cue : new_individual.IndiCues) {
        std::cout << cue << " ";
    }
    std::cout << std::endl;

    return 0;
}
