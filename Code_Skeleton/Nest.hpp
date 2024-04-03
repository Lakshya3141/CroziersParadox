//
//  Nest.hpp
//  OGH_Eusociality
//
//  Created by Lakshya Chauhan on 02/10/2023.
//  Copyright © 2023 Lakshya Chauhan. All rights reserved.
//  defines nest properties, associated functions
//  Also contains output function for individuals during lastOfUs
//

#ifndef Nest_hpp
#define Nest_hpp    

#include "Individual.hpp"
#include <algorithm>

class Nest {
public:
    Nest(const Individual<2>& f, const int nid) ;
    // Nest functions, self explanatory broadly, detailed explanation given above function definition
    std::tuple<bool, bool, size_t> feed_ld(const double& mean, const double& SD);
    void reproduce(Individual<2>& female, const int id, const params& p);
    void task_check(const Eigen::MatrixXd& tmp_matrix, Individual<2>& current, const params& p);
    size_t findFemaleIndexById(const int id);
    void mate_withinNest(Individual<2>& female);
    std::tuple<bool, size_t> choose_RndmMaleLarva();

    // Output function for LastOfUs
    void printIndividualEventCSV(const std::vector< float >& param_values, std::ostream& csv_file, const Individual<2>& current, const Individual<2>& recent, const unsigned long int event);

    // Nest variables
    unsigned int nest_id;
    std::vector<Individual<2> > adult_females;          // vector of adult females, [0] = breeder
    std::vector<Individual<2> > larval_females;         // vector to store larval females
    std::vector<Individual<1> > larval_males;           // vector to store larval males
};

// Feed function, feed random larva if found, returns index and sex of larva fed
// < is there any larvae fed, female == true, index of larvae fed > : Structure of tuple returned from feed function
std::tuple<bool, bool, size_t> Nest::feed_ld(const double& mean, const double& SD) {

    // resource collected through one foraging trip
    double resources = normal(mean, SD);
    if (resources < 0.0) resources = 0.0;

    // confirm presence of larvae
    while ((larval_males.size() + larval_females.size()) > 0){
        // take weighted probabilities
        double maleProbability = static_cast<double>(larval_males.size()) / (larval_males.size() + larval_females.size());
        if (bernoulli(maleProbability)) {
            // take random male larva to feed
            size_t ind = uni_int(0, larval_males.size());
            if (larval_males[ind].td_larva < gtime) {
                remove_from_vec(larval_males, ind);
            } else {
                larval_males[ind].body_size += resources;
                return std::make_tuple(true, false, ind);
            }
        } else {
            // take random female larva to feed
            size_t ind = uni_int(0, larval_females.size());
            if (larval_females[ind].td_larva < gtime) {
                remove_from_vec(larval_females, ind);
            } else {
                larval_females[ind].body_size += resources;
                return std::make_tuple(true, true, ind);
            }
        }
    }
    return std::make_tuple(false, true, 0);
}

// Nest constructor from breeder and Nest ID
Nest::Nest(const Individual<2>& f, const int nid) : nest_id(nid) {
    adult_females.push_back(f);
} // Constructor for nest

// produces males if not mated or with bernoulli(male sex ratio)
void Nest::reproduce(Individual<2>& female, const int id, const params& p) {
    if (female.is_mated) {
        // offspring sex depends on paramaters if mated
        if (bernoulli(p.const_sex_ratio)) {
            larval_males.emplace_back(id, female, p);
        } else {
            larval_females.emplace_back(id, female, p);
            female.num_female_larva++;      // increment female num larvae if female offspring
        }
    } else {
        // offsprings are haploid (male) if not mated
        larval_males.emplace_back(id, female, p);
    }
    female.num_larva++;                     // increment total larvae regardless
}

// choose next task of individual based on logistic funtion and phenotype choice.
void Nest::task_check(const Eigen::MatrixXd& tmp_matrix, Individual<2>& current, const params& p) {

    size_t total_larvae = larval_females.size() + larval_males.size();
    
    // Ensure num of larvae in nest is < 500, 
    // as that's the max effect allowed by our spline definition
    if (total_larvae > MaxLarvaeSpline) {
        total_larvae = MaxLarvaeSpline;
    } 
    
    current.previous_task_is_forager = current.is_foraging;
    
    // Evaluate spline at current larval levels for foraging propensity
    double foraging_propensity = evaluate_spline2d(tmp_matrix, current.choice_phenotype, n_resolution, total_larvae/(double)MaxLarvaeSpline);
    if (bernoulli(logistic(foraging_propensity))) {
        current.is_foraging = true;
    } else {
        current.is_foraging = false;
    }
    
    // Edit next time task dependent on discrete or continuous nature of time
    if (bIsTimeUnit) {
        current.t_next = current.t_next + (current.is_foraging ? p.dForagingTime : p.dBroodingTime) + (current.previous_task_is_forager and !current.is_foraging ? p.dTransitionForagingBrooding : 0) + (!current.previous_task_is_forager and current.is_foraging ? p.dTransitionBroodingForaging : 0);
    } else {
        double dum_fora = normal(p.dForagingTime, p.dForagingTimeSD);
        double dum_brood = normal(p.dBroodingTime, p.dForagingTimeSD);
        if (dum_fora < 0) dum_fora = 0;
        if (dum_brood < 0) dum_brood = 0;
        current.t_next = current.t_next + (current.is_foraging ? dum_fora : dum_brood) + (current.previous_task_is_forager and !current.is_foraging ? p.dTransitionForagingBrooding : 0) + (!current.previous_task_is_forager and current.is_foraging ? p.dTransitionBroodingForaging : 0);
    }

}

// Function to search by indidivual ID in a nest and return index
size_t Nest::findFemaleIndexById(const int id) {
    auto it = std::find_if(adult_females.begin(), adult_females.end(), [id](const Individual<2>& ind) {
        return ind.ind_id == id;
    });
    if (it != adult_females.end()) {
        return std::distance(adult_females.begin(), it);
    } else {
        // Return some sentinel value  to indicate not found
        return -1;
    }
}

// LastOfUs
// Mates females with one of the larval males
// LC : I DONT THINK WE HAVE USED THIS???
void Nest::mate_withinNest(Individual<2>& female) {
    std::tuple<bool, size_t> index_tuple = choose_RndmMaleLarva();
    if (std::get<0>(index_tuple)){
        female.mate(larval_males[std::get<1>(index_tuple)]);
    }
}

// Last of Us
// returns index of selected random larval male
// LC : I DONT THINK WE HAVE USED THIS???
std::tuple<bool, size_t> Nest::choose_RndmMaleLarva(){
    if (larval_males.size() != 0) {
        size_t index = uni_int(0, larval_males.size());
        return std::make_tuple(true, index);
    }
    else return std::make_tuple(false, 0);
}

// Output Function for LastOfUs output
void Nest::printIndividualEventCSV(const std::vector< float >& param_values, std::ostream& csv_file, const Individual<2>& current, const Individual<2>& recent, const unsigned long int event) {
    
    for (auto i : param_values) {
      csv_file << i << ',';
    }
    
    csv_file << event << "," << gtime << "," << current.nest_id << "," << current.ind_id << ","
              << current.mom_id << "," << current.dad_id << "," << current.is_mated << ","
              << current.mate_id << "," << current.is_foraging << "," << recent.is_foraging << ","
              << current.num_choices << "," << current.num_foraging << ","
              << current.num_female_larva << "," << current.num_larva << "," << current.t_birth << ","
              << current.is_alive << "," << current.t_death << "," << current.phenotype_dispersal << ","
              << larval_females.size() << "," << larval_males.size() << "," << adult_females.size();
    
    for (int i = 0; i < n_knots; i++) {
        csv_file << "," << current.choice_phenotype(i, 0); 
    }

    csv_file << "\n";
    csv_file.flush();
}   

#endif /* Nest_hpp */
