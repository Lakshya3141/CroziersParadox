#include <iostream>
#include "Nest.hpp"

void printNestInfo(const Nest& nest) {
    std::cout << "Nest ID: " << nest.nest_id << "\n";
    std::cout << "Nest Mean Cues: ";
    for (const auto& cue : nest.NestMean) {
        std::cout << cue << " ";
    }
    std::cout << std::endl;
    // std::cout << "\nNest Neutral Gene: " << nest.NestNeutralGene << "\n";
    // std::cout << "Total Abundance: " << nest.TotalAbundance << "\n";
    // std::cout << "Nest Stock: " << nest.NestStock << "\n";
    // std::cout << "Tolerance Intercept: " << nest.TolIntercept << "\n";
    // std::cout << "Tolerance Slope: " << nest.TolSlope << "\n\n";
}

// Function to choose a random intruder from a nest and check if it intrudes other nests
void testIntruder(const Nest& nest, const std::vector<Nest>& allNests, const params& parameters) {
    // Choose a random individual from the nest
    size_t randomIndex = uni_int(0, nest.NestWorkers.size());
    const Individual& intruder = nest.NestWorkers[randomIndex];

    // Check if the intruder can enter other nests
    for (const auto& otherNest : allNests) {
        if (otherNest.nest_id != nest.nest_id) {
            bool canIntrude = otherNest.check_Intruder(parameters, intruder.IndiCues);
            std::cout << "Intruder from Nest " << nest.nest_id << " ";
            if (canIntrude)
                std::cout << "can intrude Nest " << otherNest.nest_id << "\n";
            else
                std::cout << "cannot intrude Nest " << otherNest.nest_id << "\n";
        }
    }
}

// Function to choose a random resident from a nest and check if it returns successfully
void testResident(const Nest& nest, const std::vector<Nest>& allNests, const params& parameters) {
    // Choose a random individual from the nest
    size_t randomIndex = uni_int(0, nest.NestWorkers.size());
    const Individual& resident = nest.NestWorkers[randomIndex];

    // Check if the resident can return to other nests
    for (const auto& otherNest : allNests) {
        if (otherNest.nest_id == nest.nest_id) {
            bool canReturn = otherNest.check_Resident(parameters, resident);
            std::cout << "Resident from Nest " << nest.nest_id << " ";
            if (canReturn)
                std::cout << "can return to Nest " << otherNest.nest_id << "\n";
            else
                std::cout << "cannot return to Nest " << otherNest.nest_id << "\n";
        }
    }
}

int main() {
    // Parameters
    params parameters;

    // Create two nests using the default constructor
    Nest nest1(1, parameters);
    Nest nest2(2, parameters);

    // Create daughter nests from each of the existing nests
    Nest daughterNest1(3, parameters, nest1);
    Nest daughterNest2(4, parameters, nest2);

    // Vector to store all nests
    std::vector<Nest> allNests = {nest1, nest2, daughterNest1, daughterNest2};

    // Print information about the nests
    std::cout << "Nest 1:\n";
    printNestInfo(nest1);

    std::cout << "Nest 2:\n";
    printNestInfo(nest2);

    // Print detailed information about the daughter nests
    std::cout << "Daughter Nest 1:\n";
    printNestInfo(daughterNest1);

    std::cout << "Daughter Nest 2:\n";
    printNestInfo(daughterNest2);

    // Test the findIndexByID function for each nest
    std::cout << "Testing findIndexByID function:\n";
    size_t index1 = nest1.findIndexById(1);
    if (index1 != -1)
        std::cout << "Found individual with ID 1 in nest 1 at index: " << index1 << "\n";
    else
        std::cout << "Individual with ID 1 not found in nest 1\n";

    size_t index2 = nest2.findIndexById(3);
    if (index2 != -1)
        std::cout << "Found individual with ID 3 in nest 2 at index: " << index2 << "\n";
    else
        std::cout << "Individual with ID 3 not found in nest 2\n";

    // Test intruder check for each nest
    std::cout << "\nTesting intruder check:\n";
    for (const auto& nest : allNests) {
        testIntruder(nest, allNests, parameters);
    }

    // Test resident check for each nest
    std::cout << "\nTesting resident check:\n";
    for (const auto& nest : allNests) {
        testResident(nest, allNests, parameters);
    }

    return 0;
}
