//
//  OGH_Eusociality
//
//  Created by Lakshya Chauhan on 25/09/2023.
//  Copyright © 2023 Lakshya Chauhan. All rights reserved.
//  -> Parses for parameters through config ini file and contains default values
//  -> Also defines parameters needed at compile time
//

#ifndef Parameters_hpp
#define Parameters_hpp

#include "config_parser.h"
#include <array>
#include <string>
#include <vector>
#include <algorithm>

// Below are the paramaters needed at compile time
// OR parameters that stay consistent across a parameter exploration
// OR global paramaters used throughout simulation like global time
// knot locations and resolution of splines
const int n_knots = 5;
const int n_resolution = 1000;
const int MaxLarvaeSpline = 500;

// LC: Jan you may wanna change these values, I changed them while cleaning
// to make sure outputting is working correctly
double gtime = 0.0;                               // Global time
double max_gtime_evolution = 30000.0;          // Time for evolution phase of simulations
double max_gtime_LastOfUs = 20000.0;              // Maximum for last of us phase of simulation
double dMaleRemovalTime = 100.0;                  // every this time unit males are removed
double dLarvalRemovalTime = 100.0;                // every this time unit dead larvae are removed
double dOutputTimeInterval = 1000.0;              // population state output time interval
const unsigned int max_nests_evolution = 1000;    // Maximum number of nests
const unsigned int max_nests_LastOfUs = 25;       // Max number of nests in LastOfUs

double dInitDispersal = -5.0;          // Initial value of the dispersal gene
// Logistic expression looks like 1/(1+exp(a+b*x))
bool bIsTimeUnit = true;            // Tells if the brooding and foraging time is singular
                                    // if false; then is taken from a distribution
bool bIsAdditive = false;            // gene expression is additive if true, otherwise only one is expressed
bool bRecombLocus = false;           // 0.5 recombination chance of each locus of every gene if true
                                    // else recombination is genewise
struct params {

    params() {};

    params(const std::string& file_name) {
        read_parameters_from_ini(file_name);
    }
    
    // Below are the default values for parameters to be read from config file
    double dLarvaMatureSize = 1.0;      // Hard maturation threshhold for bodysize

    double dForagingTime = 3.0;         // Time it takes for foraging
    double dBroodingTime = 4.0;         // Time it takes for brooding
    double dForagingTimeSD = 0.2;         // Time it takes for foraging
    double dBroodingTimeSD = 0.2;         // Time it takes for brooding
    
    double dTransitionForagingBrooding = 1.5;   // Time for transitioning from foraging to brooding
    double dTransitionBroodingForaging = 1.5;   // Time for transitioning from brooding to foraging
    double dSurvTransitionForagingBrooding = 0.99;  // Survival when transitioning foraging to brooding
    double dSurvTransitionBroodingForaging = 0.99;  // Survival when transitioning brooding to foraging
    
    double dDeathTime = 2.0;            // Time it takes for death
    double dMaleLambda = 0.1;          // 1/Average lifespan of male
    double dLarvaeLambda = 0.01;         // Average lifespan of larva LD

    double dMutRate = 0.01;             // Mutation probability
    double dMutBias = 0.0;              // Mutation Bias
    double dMutEffect = 0.02;           // Mutation effect

    double dSurvForage = 0.98;           // Survival probability for foraging of all bees
    double dSurvBrood = 0.99;            // Survival probability for reproduction of all bees
    double dForagingMean = 0.5;         // Mean of normal foraging curve
    double dForagingSD = 0.2;           // SD of normal foraging curve
    double const_sex_ratio = 0.5;       // male sex ratio
    
    std::string temp_params_to_record;
    std::vector < std::string > param_names_to_record;
    std::vector < float > params_to_record;
    
    void read_parameters_from_ini(const std::string& file_name) {
        ConfigFile from_config(file_name);

        dLarvaMatureSize               = from_config.getValueOfKey<double>("dLarvaMatureSize");
        dForagingTime                 = from_config.getValueOfKey<double>("dForagingTime");
        dBroodingTime                 = from_config.getValueOfKey<double>("dBroodingTime");
        dForagingTimeSD                 = from_config.getValueOfKey<double>("dForagingTimeSD");
        dBroodingTimeSD                 = from_config.getValueOfKey<double>("dBroodingTimeSD");
        dTransitionForagingBrooding   = from_config.getValueOfKey<double>("dTransitionForagingBrooding");
        dTransitionBroodingForaging   = from_config.getValueOfKey<double>("dTransitionBroodingForaging");
        dSurvTransitionForagingBrooding   = from_config.getValueOfKey<double>("dSurvTransitionForagingBrooding");
        dSurvTransitionBroodingForaging   = from_config.getValueOfKey<double>("dSurvTransitionBroodingForaging");
        dDeathTime                    = from_config.getValueOfKey<double>("dDeathTime");
        dMaleLambda                  = from_config.getValueOfKey<double>("dMaleLambda");
        dLarvaeLambda                  = from_config.getValueOfKey<double>("dLarvaeLambda"); //LD
        dMutRate                      = from_config.getValueOfKey<double>("dMutRate");
        dMutBias                      = from_config.getValueOfKey<double>("dMutBias");
        dMutEffect                    = from_config.getValueOfKey<double>("dMutEffect");
        dSurvForage                   = from_config.getValueOfKey<double>("dSurvForage");
        dSurvBrood                    = from_config.getValueOfKey<double>("dSurvBrood");
        dForagingMean                 = from_config.getValueOfKey<double>("dForagingMean");
        dForagingSD                   = from_config.getValueOfKey<double>("dForagingSD");
        const_sex_ratio               = from_config.getValueOfKey<double>("const_sex_ratio");
        temp_params_to_record         = from_config.getValueOfKey<std::string>("params_to_record");
        param_names_to_record         = split(temp_params_to_record);
        params_to_record              = create_params_to_record(param_names_to_record);
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
        if (s == "dLarvaMatureSize")               return dLarvaMatureSize;
        
        if (s == "dForagingTime")                 return dForagingTime;
        if (s == "dBroodingTime")                 return dBroodingTime;
        if (s == "dForagingTimeSD")               return dForagingTimeSD;
        if (s == "dBroodingTimeSD")               return dBroodingTimeSD;
        if (s == "dTransitionForagingBrooding")   return dTransitionForagingBrooding;
        if (s == "dTransitionBroodingForaging")   return dTransitionBroodingForaging;
        if (s == "dSurvTransitionForagingBrooding")   return dSurvTransitionForagingBrooding;
        if (s == "dSurvTransitionBroodingForaging")   return dSurvTransitionBroodingForaging;
        if (s == "dDeathTime")                    return dDeathTime;
        if (s == "dMaleLambda")                   return dMaleLambda;
        if (s == "dLarvaeLambda")                 return dLarvaeLambda; //LD

        if (s == "dMutRate")                      return dMutRate;
        if (s == "dMutBias")                      return dMutBias;
        if (s == "dMutEffect")                    return dMutEffect;

        if (s == "dSurvForage")                   return dSurvForage;
        if (s == "dSurvBrood")                    return dSurvBrood;
        if (s == "dForagingMean")                 return dForagingMean;
        if (s == "dForagingSD")                   return dForagingSD;
        if (s == "const_sex_ratio")               return const_sex_ratio;
        // ADD PARAMS TO RECORD
        throw std::runtime_error("can not find parameter");
        return -1.f; // FAIL
    }
};

#endif /* Parameters_hpp */
