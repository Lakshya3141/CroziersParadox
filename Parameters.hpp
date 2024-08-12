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
#include <stdexcept>
#include <filesystem>
#include "Random.hpp"

namespace fs = std::filesystem;

// Variables needed at compile time OR variables not explored in variation
double gtime = 0.0;                               // Global time
double dRemovalTime = 200.0;                      // Removal time -> unit time after which lowest stock colonies die
double max_gtime_evolution = dRemovalTime*10.0;    // Time for evolution phase of simulations
double dReproductionTime = dRemovalTime;          // Reproduction time -> numTicks after mass reproduction occurs
double dOutputTime = 100.1;                        // Interval after which population stats are outputed
double dFracDeadNest = 0.0;                       // Fraction of dead nests recorded in output files
double dFracResetSteal = 0.99;                    // Time after which steal is set to 0 to obtain proper values
const double dInitIntercept = 0.0;                // Initial value of intercept for linear / logistic comparison
const double dInitSlope = 0.0;                    // Initial value of slope for linear / logistic function
bool bIsCoevolve = false;                         // Wether tolerance co-evolves with the cues

// The struct below contains parameters that WILL BE read
// from a config file
struct params {
  params() {};
  
  params(const std::string& file_name) {
    read_parameters_from_ini(file_name);
  }

  // Below are the default values for parameters to be read from config file
  double dFracKilled = 0.4;                     // Mortality rate after dRemovalTime
  double dMetabolicCost = 40.0;                 // Metabolic cost for cue production
  double dMutationStrength = 1.0;               // Mutation strength of tolerance
  double dMutationStrengthCues = 1.0;           // Mutation strength of cues and neutral gene
  double dFracIndMutStrength = 0.001;           // multiplied by mutation strength for individuals
  double dMutBias = 0.0;                        // Mutation bias
  double iNumWorkers = 5;                       // Number of workers in each colony
  double iNumCues = 5;                          // Number of Cues
  double iNumColonies = 5;                      // Number of colonies
  double dInitNestStock = 25.0;                 // Initial stock of colony at start/after removal
  double dInitFoodStock = 300.0;                // Intial food stock available for foraging
  double dExpParam = 0.01;                      // Exponential parameter, 1/dExpParam is from which initial cues are sampled
  double dMeanActionTime = 1.0;                 // Average time of action for gillespe algorithm
  double dRatePopStock = 150.0;                 // Rate of regeneration of population stock per unit time
  double dConstantPopStock = 30.0;              // COnstant population stock size in specific case
  double dRateNestStock = 0.0/24.0;             // Rate of regeneration of nest stock per unit time
  double dTickTime = 2.0;                           // Time after which population stock is reset IF iConstPopStock = 2

  double iModelChoice = 0.0;        // 0 for gestalt, 1 for dpresent, 2 for uabsent
  double iTolChoice = 2.0;          // 0 for linear, 1 for logistic, 2 for control
  double iKillChoice = 1;           // 0 for random killing, 1 for sorted killing, 2 for no mass killing
  double iRepChoice = 4;            // 0 for mass reproduction, 1 for individual reproduction, 2 for both
  double iFoodResetChoice = 0;      // Reset nest and population stock at mass reproduction point
                                    // 1 for yes reset, 0 for no reset
  double iConstStockChoice = 0;     // 0 linearly increasing | 1 for const pop stock | 2 for tick system 

  std::string temp_params_to_record;                  // Temp variable
  std::vector < std::string > param_names_to_record;  // Parameter names to add to output files
  std::vector < float > params_to_record;             // Parameter values to add to output files

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
    dTickTime                = from_config.getValueOfKey<double>("dTickTime");
    dMeanActionTime          = from_config.getValueOfKey<double>("dMeanActionTime");
    dRatePopStock            = from_config.getValueOfKey<double>("dRatePopStock");
    dConstantPopStock        = from_config.getValueOfKey<double>("dConstantPopStock");
    dRateNestStock           = from_config.getValueOfKey<double>("dRateNestStock");
    iModelChoice             = from_config.getValueOfKey<double>("iModelChoice");
    iTolChoice               = from_config.getValueOfKey<double>("iTolChoice");
    iKillChoice              = from_config.getValueOfKey<double>("iKillChoice");
    iRepChoice               = from_config.getValueOfKey<double>("iRepChoice");
    iFoodResetChoice         = from_config.getValueOfKey<double>("iFoodResetChoice");
    iConstStockChoice        = from_config.getValueOfKey<double>("iConstStockChoice");
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
    if (s == "dTickTime")                 return dTickTime;
    if (s == "dMeanActionTime")           return dMeanActionTime;
    if (s == "dRatePopStock")             return dRatePopStock;
    if (s == "dConstantPopStock")         return dConstantPopStock;
    if (s == "dRateNestStock")            return dRateNestStock;
    if (s == "iModelChoice")              return iModelChoice;
    if (s == "iTolChoice")                return iTolChoice;
    if (s == "iKillChoice")               return iKillChoice;
    if (s == "iRepChoice")                return iRepChoice;
    if (s == "iFoodResetChoice")          return iFoodResetChoice;
    if (s == "iConstStockChoice")          return iConstStockChoice;
    // ADD PARAMS TO RECORD
    throw std::runtime_error("can not find parameter");
    return -1.f; // FAIL
  }

  // Function to print strings of model choices in output file
  void print_string_vals(){
    std::vector<std::string> modelchoice = {"gestalt", "Dpresent", "Uabsent", "control", "gestaltInd", "DpresentInd", "UabsentInd"};
    std::vector<std::string> tolchoice = {"linear", "logistic", "control"};
    std::vector<std::string> killchoice = {"random", "sorted", "nodeath"};
    std::vector<std::string> repchoice = {"mass", "individual", "both", "control"};
    std::vector<std::string> foodresetchoice = {"no", "yes"};
    std::vector<std::string> constPopStockchoice = {"linearly increasing", "constant population stock", "tick based reset"};

    std::cout << "Model : " << modelchoice[iModelChoice] << std::endl;
    std::cout << "Tolerance : " << tolchoice[iTolChoice] << std::endl;
    std::cout << "KillMode : " << killchoice[iKillChoice] << std::endl;
    std::cout << "Reproduction : " << repchoice[iRepChoice] << std::endl;      
    std::cout << "Food Reset : " << foodresetchoice[iFoodResetChoice] << std::endl;
    std::cout << "Const Pop Stock : " << constPopStockchoice[iConstStockChoice] << std::endl;
  }
};

// Function to export parameters to a CSV file
void exportParametersToCSV(const params& p) {
    // Open the file in write mode
    fs::path parameterPath = fs::path("./output_sim/" + std::to_string(simulationID) + "_parameter.csv");
    std::ofstream file(parameterPath);

    // Write the header
    file << "max_gtime_evolution,dRemovalTime,dReproductionTime,dTickTime,dOutputTime,dFracDeadNest,dFracResetSteal,dInitIntercept,dInitSlope,bIsCoevolve,";
    file << "dFracKilled,dMetabolicCost,dMutationStrength,dMutationStrengthCues,dFracIndMutStrength,dMutBias,iNumWorkers,iNumCues,iNumColonies,dInitNestStock,dInitFoodStock,dExpParam,dMeanActionTime,dRatePopStock,dConstantPopStock,dRateNestStock,iModelChoice,iTolChoice,iKillChoice,iRepChoice,iFoodResetChoice,iConstStockChoice\n";

    // Write the values
    file << max_gtime_evolution << "," << dRemovalTime << "," << dReproductionTime << "," << p.dTickTime << "," << dOutputTime << "," << dFracDeadNest << "," << dFracResetSteal << "," << dInitIntercept << "," << dInitSlope << "," << bIsCoevolve << ",";
    file << p.dFracKilled << "," << p.dMetabolicCost << "," << p.dMutationStrength << "," << p.dMutationStrengthCues << "," << p.dFracIndMutStrength << "," << p.dMutBias << "," << p.iNumWorkers << "," << p.iNumCues << "," << p.iNumColonies << "," << p.dInitNestStock << "," << p.dInitFoodStock << "," << p.dExpParam << "," << p.dMeanActionTime << "," << p.dRatePopStock << "," << p.dConstantPopStock << "," << p.dRateNestStock << "," << p.iModelChoice << "," << p.iTolChoice << "," << p.iKillChoice << "," << p.iRepChoice << "," << p.iFoodResetChoice << "," << p.iConstStockChoice << "\n";

    // Close the file
    file.close();
}

#endif /* Parameters_hpp */
