#include <iostream>
#include "Population.hpp"

int main() {
    // Define parameters
    params p;

    // Create a population object
    Population population(p);

    // Initialize the population
    population.initialise_pop();

    population.kill_nest(1);
    // Simulate the population
    population.simulate();

    return 0;
}
