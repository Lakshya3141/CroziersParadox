//
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 03/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  -> Parses for parameters through config ini file and contains default values
//  -> Also defines parameters needed at compile time
//

#ifndef Parameters_hpp
#define Parameters_hpp

// #include "config_parser.h"
#include <array>
#include <string>
#include <vector>
#include <algorithm>

// Variables needed at compile time OR variables not explored in variation
double gtime = 0.0;                            // Global time
double max_gtime_evolution = 1.0;          // Time for evolution phase of simulations
double dRemovalTime = 1000.0;                  // Removal time -> numTicks after which lowest stock colonies die
double dStep = 1.0;                            // Time to go/come back from a foraging/colony

// dubious parameters we MAY wanna explore
int iNumColonies = 3;                        // Number of colonies
int iInitNestStock = 25;                          // Initial stock of colony at start/after removal
int iInitFoodStock = 300;                     // Intial food stock available for foraging
double dExpParam = 0.1;                       // Exponential parameter, 1/dExpParam is from which initial cues are sampled

// Parameters to be incorporated in config file
bool bIsCoevolve = true;                      // A boolean variable to determine if coevolution switches on at some point
double dTimeCoevolveStart = max_gtime_evolution;  // Time point of switch to coevolution

struct params {
    params() {};
    
    // Below are the default values for parameters to be read from config file
    double dFracKilled = 0.4;                    // Mortality rate after dRemovalTime
    double dMetabolicCost = 40.0;                // Metabolic cost for cue production
    double dMutationStrength = 0.1;              // Mutation strength
    int iNumWorkers = 3;                        // Number of workers in each colony
    int iNumCues = 5;                           // Number of Cues
    std::string temp_params_to_record;
    std::vector < std::string > param_names_to_record;
    std::vector < float > params_to_record;
};

#endif /* Parameters_hpp */
