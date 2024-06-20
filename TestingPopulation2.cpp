#include <iostream>
#include "Population.hpp"

void printPopulationDetails(const Population& pop) {
    std::cout << "> Storer IDs: ";
    printVector(pop.storer_nest_id);

    std::cout << "> Storer Sto: ";
    printVector(pop.storer_stocks);    

    // Print alive nests in nests vector
    std::cout << "> Nests Vect: ";
    std::cout << "[ ";
    for (const auto& nest : pop.nests) {
        std::cout << nest.nest_id << " ";
    }
    std::cout << "]" << std::endl;
}

int main() {
    // Create a parameter struct
    params par;
    // Initialize parameters with some default values
    par.iNumColonies = 10;  // Number of colonies
    par.dInitFoodStock = 100; // Initial food stock
    par.iInitNestStock = 50; // Initial nest stock
    // You can set other parameters as needed

    // Create a population
    Population pop(par);
    
    // Initialize the population
    pop.initialise_pop();

    // Modify the stock values to be 1, 2, 3, and so on
    for (size_t i = 0; i < pop.nests.size(); ++i) {
        pop.nests[i].NestStock = pow(8, i);
    }

    // Call the update_storer function
    pop.update_storer();

    // Print storer_stocks and storer_nest_id to confirm
    std::cout << "INITIAL POPULATION: " << std::endl;
    printPopulationDetails(pop);

    // 1) Test the kill nest function
    unsigned int nestToKill = 3; // For example, kill nest with ID 3
    pop.kill_nest(nestToKill);

    // Print storer_stocks and storer_nest_id to confirm
    std::cout << "\nAFTER KILLING NEST " << nestToKill << ":" << std::endl;
    printPopulationDetails(pop);

    // 2) Test the reproduce nest function
    pop.reproduce_nest();

    // Print storer_stocks and storer_nest_id to confirm reproduction
    std::cout << "\nAFTER REPRODUCTION" << std::endl;
    printPopulationDetails(pop);

    gtime = 1001.0;
    // Test population regeneration of food
    pop.regenerate_food();
    pop.nests[0].metabolic_cost(par);
    
    // 2) Test the mass_kill function
    pop.mass_kill();
    

    // Print storer_stocks and storer_nest_id to confirm reproduction
    std::cout << "\nAFTER MASS KILL" << std::endl;
    printPopulationDetails(pop);

    // 2) Test the mass_reproduce function
    pop.mass_reproduce();

    // Print storer_stocks and storer_nest_id to confirm reproduction
    std::cout << "\nAFTER MASS REPRODUCE" << std::endl;
    printPopulationDetails(pop);

    // 2) Test the mass_kill function
    gtime = 2001.0;
    pop.mass_kill();

    // Print storer_stocks and storer_nest_id to confirm reproduction
    std::cout << "\nAFTER SECOND MASS KILL" << std::endl;
    printPopulationDetails(pop);

    return 0;
}
