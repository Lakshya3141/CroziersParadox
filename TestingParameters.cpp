#include <iostream>
#include "Parameters.hpp"

int main() {
    // Test params structure
    params p;

    // Print default values
    std::cout << "Default values:" << std::endl;
    std::cout << "Model Choice: " << p.sModelChoice << " (Value: " << p.iModelChoice << ")" << std::endl;
    std::cout << std::endl;

    // Test conversion function
    try {
        std::string choice = "desv";
        p.sModelChoice = choice;
        int model = p.convertStringChoicetoInt(choice);
        std::cout << "Converted model choice: " << p.sModelChoice << " (Value: " << p.iModelChoice << ")" << std::endl;
    } catch (const std::runtime_error& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }

    return 0;
}
