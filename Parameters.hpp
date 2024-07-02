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

#include "config_parser.h"
#include <array>
#include <string>
#include <vector>
#include <algorithm>
#include <stdexcept>
#include <filesystem>
#include "Random.hpp"

namespace fs = std::filesystem;

// Variables needed at compile time OR variables not explored in variation
double gtime = 0.0;                            // Global time
double max_gtime_evolution = 1000.0;          // Time for evolution phase of simulations
double dRemovalTime = 200.0;                  // Removal time -> numTicks after which lowest stock colonies die
double dReproductionTime = dRemovalTime;       // Reproduction time -> numTicks after mass reproduction occurs
double dOutputTime = 50.1;
double dFracDeadNest = 0.3;
double dFracLastIndRecord = 0.05;                  // Records individual movement in last this fraction of simulation

const double dInitIntercept = 0.0;          // Initial value of intercept for linear / logistic comparison
const double dInitSlope = 1.0;              // Initial value of slope for linear / logistic function

// dubious parameters we MAY wanna explore
bool bIsCoevolve = false;   

// The struct below defines parameters that WILL BE read
// from a config file. For now, defining the default values for these
// to be tested on my terminal. Will add functions that parse from a file later
// when required
struct params {
    params() {};
    
    params(const std::string& file_name) {
      read_parameters_from_ini(file_name);
    }

    // Below are the default values for parameters to be read from config file
    double dFracKilled = 0.4;                    // Mortality rate after dRemovalTime
    double dMetabolicCost = 40.0;                // Metabolic cost for cue production
    double dMutationStrength = 1.0;             // Mutation strength of tolerance and neutral genes
    double dMutationStrengthCues = 1.0;           // Mutation strength of cues
    double dFracIndMutStrength = 0.001;            // multiplied by mutation strength for individuals
    double dMutBias = 0.0;                       // Mutation bias
    double iNumWorkers = 5;                        // Number of workers in each colony
    double iNumCues = 5;                           // Number of Cues
    double iNumColonies = 5;                        // Number of colonies
    double dInitNestStock = 25.0;                          // Initial stock of colony at start/after removal
    double dInitFoodStock = 300.0;                     // Intial food stock available for foraging
    double dExpParam = 0.01;                       // Exponential parameter, 1/dExpParam is from which initial cues are sampled
    double dMeanActionTime = 1.0;               // Average time of action for gillespe algorithm
    double dRatePopStock = 5.0; //150.0;               //  Rate of regeneration of population stock per unit time
    double dRateNestStock = 0.0/24.0;               // Rate of regeneration of nest stock per unit time

    double iModelChoice = 0.0;       // Int value for model choice to have in if statements
    double iTolChoice = 2.0;       // Int value for tolerance choice to have in if statements
                                    // 0 for linear, 1 for logistic, 2 for control
    double iKillChoice = 1;                        // 0 for random killing, 1 for sorted killing, 2 for no mass killing
    double iRepChoice = 4;                         // 0 for mass reproduction, 1 for individual reproduction, 2 for both
    double iFoodResetChoice = 0;                   // Only relevant in mass reproduction
                                                // 1 for yes reset, 0 for no reset

    std::string temp_params_to_record;          // Not relevant now
    std::vector < std::string > param_names_to_record;  // Not relevant now
    std::vector < float > params_to_record;     // Not relevant now

    void read_parameters_from_ini(const std::string& file_name) {
        ConfigFile from_config(file_name);

        
        iNumWorkers              = from_config.getValueOfKey<double>("iNumWorkers");
        iNumCues                 = from_config.getValueOfKey<double>("iNumCues");
        iNumColonies             = from_config.getValueOfKey<double>("iNumColonies");
        dFracKilled              = from_config.getValueOfKey<double>("dFracKilled");
        dMetabolicCost           = from_config.getValueOfKey<double>("dMetabolicCost");
        dMutationStrength        = from_config.getValueOfKey<double>("dMutationStrength");
        dMutationStrengthCues    = from_config.getValueOfKey<double>("dMutationStrengthCues");
        dFracIndMutStrength      = from_config.getValueOfKey<double>("dFracIndMutStrength");
        dMutBias                 = from_config.getValueOfKey<double>("dMutBias");
        dInitNestStock           = from_config.getValueOfKey<double>("dInitNestStock");
        dInitFoodStock           = from_config.getValueOfKey<double>("dInitFoodStock");
        dExpParam                = from_config.getValueOfKey<double>("dExpParam");
        dMeanActionTime          = from_config.getValueOfKey<double>("dMeanActionTime");
        dRatePopStock            = from_config.getValueOfKey<double>("dRatePopStock");
        dRateNestStock           = from_config.getValueOfKey<double>("dRateNestStock");
        iModelChoice             = from_config.getValueOfKey<double>("iModelChoice");
        iTolChoice               = from_config.getValueOfKey<double>("iTolChoice");
        iKillChoice              = from_config.getValueOfKey<double>("iKillChoice");
        iRepChoice               = from_config.getValueOfKey<double>("iRepChoice");
        iFoodResetChoice         = from_config.getValueOfKey<double>("iFoodResetChoice");
        temp_params_to_record    = from_config.getValueOfKey<std::string>("params_to_record");
        param_names_to_record    = split(temp_params_to_record);
        params_to_record         = create_params_to_record(param_names_to_record);
    }

    std::vector< std::string > split(std::string s) {
      // code from: https://stackoverflow.com/questions/14265581/parse-split-a-string-in-c-using-string-delimiter-standard-c
      std::vector< std::string > output;
      std::string delimiter = ",";
      size_t pos = 0;
      std::string token;
      while ((pos = s.find(delimiter)) != std::string::npos) {
        token = s.substr(0, pos);
        output.push_back(token);
        s.erase(0, pos + delimiter.length());
      }
      output.push_back(s);
      return output;
    }

    std::vector< float > create_params_to_record(const std::vector< std::string >& param_names) {
      std::vector< float > output;
      for (auto i : param_names) {
        output.push_back(get_val(i));
      }
      return output;
    }

    float get_val(std::string s) {
        if (s == "dFracKilled")               return dFracKilled;
        if (s == "dMetabolicCost")            return dMetabolicCost;
        if (s == "dMutationStrength")         return dMutationStrength;
        if (s == "dMutationStrengthCues")     return dMutationStrengthCues;
        if (s == "dFracIndMutStrength")       return dFracIndMutStrength;
        if (s == "dMutBias")                  return dMutBias;
        if (s == "iNumWorkers")               return iNumWorkers;
        if (s == "iNumCues")                  return iNumCues;
        if (s == "iNumColonies")              return iNumColonies;
        if (s == "dInitNestStock")            return dInitNestStock;
        if (s == "dInitFoodStock")            return dInitFoodStock;
        if (s == "dExpParam")                 return dExpParam;
        if (s == "dMeanActionTime")           return dMeanActionTime;
        if (s == "dRatePopStock")             return dRatePopStock;
        if (s == "dRateNestStock")            return dRateNestStock;
        if (s == "iModelChoice")              return iModelChoice;
        if (s == "iTolChoice")                return iTolChoice;
        if (s == "iKillChoice")               return iKillChoice;
        if (s == "iRepChoice")                return iRepChoice;
        if (s == "iFoodResetChoice")          return iFoodResetChoice;
        // ADD PARAMS TO RECORD
        throw std::runtime_error("can not find parameter");
        return -1.f; // FAIL
    }

    void print_string_vals(){
        std::vector<std::string> modelchoice = {"gestalt", "Dpresent", "Uabsent", "control", "gestaltInd", "DpresentInd", "UabsentInd"};
        std::vector<std::string> tolchoice = {"linear", "logistic", "control"};
        std::vector<std::string> killchoice = {"random", "sorted", "nodeath"};
        std::vector<std::string> repchoice = {"mass", "individual", "both", "control"};
        std::vector<std::string> foodresetchoice = {"yes", "no"};


        std::cout << "Model : " << modelchoice[iModelChoice] << std::endl;
        std::cout << "Tolerance : " << tolchoice[iTolChoice] << std::endl;
        std::cout << "KillMode : " << killchoice[iKillChoice] << std::endl;
        std::cout << "Reproduction : " << repchoice[iRepChoice] << std::endl;
        std::cout << "Food Reset : " << foodresetchoice[iFoodResetChoice] << std::endl;
    }
};

// Function to export parameters to a CSV file
void exportParametersToCSV(const params& p) {
    // Open the file in write mode
    fs::path parameterPath = fs::path("./output_sim/" + std::to_string(simulationID) + "_parameter.csv");
    std::ofstream file(parameterPath);

    // Write the header
    file << "Parameter,Value\n";

    // Write the global parameters
    file << "max_gtime_evolution," << max_gtime_evolution << "\n";
    file << "dRemovalTime," << dRemovalTime << "\n";
    file << "dReproductionTime," << dReproductionTime << "\n";
    file << "dOutputTime," << dOutputTime << "\n";
    file << "dFracDeadNest," << dFracDeadNest << "\n";
    file << "dFracLastIndRecord," << dFracLastIndRecord << "\n";
    file << "dInitIntercept," << dInitIntercept << "\n";
    file << "dInitSlope," << dInitSlope << "\n";
    file << "bIsCoevolve," << bIsCoevolve << "\n";

    // Write the parameters from the params struct
    file << "dFracKilled," << p.dFracKilled << "\n";
    file << "dMetabolicCost," << p.dMetabolicCost << "\n";
    file << "dMutationStrength," << p.dMutationStrength << "\n";
    file << "dMutationStrengthCues," << p.dMutationStrengthCues << "\n";
    file << "dFracIndMutStrength," << p.dFracIndMutStrength << "\n";
    file << "dMutBias," << p.dMutBias << "\n";
    file << "iNumWorkers," << p.iNumWorkers << "\n";
    file << "iNumCues," << p.iNumCues << "\n";
    file << "iNumColonies," << p.iNumColonies << "\n";
    file << "dInitNestStock," << p.dInitNestStock << "\n";
    file << "dInitFoodStock," << p.dInitFoodStock << "\n";
    file << "dExpParam," << p.dExpParam << "\n";
    file << "dMeanActionTime," << p.dMeanActionTime << "\n";
    file << "dRatePopStock," << p.dRatePopStock << "\n";
    file << "dRateNestStock," << p.dRateNestStock << "\n";
    file << "iModelChoice," << p.iModelChoice << "\n";
    file << "iTolChoice," << p.iTolChoice << "\n";
    file << "iKillChoice," << p.iKillChoice << "\n";
    file << "iRepChoice," << p.iRepChoice << "\n";
    file << "iFoodResetChoice," << p.iFoodResetChoice << "\n";

    // Close the file
    file.close();
}

#endif /* Parameters_hpp */
