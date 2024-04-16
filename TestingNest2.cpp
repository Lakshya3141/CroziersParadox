#include <iostream>
#include "Nest.hpp"

int main() {
    // Define parameters
    params p;

    std::vector<double> nestmean = {10.0, 30.0, 4.0, 5.0, 6.0}; // Assuming a profile with 5 cues

    // Create a nest
    Nest dumnest(1, p);

    dumnest.NestMean = nestmean;

    Nest nest(2, p, dumnest);

    // Define profiles for testing
    std::vector<double> otherProfile = {1.0, 3.0, 4.0, 50.0, 60.0}; // Assuming a profile with 5 cues

    // Test check_Intruder function
    std::cout << "Test check_Intruder:" << std::endl;
    for (int i = 0; i < 10; i++) {
        std::cout << "Result: " << nest.check_Intruder(p, otherProfile) << std::endl;
    }

    // Test check_Resident function
    std::cout << "\nTest check_Resident:" << std::endl;
    // Select a random worker from the nest
    size_t workerIndex = uni_int(0, nest.NestWorkers.size());
    Individual& selectedWorker = nest.NestWorkers[workerIndex];
    std::cout << "Result: " << nest.check_Resident(p, selectedWorker) << std::endl;

    // // Test get_Tolerance function
    // std::cout << "\nTest get_Tolerance:" << std::endl;
    // double distance = 0.5; // Sample distance
    // std::cout << "Result: " << nest.get_Tolerance(p, distance) << std::endl;

    return 0;
}
