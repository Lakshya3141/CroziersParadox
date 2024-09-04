#include "Random.hpp"
#include <iostream>

int main() {
    // Test bernoulli distribution
    std::cout << "Bernoulli distribution: " << bernoulli(0.1) << std::endl;
    std::cout << "Bernoulli distribution: " << bernoulli(0.1) << std::endl;
    std::cout << "Bernoulli distribution: " << bernoulli(0.1) << std::endl;
    std::cout << "Bernoulli distribution: " << bernoulli(0.1) << std::endl;
    std::cout << "Bernoulli distribution: " << bernoulli(0.1) << std::endl;
    std::cout << "Bernoulli distribution: " << bernoulli(0.1) << std::endl;

    // Test normal distribution
    std::cout << "Normal distribution: " << normal(0.0, 1.0) << std::endl;

    // Test uniform integer distribution
    std::cout << "Uniform integer distribution: " << uni_int(1, 10) << std::endl;

    // Test uniform real distribution
    std::cout << "Uniform real distribution: " << uni_real(0.0, 1.0) << std::endl;

    // Test binomial distribution
    std::cout << "Binomial distribution: " << binom(10, 0.5) << std::endl;

    // Test exponential distribution
    std::cout << "Exponential distribution: " << exponential(1.0) << std::endl;

    // Test logistic function
    std::cout << "Logistic function: " << logistic(0.0) << std::endl;

    // Test remove_from_vec function
    std::vector<int> vec = {1, 2, 3, 4, 5};
    remove_from_vec(vec, 2);
    std::cout << "Vector after removing element at index 2: ";
    printVector(vec);

    // Test randomSubset function
    std::vector<int> individuals = {1, 2, 3, 4, 5};
    std::vector<int> subset = randomSubset(individuals, 2);
    std::cout << "Random subset: ";
    printVector(subset);

    // Test calculateAverage function
    std::vector<double> values = {1.0, 2.0, 3.0, 4.0, 5.0};
    std::cout << "Average: " << calculateAverage(values) << std::endl;

    // Test mean_std function
    auto result = mean_std(values);
    std::cout << "Mean: " << std::get<0>(result) << ", Standard Deviation: " << std::get<1>(result) << std::endl;

    // Test mean function
    std::cout << "Mean: " << mean(values) << std::endl;

    // Test standard_deviation function
    std::cout << "Standard Deviation: " << standard_deviation(values) << std::endl;

    // Test covariance function
    std::vector<double> y = {2.0, 3.0, 4.0, 5.0, 6.0};
    std::cout << "Covariance: " << covariance(values, y) << std::endl;

    return 0;
}
