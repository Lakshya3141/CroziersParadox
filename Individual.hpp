//
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 05/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  -> defines individual functions
// Prompt 3

#ifndef Individual_hpp
#define Individual_hpp

#include<algorithm>
#include <stdexcept>
#include "Parameters.hpp"
#include "Random.hpp"

class Individual {
public:
    // Individual constructors
    // male and female default + initialised constructors overloaded
    Individual(const int id, const params& p, const std::vector<double>& NestMean);   
    
    std::vector<double> IndiCues;
    double NeutralGene;

    bool bSuccesfulFood = false;// True if ant carries food on way home
    bool is_alive = true;       // Death status of individual
    double t_birth = uni_real();// Birth time of each individual, random number between 0 - 1
    double t_next;              // Next time of action of individual
    int ind_id;                 // Individual identifier
    unsigned int nest_id;       // Nest identifier

    // Individual funcions, names are self explanatory
    // more explanation given above function definition
    void mutate(const params& p);
    double calculateGestaltDist(const std::vector<double>& rNestMean, const std::vector<double>& otherProfile);
    double calculateUAbsentDist(const std::vector<double>& otherProfile);
    double calculateDPresentDist(const std::vector<double>& otherProfile);

};

// constructor for new individuals from Nest Mean
Individual::Individual (const int id, const params& p, const std::vector<double>& NestMean) 
: ind_id(id), NeutralGene(0.0) {
    for (int i = 0; i < NestMean.size(); i++) {
        IndiCues.push_back(NestMean[i]);
    }
    mutate(p);
    t_birth = gtime + uni_real();
    t_next = t_birth;
}

void Individual::mutate (const params& p) {
    for (int i = 0; i < p.iNumCues; i++) {
        IndiCues[i] += normal(p.dMutBias, p.dMutationStrength);
        if (IndiCues[i] < 0) IndiCues[i] = 0.0;
    }
    NeutralGene += normal(p.dMutBias, p.dMutationStrength);
}

// Function to calculate Bray Curtis distance for the "gestalt" recognition mode
double Individual::calculateGestaltDist(const std::vector<double>& rNestMean, const std::vector<double>& otherProfile) {
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
double Individual::calculateUAbsentDist(const std::vector<double>& otherProfile) {
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
double Individual::calculateDPresentDist(const std::vector<double>& otherProfile) {
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
