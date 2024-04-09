//
//  Nest.hpp
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 08/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  defines nest properties, associated functions
//  Also contains output function for individuals during lastOfUs
//

#ifndef Nest_hpp
#define Nest_hpp    

#include "Individual.hpp"
#include <algorithm>

class Nest {
public:
    Nest(const unsigned int nid, const params& p);
    Nest(const unsigned int nid, const params& p, const std::vector<double>& prevNestMean);
    // Nest functions, self explanatory broadly, detailed explanation given above function definition

    // Nest variables
    unsigned int nest_id;
    unsigned int individual_id_counter = 0;
    std::vector<Individual> NestWorkers;
    std::vector<double> NestMean;
    double TotalAbundance;
    int NestStock = iInitNestStock;
    
    // Nest functions
    void calculate_abundance(const params& p);
    size_t findIndexById(const int id);
};

// Constructor for initial nests
Nest::Nest(const unsigned int nid, const params& p) : nest_id(nid) {
    for (int i = 0; i < p.iNumCues; i++) {
        NestMean.push_back(exponential(dExpParam));
    }

    calculate_abundance(p);

    for (int i = 0; i < p.iNumWorkers; i++) {
        Individual newWorker(individual_id_counter, p, NestMean);
        newWorker.nest_id = nid;
        ++individual_id_counter;
        NestWorkers.push_back(newWorker);
    }
} 

// Constructor for reproduced nests
Nest::Nest(const unsigned int nid, const params& p, const std::vector<double>& prevNestMean) : nest_id(nid) {
    for (int i = 0; i < p.iNumCues; i++) {
        NestMean.push_back(normal(prevNestMean[i], p.dMutationStrength));
        if (NestMean[i] < 0.0) NestMean[i] = 0.0;
    }

    calculate_abundance(p);

    for (int i = 0; i < p.iNumWorkers; i++) {
        Individual newWorker(individual_id_counter, p, NestMean);
        newWorker.nest_id = nid;
        ++individual_id_counter;
        NestWorkers.push_back(newWorker);
    }
}

// Calculate total abundance from NestMean
void Nest::calculate_abundance(const params& p) {
    TotalAbundance = 0.0;
    for (int i = 0; i < p.iNumCues; i++) {
        TotalAbundance = TotalAbundance + NestMean[i];
    }
}

// Function to search by indidivual ID in a nest and return index
size_t Nest::findIndexById(const int id) {
    auto it = std::find_if(NestWorkers.begin(), NestWorkers.end(), [id](const Individual& ind) {
        return ind.ind_id == id;
    });
    if (it != NestWorkers.end()) {
        return std::distance(NestWorkers.begin(), it);
    } else {
        // Return some sentinel value  to indicate not found
        return -1;
    }
}

#endif /* Nest_hpp */
