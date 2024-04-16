//
//  Nest.hpp
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 08/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  defines nest properties, associated functions
//  Also contains output function for individuals during lastOfUs
// Prompt 4

#ifndef Nest_hpp
#define Nest_hpp    

#include "Individual.hpp"
#include <algorithm>

class Nest {
public:
    Nest(const unsigned int nid, const params& p);
    Nest(const unsigned int nid, const params& p, const Nest& prevNest);
    // Nest functions, self explanatory broadly, detailed explanation given above function definition

    // Nest variables
    unsigned int nest_id;
    unsigned int individual_id_counter = 0;
    std::vector<Individual> NestWorkers;
    std::vector<double> NestMean;
    double TotalAbundance;
    int NestStock;
    double TolIntercept;
    double TolSlope;

    // Nest functions
    void mutate(const params& p);
    bool check_Intruder(const params& p, const std::vector<double>& otherProfile);
    bool check_Resident(const params& p, const Individual& resident);
    double get_Tolerance(const params&p, const double distance);
    void calculate_abundance(const params& p);
    size_t findIndexById(const int id);
};

// Constructor for initial nests
Nest::Nest(const unsigned int nid, const params& p) : nest_id(nid) {
    for (int i = 0; i < p.iNumCues; i++) {
        NestMean.push_back(exponential(p.dExpParam));
    }

    calculate_abundance(p);
    NestStock = p.iInitNestStock;
    TolIntercept = normal(dInitIntercept, p.dMutationStrength);
    TolSlope = normal(dInitSlope, p.dMutationStrength);

    for (int i = 0; i < p.iNumWorkers; i++) {
        Individual newWorker(individual_id_counter, p, NestMean);
        newWorker.nest_id = nid;
        ++individual_id_counter;
        NestWorkers.push_back(newWorker);
    }
} 

// Constructor for reproduced nests
Nest::Nest(const unsigned int nid, const params& p, const Nest& prevNest) :
 nest_id(nid), NestMean(prevNest.NestMean) {
    mutate(p);
    calculate_abundance(p);
    NestStock = p.iInitNestStock;

    if (bIsCoevolve) {
        TolIntercept = prevNest.TolIntercept + normal(p.dMutBias, p.dMutationStrength);
        TolSlope = prevNest.TolSlope + normal(p.dMutBias, p.dMutationStrength);
    } else {
        TolIntercept = normal(dInitIntercept, p.dMutationStrength);
        TolSlope = normal(dInitSlope, p.dMutationStrength);
    }

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

void Nest::mutate(const params& p) {
    for (int i = 0; i < p.iNumCues; i++) {
        NestMean[i] += normal(p.dMutBias, p.dMutationStrength);
        if (NestMean[i] < 0.0) NestMean[i] = 0.0;
    }
}

bool Nest::check_Intruder(const params& p, const std::vector<double>& otherProfile) {
    double distance = 0.0;
    size_t resIndex = uni_int(0, NestWorkers.size());
    switch (p.iModelChoice)
    {
    case 0:
        distance = NestWorkers[resIndex].calculateGestaltDist(NestMean, otherProfile);
        break;
    case 1:
        distance = NestWorkers[resIndex].calculateDPresentDist(otherProfile);
        break;
    case 2:
        distance = NestWorkers[resIndex].calculateUAbsentDist(otherProfile);
        break;
    case 3:
        distance = uni_real();
        break;
    default:
        break;
    }

    double tolerance = get_Tolerance(p, distance);
    // std::cout << "Distance: " << distance << " | tolerance: " << tolerance << std::endl;
    return !bernoulli(tolerance);
}

bool Nest::check_Resident(const params& p, const Individual& resident) {
    double distance = 0.0;
    int resIndex = uni_int(0, NestWorkers.size());
    if (NestWorkers[resIndex].ind_id == resident.ind_id) {
        //LC std::cout << "resampling" << std::endl;
        while (NestWorkers[resIndex].ind_id == resident.ind_id) {
            resIndex = uni_int(0, NestWorkers.size());
        }   
    }
    switch (p.iModelChoice)
    {
    case 0:
        distance = NestWorkers[resIndex].calculateGestaltDist(NestMean, resident.IndiCues);
        break;
    case 1:
        distance = NestWorkers[resIndex].calculateDPresentDist(resident.IndiCues);
        break;
    case 2:
        distance = NestWorkers[resIndex].calculateUAbsentDist(resident.IndiCues);
        break;
    case 3:
        distance = uni_real();
        break;
    default:
        break;
    }

    double tolerance = get_Tolerance(p, distance);
    // std::cout << "Distance: " << distance << " | tolerance: " << tolerance << std::endl;
    return !bernoulli(tolerance);
}

double Nest::get_Tolerance(const params&p, const double distance) {
    double tolerance = 0.0;

    switch (p.iTolChoice)
    {
        // Linear Tolerance scenario
        case 0:
            tolerance = TolIntercept + TolSlope*distance;
            break;
        // Logistic Tolerance scenario
        case 1:
            tolerance = logistic(distance, TolIntercept, TolSlope);
            break;
        // Control random Tolerance scenario
        case 2:
            tolerance = uni_real();
            break;
        default:
            break;
    }

    if (tolerance < 0.0) {
        tolerance = 0.0;
    } else if (tolerance > 1.0) {
        tolerance = 1.0;
    }

    return tolerance;

}

#endif /* Nest_hpp */
