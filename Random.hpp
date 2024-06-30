//
//  CroziersParadox
//
//  Created by Lakshya Chauhan on 03/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  -> This script contains random and stochasticity based functions  
//  Pt 1
#ifndef Random_hpp
#define Random_hpp

#include <random>
#include <chrono>
#include <array>
#include <vector>
#include <cmath>
#include <iostream>
#include <string>
#include <algorithm>
#include <tuple>
#include <numeric>

unsigned int simulationID = static_cast<unsigned int>(std::chrono::high_resolution_clock::now().time_since_epoch().count()); // sample a seed
std::mt19937 rn(simulationID); // seed the random number generator

// bernoulli distribution (default p=0.5)
bool bernoulli(double p=0.5) { return std::bernoulli_distribution(p)(rn); }

// normal distribution
double normal(double mean, double sd) { return std::normal_distribution<double>(mean, sd)(rn); }

// uniform integer distribution
template<typename T1, typename T2>
T2 uni_int(T1 lower, T2 upper) { return std::uniform_int_distribution<T2>(lower, upper - 1)(rn); }

// uniform real distribution (default limits 0-1)
double uni_real(double lower = 0.0, double upper = 1.0) { return std::uniform_real_distribution<double>(lower, upper)(rn); }

// binomial distribution
int binom(int n, double p) { return std::binomial_distribution<int>(n,p)(rn); }

// exponential distribution
double exponential(double lambda) {
    return std::exponential_distribution<double>(lambda)(rn);
}

// logistic function
template <typename T>
double logistic(T x, double intercept = 0.0, double slope = 1.0) {
    return 1 / (1 + exp(intercept + static_cast<double>(x) * slope));
}

// function that removes objects from a vector
template <typename T = double>
void remove_from_vec(std::vector<T>& v, const size_t idx) {
    auto back_idx = v.size()-1;
    if (idx != back_idx) v[idx] = std::move(v[back_idx]);
    v.pop_back();
}

// Function to randomly select alpha number of individuals
template <typename T>
std::vector<T> randomSubset(const std::vector<T>& individuals, int alpha) {
    // Copy the vector to avoid modifying the original vector
    std::vector<T> result = individuals;

    if (alpha >= individuals.size()) {
        // Shuffle the entire vector if alpha is greater or equal to the vector size
        std::shuffle(result.begin(), result.end(), rn);
        return result;
    }

    // Shuffle the vector to randomize the selection
    std::shuffle(result.begin(), result.end(), rn);

    // Resize the vector to contain only alpha elements
    result.resize(alpha);

    return result;
}

int chooseProbableIndex(const std::vector<double>& probabilities) {
    if (probabilities.empty()) {
        throw std::invalid_argument("The input vector must not be empty.");
    }

    // Calculate the total sum of the probabilities
    double total = std::accumulate(probabilities.begin(), probabilities.end(), 0.0);

    if (total <= 0) {
        throw std::invalid_argument("The sum of probabilities must be positive.");
    }

    // Create a cumulative distribution
    std::vector<double> cumulative(probabilities.size());
    std::partial_sum(probabilities.begin(), probabilities.end(), cumulative.begin());

    // Normalize the cumulative distribution
    for (double& value : cumulative) {
        value /= total;
    }

    // Generate a random number between 0 and 1
    double randomValue = uni_real();

    // Find the index corresponding to the random value
    auto it = std::lower_bound(cumulative.begin(), cumulative.end(), randomValue);
    return std::distance(cumulative.begin(), it);
}

// Function to calculate Shannon's diversity index
double calculateShannonDiversity(const std::vector<std::vector<double>>& antProfiles) {
    int numAnts = antProfiles.size();
    if (numAnts == 0) return 0.0;
    
    int numCues = antProfiles[0].size();
    std::vector<double> totalConcentrations(numCues, 0.0);
    
    // Sum up concentrations for each cue across all ants
    for (const auto& profile : antProfiles) {
        for (int j = 0; j < numCues; ++j) {
            totalConcentrations[j] += profile[j];
        }
    }
    
    // Calculate the total sum of all cues
    double totalSum = 0.0;
    for (double concentration : totalConcentrations) {
        totalSum += concentration;
    }
    
    // Calculate the proportions and then the diversity index
    double diversityIndex = 0.0;
    for (double concentration : totalConcentrations) {
        if (concentration > 0) {
            double proportion = concentration / totalSum;
            diversityIndex -= proportion * std::log(proportion);
        }
    }
    
    return diversityIndex;
}

// Function to calculate Simpson's diversity index
double calculateSimpsonDiversity(const std::vector<std::vector<double>>& antProfiles) {
    int numAnts = antProfiles.size();
    if (numAnts == 0) return 0.0;

    int numCues = antProfiles[0].size();
    std::vector<double> totalConcentrations(numCues, 0.0);

    // Sum up concentrations for each cue across all ants
    for (const auto& profile : antProfiles) {
        for (int j = 0; j < numCues; ++j) {
            totalConcentrations[j] += profile[j];
        }
    }

    // Calculate the total sum of all cues
    double totalSum = 0.0;
    for (double concentration : totalConcentrations) {
        totalSum += concentration;
    }

    // Calculate the proportions and then the diversity index
    double sumProportionsSquared = 0.0;
    for (double concentration : totalConcentrations) {
        if (concentration > 0) {
            double proportion = concentration / totalSum;
            sumProportionsSquared += proportion * proportion;
        }
    }

    double diversityIndex = 1.0 - sumProportionsSquared;
    return diversityIndex;
}

// Function to calculate Bray-Curtis distance between two ant profiles
double calculateBrayCurtisDistance(const std::vector<double>& profile1, const std::vector<double>& profile2) {
    double sumDifferences = 0.0;
    double sumTotals = 0.0;

    for (size_t i = 0; i < profile1.size(); ++i) {
        sumDifferences += std::min(profile1[i],profile2[i]);
        sumTotals += (profile1[i] + profile2[i]);
    }

    return 1 - 2*sumDifferences/sumTotals;
}

// Function to calculate pairwise Bray-Curtis distances and return the average and std deviation
std::tuple<double, double> calculatePairwiseBrayCurtis(const std::vector<std::vector<double>>& antProfiles) {
    std::vector<double> distances;
    
    for (size_t i = 0; i < antProfiles.size(); ++i) {
        for (size_t j = i + 1; j < antProfiles.size(); ++j) {
            double distance = calculateBrayCurtisDistance(antProfiles[i], antProfiles[j]);
            distances.push_back(distance);
        }
    }
    
    return mean_std(distances);
}

// dummy print function for debugging
void print(){
    std::cout << "DUMMY" << std::endl;
}

// dummy print function for debugging
void print_spec(const std::string& str){
    std::cout << str << std::endl;
}

// dummy print function for debugging
void print_spec(const char* str) {
    std::cout << str << std::endl;
}

// dummy print vector function for debugging
template <typename T>
void printVector(const std::vector<T>& vec) {
    std::cout << "[ ";
    for (const auto& element : vec) {
        std::cout << element << " ";
    }
    std::cout << "]\n";
}

// LC: Some of the functions may be a bit repetitive, cleaning throughout might be an issue
// I dont think it has any significant effect

// Function template to calculate the average of a vector of any numeric type
template <typename T>
T calculateAverage(const std::vector<T>& values) {
    if (values.empty()) {
        // Handle the case where the vector is empty to avoid division by zero
        std::cerr << "Error: Cannot calculate average of an empty vector." << std::endl;
        return T();
    }
    // Calculate the sum of all elements in the vector
    T sum = T();
    for (const auto& value : values) {
        sum += static_cast<double>(value); // Typecast value to double
    }
    // Calculate the average
    return sum / static_cast<double>(values.size());
}

// Function template to calculate the mean and standard deviation of a vector of any numeric type
template <typename T>
std::tuple<double, double> mean_std(const std::vector<T>& data) {
    double mean = calculateAverage(data);
    double std_dev = 0.0;
    for (const auto& value : data) {
        std_dev += std::pow(static_cast<double>(value) - mean, 2);
    }
    std_dev = std::sqrt(std_dev / static_cast<double>(data.size()));
    return std::make_tuple(mean, std_dev);
}

// stats functions
double mean(const std::vector<double>& x) {
    return std::accumulate(begin(x),end(x),0.0)/static_cast<double>(x.size());
}

double standard_deviation(const std::vector<double>& x) {
    double ss{std::inner_product(begin(x),end(x),begin(x),0.0)};
    double m{mean(x)};
    return sqrt(ss/static_cast<double>(x.size())-m*m);
}

double covariance(const std::vector<double>& x, const std::vector<double>& y) {
    double ss{std::inner_product(begin(x),end(x),begin(y),0.0)};
    double mx{mean(x)};
    double my{mean(y)};
    return ss/static_cast<double>(x.size())-mx*my;
}

#endif /* Random_hpp */