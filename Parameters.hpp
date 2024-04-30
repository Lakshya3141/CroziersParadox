//
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 03/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  -> Parses for parameters through config ini file and contains default values
//  -> Also defines parameters needed at compile time
//  Pt 2

#ifndef Parameters_hpp
#define Parameters_hpp

// #include "config_parser.h"
#include <array>
#include <string>
#include <vector>
#include <algorithm>
#include <stdexcept>

// Variables needed at compile time OR variables not explored in variation
double gtime = 0.0;                            // Global time
double max_gtime_evolution = 1.0;          // Time for evolution phase of simulations
double dRemovalTime = 1000.0;                  // Removal time -> numTicks after which lowest stock colonies die
double dStep = 1.0;                            // Time to go/come back from a foraging/colony

const double dInitIntercept = 0.0;          // Initial value of intercept for linear / logistic comparison
const double dInitSlope = 1.0;              // Initial value of slope for linear / logistic function

// dubious parameters we MAY wanna explore
bool bIsCoevolve = true;   

// The struct below defines parameters that WILL BE read
// from a config file. For now, defining the default values for these
// to be tested on my terminal. Will add functions that parse from a file later
// when required
struct params {
    params() {};
    
    // Below are the default values for parameters to be read from config file
    double dFracKilled = 0.4;                    // Mortality rate after dRemovalTime
    double dMetabolicCost = 40.0;                // Metabolic cost for cue production
    double dMutationStrength = 0.0001;              // Mutation strength
    double dMutBias = 0.0;                       // Mutation bias
    int iNumWorkers = 2;                        // Number of workers in each colony
    int iNumCues = 5;                           // Number of Cues
    int iNumColonies = 3;                        // Number of colonies
    int iInitNestStock = 25;                          // Initial stock of colony at start/after removal
    int iInitFoodStock = 300;                     // Intial food stock available for foraging
    double dExpParam = 0.1;                       // Exponential parameter, 1/dExpParam is from which initial cues are sampled
    std::string sModelChoice = "gestalt";        // Model choice: "control", "uabsent", "dpresent", "gestalt"
    int iModelChoice = convertStringModeltoInt(sModelChoice);       // Int value for model choice to have in if statements
    std::string sTolChoice = "linear";    // Tolerance choice: "control", "linear", "logistic"
    int iTolChoice = convertStringTolerancetoInt(sTolChoice);       // Int value for tolerance choice to have in if statements
    std::string temp_params_to_record;          // Not relevant now
    std::vector < std::string > param_names_to_record;  // Not relevant now
    std::vector < float > params_to_record;     // Not relevant now

    // Function to take in string of modelchoice and return the analagous int value.
    int convertStringModeltoInt(const std::string& ModelChoice) {
        int dumRes;
        if (ModelChoice == "gestalt") {
            dumRes = 0;
        } else if (ModelChoice == "dpresent") {
            dumRes = 1;
        } else if (ModelChoice == "uabsent") {
            dumRes = 2;
        } else if(ModelChoice == "control") {
            dumRes = 3;
        } else throw std::runtime_error("Wrong model specified"); 

        iModelChoice = dumRes;
        return dumRes;
    }

    // Function to take in string of tolerance choice and return the analagous int value.
    int convertStringTolerancetoInt(const std::string& TolChoice) {
        int dumRes;
        if (TolChoice == "linear") {
            dumRes = 0;
        } else if (TolChoice == "logistic") {
            dumRes = 1;
        } else if (TolChoice == "control") {
            dumRes = 2;
        } else throw std::runtime_error("Wrong tolerance specified"); 

        iTolChoice = dumRes;
        return dumRes;
    }
};

#endif /* Parameters_hpp */
