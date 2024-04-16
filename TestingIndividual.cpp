#include <iostream>
#include "Nest.hpp"

int main() {
    // Define parameters
    params p;
    // Initialize nest ID
    unsigned int indID = 1;
    std::vector<double> dumNestMean = {1, 2, 3, 4, 5};
    std::vector<double> otherProfile = {0, 1, 3, 5, 10};
    Individual dummy(indID, p, dumNestMean);
    
    double gestaltDist = dummy.calculateGestaltDist(dumNestMean, otherProfile);
    std::cout << "Gestalt Distance: " << gestaltDist << std::endl;

    // Test calculateUAbsentDist function
    
    double uAbsentDist = dummy.calculateUAbsentDist(otherProfile);
    std::cout << "UAbsent Distance: " << uAbsentDist << std::endl;
    

    // Test calculateDPresentDist function
    
    double dPresentDist = dummy.calculateDPresentDist(otherProfile);
    std::cout << "DPresent Distance: " << dPresentDist << std::endl;

    return 0;
}
