//
//  Nest.hpp
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 12/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  -> Defines nest class which comprises of workers
//  -> And nest functions
//  Pt 4

#ifndef Nest_hpp
#define Nest_hpp    

#include "Individual.hpp"
#include <algorithm>

class Nest {
public:
    // Below are the default and reproduced nest functions respectively
    Nest(const unsigned int nid, const params& p);
    Nest(const unsigned int nid, const params& p, const Nest& prevNest);
    
    // Nest variables
    unsigned int nest_id;                       // Nest ID
    unsigned int individual_id_counter = 0;     // Starts every nest ind ID at 0
    std::vector<Individual> NestWorkers;        // Vector containing workers
    std::vector<double> NestMean;               // Nest mean cues
    double NestNeutralGene;                     // Neutral gene for nest
    double TotalAbundance;                      // Total abundance of nest
    int NestStock;                              // Food stock with nest
    double TolIntercept;                        // Intercept for linear/logistic threshold curve
    double TolSlope;                            // Slope for linear/logistic threshold curve
    double tbirth = gtime;                      // Time of birth
    int num_offsprings = 0.0;                   // Number of offsprings

    // Nest functions
    void mutate(const params& p);               // Mutates nest cues and neutral gene for new nest
    // Function to check intruder stealing food
    bool check_Intruder(const params& p, const std::vector<double>& otherProfile) const;
    // Function to check resident returning after foraging trip
    bool check_Resident(const params& p, const Individual& resident) const;
    // Function to get tolerance for a particular distance
    double get_Tolerance(const params&p, const double distance) const;
    void calculate_abundance(const params& p);  // Calculates abundance
    size_t findIndexById(const int id);         // Finds index of individual in NestWorkers from ID
};

// Constructor for initial nests
Nest::Nest(const unsigned int nid, const params& p) : nest_id(nid) {

    // Initialise nest mean from exponential distribution
    for (int i = 0; i < p.iNumCues; i++) {
        NestMean.push_back(exponential(p.dExpParam));
    }

    calculate_abundance(p);                         // Calculate abundance
    NestStock = p.iInitNestStock;                   // Create initial nest stock
    // Assign values to neutral, intercept and slope genes
    NestNeutralGene = 0.0 + normal(p.dMutBias, p.dMutationStrength);
    TolIntercept = normal(dInitIntercept, p.dMutationStrength);
    TolSlope = normal(dInitSlope, p.dMutationStrength);

    // Create and push individuals into NestWorkers vector
    // Also increments individual ID counter
    for (int i = 0; i < p.iNumWorkers; i++) {
        Individual newWorker(individual_id_counter, p, NestMean, NestNeutralGene);
        newWorker.nest_id = nid;
        ++individual_id_counter;
        NestWorkers.push_back(newWorker);
    }
} 

// Constructor for reproduced nests
Nest::Nest(const unsigned int nid, const params& p, const Nest& prevNest) :
 nest_id(nid), NestMean(prevNest.NestMean), NestNeutralGene(prevNest.NestNeutralGene) {

    mutate(p);                      // Mutate nest cues and neutral gene
    calculate_abundance(p);         // Calculate abundance
    NestStock = p.iInitNestStock;   // Assign initial nest stock

    if (bIsCoevolve) {              // If coevolve is true mutate intercept and slope too
        TolIntercept = prevNest.TolIntercept + normal(p.dMutBias, p.dMutationStrength);
        TolSlope = prevNest.TolSlope + normal(p.dMutBias, p.dMutationStrength);
    } else {                        // If coevolve is not true, choose specific values for intercept and slope
        TolIntercept = normal(dInitIntercept, p.dMutationStrength);
        TolSlope = normal(dInitSlope, p.dMutationStrength);
    }

    // Create and add workers to NestWorkers vector
    for (int i = 0; i < p.iNumWorkers; i++) {
        Individual newWorker(individual_id_counter, p, NestMean, NestNeutralGene);
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

// Mutates nest cues and neutral gene
// Also makes sure the cues dont reach negative values
void Nest::mutate(const params& p) {
    for (int i = 0; i < p.iNumCues; i++) {
        NestMean[i] += normal(p.dMutBias, p.dMutationStrength);
        if (NestMean[i] < 0.0) NestMean[i] = 0.0;
    }
    NestNeutralGene += normal(p.dMutBias, p.dMutationStrength);
}

// Target nest function to check if intruder can enter or not
bool Nest::check_Intruder(const params& p, const std::vector<double>& otherProfile) const {
    double distance = 0.0;
    // Choose a resident ant at random to interact with the intruder LC????
    size_t resIndex = uni_int(0, NestWorkers.size());
    
    switch (p.iModelChoice)
    {   // Calculate distance of intruder from resident based on choice of model
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

    // Get tolerance based on distance metric decided
    double tolerance = get_Tolerance(p, distance);
    // 
    return !bernoulli(tolerance);
}

// Resident nest function to check if resident can return successfully
bool Nest::check_Resident(const params& p, const Individual& resident) const {
    double distance = 0.0;
    // Choose random resident that is NOT the same as returning individual
    int resIndex = uni_int(0, NestWorkers.size());
    if (NestWorkers[resIndex].ind_id == resident.ind_id) {
        while (NestWorkers[resIndex].ind_id == resident.ind_id) {
            resIndex = uni_int(0, NestWorkers.size());
        }   
    }

    switch (p.iModelChoice)
    {   // Calculate distance of returning resident from resident based on choice of model
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
    // Get tolerance from distance and choice of model
    double tolerance = get_Tolerance(p, distance);
    return !bernoulli(tolerance);
}

double Nest::get_Tolerance(const params&p, const double distance) const {
    double tolerance = 0.0;

    switch (p.iTolChoice)
    {
        case 0:         // Linear Tolerance scenario
            tolerance = TolIntercept + TolSlope*distance;
            break;
        case 1:         // Logistic Tolerance scenario
            tolerance = logistic(distance, TolIntercept, TolSlope);
            break;
        case 2:         // Control random Tolerance scenario
            tolerance = uni_real();
            break;
        default:
            break;
    }

    // Ensure tolerance belongs to [0.0, 1.0]
    if (tolerance < 0.0) {
        tolerance = 0.0;
    } else if (tolerance > 1.0) {
        tolerance = 1.0;
    }
    return tolerance;

}

#endif /* Nest_hpp */
