#include "Parameters.hpp"
#include <iostream>

int main() {
    // Testing default values
    params p;
    std::cout << "Default values:" << std::endl;
    std::cout << "dFracKilled: " << p.dFracKilled << std::endl;
    std::cout << "dMetabolicCost: " << p.dMetabolicCost << std::endl;
    std::cout << "dMutationStrength: " << p.dMutationStrength << std::endl;
    std::cout << "dMutBias: " << p.dMutBias << std::endl;
    std::cout << "iNumWorkers: " << p.iNumWorkers << std::endl;
    std::cout << "iNumCues: " << p.iNumCues << std::endl;
    std::cout << "iNumColonies: " << p.iNumColonies << std::endl;
    std::cout << "iInitNestStock: " << p.iInitNestStock << std::endl;
    std::cout << "iInitFoodStock: " << p.iInitFoodStock << std::endl;
    std::cout << "dExpParam: " << p.dExpParam << std::endl;
    std::cout << "sModelChoice: " << p.sModelChoice << std::endl;
    std::cout << "sTolChoice: " << p.sTolChoice << std::endl;

    // Testing manual change of model and tolerance type
    p.sModelChoice = "dpresent";
    p.sTolChoice = "linear";
    p.convertStringModeltoInt(p.sModelChoice);
    p.convertStringTolerancetoInt(p.sTolChoice);
    std::cout << "\nUpdated values after manual change:" << std::endl;
    std::cout << "sModelChoice: " << p.sModelChoice << " (int value: " << p.iModelChoice << ")" << std::endl;
    std::cout << "sTolChoice: " << p.sTolChoice << " (int value: " << p.iTolChoice << ")" << std::endl;

    return 0;
}
