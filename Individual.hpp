//
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 05/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  -> defines individual functions
//

#ifndef Individual_hpp
#define Individual_hpp

#include "Parameters.hpp"
#include "Random.hpp"

// using CuesArray = std::array<double, iNumCues>;

class Individual {
public:
    // Individual constructors
    // male and female default + initialised constructors overloaded
    Individual(const int id, const params& p, const std::vector<double>& NestMean);   
    
    std::vector<double> IndiCues;
    bool bSuccesfulFood = false;// True if ant carries food on way home
    bool is_alive = true;       // Death status of individual
    double t_birth = uni_real();// Birth time of each individual, random number between 0 - 1
    double t_next;              // Next time of action of individual
    int ind_id;                 // Individual identifier
    unsigned int nest_id;       // Nest identifier

    // Individual funcions, names are self explanatory
    // more explanation given above function definition

};

// constructor for new individuals from Nest Mean
Individual::Individual (const int id, const params& p, const std::vector<double>& NestMean) : ind_id(id) {
    for (int i = 0; i < p.iNumCues; i++) {
        IndiCues.push_back(normal(NestMean[i], p.dMutationStrength));
        if (IndiCues[i] < 0) IndiCues[i] = 0.0;
    }
    t_birth = gtime + uni_real();
    t_next = t_birth;
}


#endif /* Individual_hpp */
