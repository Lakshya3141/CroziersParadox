//
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 05/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  -> defines individual class and functions
//  Pt 3

#ifndef Individual_hpp
#define Individual_hpp

#include <algorithm>
#include <stdexcept>
#include "Parameters.hpp"
#include "Random.hpp"

// The class below defines an individual and the functions corresponding to it
class Individual {
public:
    // Individual constructor definition: creates an individual mutated around NestMean and with ID
    Individual(const int id, const params& p, const std::vector<double>& NestMean, const double NestNeutral);   
    
    std::vector<double> IndiCues;   // Vector containing cue values for individuals
    double NeutralGene;             // Neutral gene to report relatedness later

    bool bIsGoing = true;       // True if heading out // False if returning
    bool bForage = false;       // True if stealing
    bool bSuccesfulFood = false;// True if ant carries food on way home
    bool is_alive = true;       // Death status of individual [Important when nest dies out]
    double t_birth = uni_real();// Birth time of each individual, random number between 0 - 1
    double t_next;              // Next time of action of individual
    int ind_id;                 // Individual identifier
    unsigned int nest_id;       // Nest identifier

    // Individual funcions, names are self explanatory
    // more explanation given above function definition
    void mutate(const params& p);   // Mutates individual cues and neutral gene
    // Functions below calculate various distances given profiles
    double calculateGestaltDist(const std::vector<double>& rNestMean, const std::vector<double>& otherProfile) const;
    double calculateUAbsentDist(const std::vector<double>& otherProfile) const;
    double calculateDPresentDist(const std::vector<double>& otherProfile) const;
};

// constructor for new individuals from mutated Nest Mean
// Also assigns a birth time and time of action to the individual
Individual::Individual (const int id, const params& p, const std::vector<double>& NestMean, const double NestNeutral) 
: ind_id(id), NeutralGene(NestNeutral) {
    for (int i = 0; i < NestMean.size(); i++) {
        IndiCues.push_back(NestMean[i]);
    }
    mutate(p);
    t_birth = gtime + uni_real();
    t_next = t_birth;
}

// Mutate function
void Individual::mutate (const params& p) {
    for (int i = 0; i < p.iNumCues; i++) {
        IndiCues[i] += normal(p.dMutBias, p.dMutationStrength);
        if (IndiCues[i] < 0) IndiCues[i] = 0.0;
    }
    NeutralGene += normal(p.dMutBias, p.dMutationStrength);
}

// Function to calculate Bray Curtis distance for the "gestalt" recognition mode
double Individual::calculateGestaltDist(const std::vector<double>& rNestMean, const std::vector<double>& otherProfile) const {
    double distance = 0.0;
    double sum1 = 0.0;
    double sum2 = 0.0;

    for (size_t i = 0; i < rNestMean.size(); ++i) {
        distance += std::min(rNestMean[i], otherProfile[i]);
        sum1 += rNestMean[i];
        sum2 += otherProfile[i];
    }

    if ((sum1 + sum2) > 0) {
        distance = 1.0 - (2.0 * distance / (sum1 + sum2));
    } else {
        throw std::runtime_error("Sum of profile elements is zero"); // Throw a runtime error
    }

    return distance;
}

// Function to calculate Bray Curtis distance for the "undesirable-absent" recognition mode
double Individual::calculateUAbsentDist(const std::vector<double>& otherProfile) const {
    double distance = 0.0;
    double sum1 = 0.0;
    double sum2 = 0.0;

    for (size_t i = 0; i < IndiCues.size(); ++i) {
        distance += std::min(IndiCues[i], otherProfile[i]);
        if (otherProfile[i] < IndiCues[i]) {
            sum1 += otherProfile[i];
            sum2 += otherProfile[i];
        } else {
            sum1 += IndiCues[i];
            sum2 += otherProfile[i];
        }
    }

    if ((sum1 + sum2) > 0) {
        distance = 1.0 - (2.0 * distance / (sum1 + sum2));
    } else {
        throw std::runtime_error("Sum of profile elements is zero"); // Throw a runtime error
    }

    return distance;
}

// Function to calculate Bray Curtis distance for the "desirable-present" recognition mode
double Individual::calculateDPresentDist(const std::vector<double>& otherProfile) const {
    double distance = 0.0;
    double sum1 = 0.0;
    double sum2 = 0.0;

    for (size_t i = 0; i < IndiCues.size(); ++i) {
        distance += std::min(IndiCues[i], otherProfile[i]);
        if (IndiCues[i] < otherProfile[i]) {
            sum1 += IndiCues[i];
            sum2 += IndiCues[i];
        } else {
            sum1 += IndiCues[i];
            sum2 += otherProfile[i];
        }
    }

    if ((sum1 + sum2) > 0) {
        distance = 1.0 - (2.0 * distance / (sum1 + sum2));
    } else {
        throw std::runtime_error("Sum of profile elements is zero"); // Throw a runtime error
    }

    return distance;
}

#endif /* Individual_hpp */
