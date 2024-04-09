//
//  Population.hpp
//  OGH_Eusociality
//
//  Created by Lakshya Chauhan on 02/10/2023.
//  Copyright © 2023 Lakshya Chauhan. All rights reserved.
//  Defines population functions, simulations and outputs
//

#ifndef Population_hpp
#define Population_hpp    

#include "Nest.hpp"
#include <queue>
#include <iomanip> // For std::setprecision
#include <sstream> // For std::ostringstream
#include <numeric>
#include <filesystem>

namespace fs = std::filesystem;

// track_time struct for event queue ordered by next task time
struct track_time {
    double time;
    unsigned int nest_id;
    int ind_id;

    // event constructor using initializer lists
    track_time(const Individual<2>& input) :
        time{input.t_next},
        nest_id{input.nest_id},
        ind_id{input.ind_id}
    {}
};

class Population {
public:
    Population(const params& par) : p(par) { };
    std::vector<Individual<1> > adult_males;        // vector for adult males to fertilize female
    std::vector<Nest> nests;
    std::vector<size_t> empty_nests;                // vector to store empty nest IDS.
    std::vector<unsigned int> storer_nest_id;       // vector to store nest IDs corresponding to nest indexes

    void initialise_pop();                          // Initialise populations
    std::tuple<bool, unsigned int> update_emptyNests(); // updates emty_nests list and returns empty nest ID
    void mate(Individual<2>& female);               // mates a female with a random male from adult_males
    std::tuple<bool, size_t> choose_RndmMale();     // function to choose random male for mating
    void removeDeadMales();                         // to remove dead males
    void removeDeadLarva();                         // LD to remove dead larva
    int findIndexByNestId(unsigned int nestId);     // returns index of Nest ID in nests vector

    void simulate_tst(const std::vector<std::string>& param_names);      // simulate function for evolution period
    Population initialise_LastOfUs();   // initialise the last of us generation 
    void simulate_LastOfUs(const std::vector<std::string>& param_names); // Simulate LastOfUs
    // add row of data to population state file
    void printPopulationState(const std::vector< float >& param_values, std::ostream& csv_file, const unsigned long int event);  
    // add row of data to deadIndividual file
    void printDeadIndividualData(const std::vector< float >& param_values, std::ostream& csv_file); 

    // Outputs basis matrix for this simulation
    void writeBasisMatrix();

    unsigned int nest_id_counter = 0;               // nest ID counter 
    unsigned int individual_id_counter = 0;         // individual ID counter
    
    // Initialises basis matrix once for this round of simulation and parameters
    Eigen::MatrixXd basis_matrix_choice{ make_spline2d(n_knots, n_resolution, 0.0, 1.0) };
    params p;

private:
    // Self explanatory variables, indicate last time since removal/output happened
    double last_dead_male_removal_time = 0.0;
    double last_dead_larval_removal_time = 0.0;
    double last_evolution_time = 0.0;
    double last_deadInd_time = 0.0;
    // Collects deadIndividual data
    // Fraction of dead individuals collected to reduce output size
    double frac_ind_dot_plot = 0.0005;

    // vectors, where each row is an individual that died and was accepted for data output
    // with bernoulli (frac_ind_dot_plot). The tuple is of the format
    // gtime, pertime_foraging, pertask_foraging,  num_choices, nest_id
    std::vector<std::tuple<double, double, double, double, unsigned int, double> > deadInd_data;
    // similar vector for geneData
    std::vector< Eigen:: Matrix<double, n_knots, 1> > deadInd_geneData;  
};

// Lambda function for maintaining priority queue
auto cmptime = [](const track_time& a, const track_time& b) { return a.time > b.time; };

// initialise population function
void Population::initialise_pop() {
    // clear vectors

    // starting with one adult male
    Individual<1> adam(individual_id_counter);
    ++individual_id_counter;
    adult_males.push_back(adam);
    
    for(int i=0; i < max_nests_evolution; ++i) {
        // initalise each nest with breeder female and mate with adam
        Individual<2> eve(individual_id_counter);
        ++individual_id_counter;
        eve.mate(adam);

        // change nest ID values in 
        eve.nest_id = nest_id_counter;
        storer_nest_id.push_back(i);
        eve.t_next = uni_real();                // impart asynchronous acting time
        eve.is_foraging = false;                // set breeder
        ++nest_id_counter;                      
        nests.emplace_back(eve, eve.nest_id);
    }
}

// Function to find index of a particular Nest ID in nests vector
// By searching in the storer nest ID vector 
int Population::findIndexByNestId(unsigned int nestId) {
        auto it = std::find(storer_nest_id.begin(), storer_nest_id.end(), nestId);
        if (it != storer_nest_id.end()) {
            return static_cast<int>(std::distance(storer_nest_id.begin(), it));
        } else {
            return -1;  // Return -1 if nest_id is not found
        }
    }

// Simulate function for initalised population
void Population::simulate_tst(const std::vector<std::string>& param_names) {
    // Create a priority queue to track individuals by their next action time
    std::priority_queue<track_time, std::vector<track_time>, decltype(cmptime)> event_queue(cmptime);
    // Initialize the event queue with individuals and their initial next action times
    for (auto& nest : nests) {
        for (auto& individual : nest.adult_females) {
            event_queue.push(track_time(individual));
        }
    }

    fs::path evolutionPath = fs::path("./output_sim/" + std::to_string(simulationID) + "_evolution.csv");
    std::ofstream evolution_file(evolutionPath);

    fs::path deadindPath = fs::path("./output_sim/" + std::to_string(simulationID) + "_deadIndividuals.csv");
    std::ofstream di_file(deadindPath);
    
    for (auto i : param_names) {
        evolution_file << i << ',';
        di_file << i << ',';
    }

    evolution_file << "gtime,event,dispersal_avg,dispersal_std,num_female,num_male,fem_avg,fem_std,femLarv_avg,femLarv_std,malLarv_avg,malLarv_std,totLarv_avg,totLarv_std,relatedness";

    // Add headers for beta averages and standard deviations
    for (int beta_index = 0; beta_index < n_knots; ++beta_index) {
        evolution_file << ",beta" << beta_index << "_avg,beta" << beta_index << "_std";
    }

    evolution_file << std::endl;
    evolution_file.flush();

    di_file << "gtime,pertime_foraging,num_foraging,num_choices,nest_id,dispersal";
    
    // Add headers for beta averages and standard deviations
    for (int beta_index = 0; beta_index <= n_knots; ++beta_index) {
        di_file << ",beta" << beta_index;
    }
    di_file << std::endl;
    di_file.flush();
    writeBasisMatrix();
    unsigned long int event = 0;

    // Simulate till max_gtime_evolution
    while (gtime < max_gtime_evolution) {

        if (event_queue.empty()) {
            // No more events to process
            std::cout << "ERROR: event_queue empty" << std::endl;
            break;
        }

        // Call remove DeadMales and larva every time 
        removeDeadMales();
        removeDeadLarva();

        // output
        printPopulationState(p.params_to_record, evolution_file, event);
        printDeadIndividualData(p.params_to_record, di_file);
        // Get the individual with the earliest next action time, pop it from queue
        // find nest index (cnestid) based on event's nest ID and individual ID (cindid)
        // Find index of current indidvidual in it's respective next
        track_time next_event = event_queue.top();
        event_queue.pop();
        size_t cnestid = findIndexByNestId(next_event.nest_id);
        auto cindid = next_event.ind_id;
        auto current_index = nests[cnestid].findFemaleIndexById(cindid);

        // dummy current to hold old variable values for current individual
        auto current = nests[cnestid].adult_females[current_index];

        // Update Gtime to current task time
        gtime = current.t_next;

        // Last task survival check
        if (current.is_alive) { // If individual survived till now
            if (current.is_foraging) {  // And old task is foraging

                // Feed random larva and also get it's gender and index
                std::tuple<bool, bool, size_t> index = nests[cnestid].feed_ld(p.dForagingMean, p.dForagingSD);

                if (std::get<0>(index) == true) {       // If feed successful
                    if (std::get<1>(index) == false) {  // if male
                        // Check if larva matures after feeding
                        Individual<1>& m{nests[cnestid].larval_males[std::get<2>(index)]};
                        if (m.check_mature(gtime, p)) {
                            
                            // Push mature larva to adult males vector
                            adult_males.push_back(m);
                            remove_from_vec(nests[cnestid].larval_males, std::get<2>(index));
                            
                        } 
                    } else { // if female
                        // Check mature
                        Individual<2>& f{nests[cnestid].larval_females[std::get<2>(index)]};                    
                        if (f.check_mature(gtime, p)) {
                            // Check if disperser
                            if (f.check_disperser()) {
                                // If diserpser, mate larva
                                mate(f);

                                // Get Empty nest ID and it's index in nests vector
                                auto empty = update_emptyNests();
                                size_t empty_index = findIndexByNestId(std::get<1>(empty));
                                
                                if (std::get<0>(empty) == true) {       // If empty nest found
                                    
                                    Nest& new_nest{nests[empty_index]};

                                    // Push to adult females vector in empty nest and delete
                                    // from old larval vector
                                    new_nest.adult_females.push_back(f);
                                    remove_from_vec(nests[cnestid].larval_females, std::get<2>(index));

                                    // Since new colony, remove older larvae
                                    new_nest.larval_females.clear();
                                    new_nest.larval_males.clear();
                                    
                                    // Update t_next before task check
                                    Individual<2>& breeder{new_nest.adult_females[0]};
                                    breeder.t_next = gtime;
                                    new_nest.task_check(basis_matrix_choice, current, p);

                                    // Update ID of new nest, new individual and storer_nest_id vector
                                    breeder.nest_id = nest_id_counter;
                                    storer_nest_id[empty_index] = nest_id_counter;
                                    new_nest.nest_id = nest_id_counter;
                                    nest_id_counter++;
                                    // Push mature disperser to queue
                                    event_queue.push(track_time(breeder));
                                    
                                } else {
                                    // If not disperser
                                    // erase larva
                                    remove_from_vec(nests[cnestid].larval_females, std::get<2>(index));
                                }
                            } else { // else if not disperser
                                
                                mate(f);        // Mate female on maturing

                                // Add to adult females and remove from larval females
                                nests[cnestid].adult_females.push_back(f);
                                remove_from_vec(nests[cnestid].larval_females, std::get<2>(index));

                                // Update gtime and check task
                                nests[cnestid].adult_females.back().t_next = gtime;
                                nests[cnestid].task_check(basis_matrix_choice, nests[cnestid].adult_females.back(), p);
                                
                                // Push to queue
                                event_queue.push(track_time(nests[cnestid].adult_females.back()));
                            }
                        }
                    }
                }
            } else { // old task is reproducing

                // reproduce
                nests[cnestid].reproduce(nests[cnestid].adult_females[current_index], individual_id_counter, p);
                ++individual_id_counter;
            
            }
            Individual<2>& cf{nests[cnestid].adult_females[current_index]};
            // Increment num_choice and num_forag
            cf.num_choices++;
            if (cf.is_foraging) {
                cf.num_foraging++;
            }
            // Task check for current female, followed by survival check
            nests[cnestid].task_check(basis_matrix_choice, cf, p);
            cf.survival(p);
            // push current individual back to queue
            event_queue.push(track_time(cf));
        
        } // Death condition 
        else {
            // sampling dead individuals for the output deadIndividual file
            if (bernoulli(frac_ind_dot_plot)) {
                // gtime, pertime_foraging, pertask_foraging,  num_choices, nest_id
                current.num_choices = static_cast<double>(current.num_choices);
                current.num_foraging = static_cast<double>(current.num_foraging);
                double tot_time = p.dForagingTime*current.num_foraging + (p.dBroodingTime*(current.num_choices - current.num_foraging));
                double pertime_foraging = p.dForagingTime*current.num_foraging / (tot_time);
                // double pertask_foraging = static_cast<double>(current.num_foraging)/static_cast<double>(current.num_choices)*100.0;
                auto dummy = std::make_tuple(current.t_next, pertime_foraging, current.num_foraging, current.num_choices, current.nest_id, current.phenotype_dispersal);
                deadInd_data.push_back(dummy);
                deadInd_geneData.push_back(current.choice_phenotype);
            }

            remove_from_vec(nests[cnestid].adult_females, current_index);
        }

        event++;
    }
    evolution_file.close();
    di_file.close();
}


// // Simulate just one generation as per output testing discussed
Population Population::initialise_LastOfUs() {

    bool to_clear = false;

    // Vector to store disperser adults
    std::vector<Individual<2> > disperser_females;
    std::vector<Individual<1> > all_males;
    std::vector<Individual<1> > newPop_males;

    // Record important data
    std::array<int, max_nests_evolution> num_adultFemales;
    int num_adultMales = adult_males.size();
    
    for (int nind = 0; nind < max_nests_evolution; nind++) {
        num_adultFemales[nind] = nests[nind].adult_females.size();
        if (to_clear) nests[nind].adult_females.clear();            // empty adult female vectors

        for (auto& fem_larva : nests[nind].larval_females) {
            fem_larva.is_larva = false;
            // If disperser, add to final females vector
            if (fem_larva.check_disperser()){
                fem_larva.t_next = uni_real();      // Asynchrounous start applied
                fem_larva.is_foraging = false;      // set breeder
                fem_larva.mom_id = -1;
                fem_larva.dad_id = -1;
                fem_larva.mate_id = -1;
                disperser_females.push_back(fem_larva);
            }
        }

        // Collect all males
        for (auto& male_larva : nests[nind].larval_males) {
            all_males.push_back(male_larva);
        }
        // Empty larval vectors
        if (to_clear) nests[nind].larval_females.clear();         
        if (to_clear) nests[nind].larval_males.clear();
    }
    
    std::vector<int> disperser_indices(disperser_females.size());        // Vector to store index of final selected dispersers
    std::iota(disperser_indices.begin(), disperser_indices.end(), 0);

    auto female_indices = randomSubset(disperser_indices, max_nests_LastOfUs);

    // Subset equal number of males as females available
    std::vector<int> allMale_indices(all_males.size());        // Vector to store index of final selected dispersers
    std::iota(allMale_indices.begin(), allMale_indices.end(), 0);

    auto male_indices = randomSubset(allMale_indices, female_indices.size());

    for (auto& index : male_indices){
        all_males[index].ind_id = -1;
        newPop_males.push_back(all_males[index]);
    }
    all_males.clear();


    // Initialise new population with selected females;
    Population newGen(p);
    // LCIMP No mutation happening in the Last of Us generation
    // Reduce mutational effect by a lot; effectively no mutation in the last of us
    newGen.p.dMutEffect = 0.00001;

    newGen.nests.clear();
    newGen.empty_nests.clear();

    gtime = 0.0;
    newGen.individual_id_counter = 0;
    newGen.nest_id_counter = 0;

    // Initialise newGen pop
    for (int index = 0; index < female_indices.size(); index++) {
        Individual<2> &current_female = disperser_females[female_indices[index]];
        Individual<1> &current_male = newPop_males[index];

        // Nest ID doesnt matter wrt previous population
        current_female.nest_id = newGen.nest_id_counter;
        // Individual ID for new population should function on it's individual counter
        current_female.ind_id = newGen.individual_id_counter;
        current_female.mate(current_male);
        newGen.storer_nest_id.push_back(newGen.nest_id_counter);

        // Add disperser individual to new nest
        newGen.nests.emplace_back(current_female, newGen.nest_id_counter);

        newGen.individual_id_counter++;
        newGen.nest_id_counter++;
    }
    return newGen;
}

// Function to simulate the last generation until death of all colonies or a certain event time period
void Population::simulate_LastOfUs(const std::vector<std::string>& param_names){
    // Create a priority queue to track individuals by their next action time
    std::priority_queue<track_time, std::vector<track_time>, decltype(cmptime)> event_queue(cmptime);

    // Initialize the event queue with individuals and their initial next action times
    for (auto& nest : nests) {
        for (auto& individual : nest.adult_females) {
            event_queue.push(track_time(individual));
        }
    }

    fs::path louPath = fs::path("./output_sim/" + std::to_string(simulationID) + "_LastOfUs.csv");
    std::ofstream lou_file(louPath);
    // TST add nest female size as well (larval vectors size also)
    
    for (auto i : param_names) {
        lou_file << i << ',';
    }
    
    lou_file << "event,gtime,nest_id,ind_id,mom_id,dad_id,is_mated,mate_id,current_foraging,next_foraging,num_choices,num_foraging,num_female_larva,num_larva,t_birth,is_alive,t_death,dispersal,num_femlarva,num_malelarva,num_adults";
    lou_file.flush();

    // Add headers for beta averages and standard deviations
    for (int beta_index = 0; beta_index < n_knots; ++beta_index) {
        lou_file << ",beta" << beta_index;
    }

    lou_file << std::endl;

    unsigned long int event = 0;

    while(gtime < max_gtime_LastOfUs) {
        
        if (event_queue.empty()) {
            // No more events to process
            std::cout << "ERROR: event_queue empty" << std::endl;
            break;
        }
        
        // call remove DeadMales every time 
        removeDeadMales();
        removeDeadLarva();
        

        // Get the individual with the earliest next action time, pop it from queue
        // Find index of current indidvidual in it's respective next
        track_time next_event = event_queue.top();
        event_queue.pop();
        size_t cnestid = next_event.nest_id;
        auto cindid = next_event.ind_id;
        auto current_index = nests[cnestid].findFemaleIndexById(cindid);

        // dummy current to hold old variable values for current individual
        auto current = nests[cnestid].adult_females[current_index];
        
        // Update Gtime to current task time
        gtime = current.t_next;
        Individual<2> recent = current;


        if (current.is_alive) { // If individual survived till now
            if (current.is_foraging) {  // And old task is foraging

                // Feed random larva and also get it's gender and index
                std::tuple<bool, bool, size_t> index = nests[cnestid].feed_ld(p.dForagingMean, p.dForagingSD);

                if (std::get<0>(index) == true) {       // If feed successful
                    if (std::get<1>(index) == false) {  // if male
                        // Check if larva matures after feeding
                        Individual<1>& m{nests[cnestid].larval_males[std::get<2>(index)]};
                        if (m.check_mature(gtime, p)) {
                            
                            // Push mature larva to adult males vector
                            adult_males.push_back(m);
                            remove_from_vec(nests[cnestid].larval_males, std::get<2>(index));
                        }
                    } else { // if female
                        // Check mature
                        Individual<2>& f{nests[cnestid].larval_females[std::get<2>(index)]};
                        if (f.check_mature(gtime, p)) {
                            // Check if disperser
                            if (f.check_disperser()) {
                                // If disperser just remove it
                                remove_from_vec(nests[cnestid].larval_females, std::get<2>(index));\

                            } else { // else if not disperser
                                
                                mate(f);        // Mate female on maturing

                                // Add to adult females and remove from larval females
                                nests[cnestid].adult_females.push_back(f);
                                remove_from_vec(nests[cnestid].larval_females, std::get<2>(index));
                                // Update gtime and check task
                                nests[cnestid].adult_females.back().t_next = gtime;
                                nests[cnestid].task_check(basis_matrix_choice, nests[cnestid].adult_females.back(), p);
                                
                                // Push to queue
                                event_queue.push(track_time(nests[cnestid].adult_females.back()));
                            }
                        }
                    }
                }
            } else { // old task is reproducing

                // reproduce
                nests[cnestid].reproduce(nests[cnestid].adult_females[current_index], individual_id_counter, p);
                ++individual_id_counter;
            }
            
            Individual<2>& cf{nests[cnestid].adult_females[current_index]};
            // Increment num_choice and num_forag
            cf.num_choices++;
            if (cf.is_foraging) {
                cf.num_foraging++;
            }
            // Task check for current female, followed by survival check
            nests[cnestid].task_check(basis_matrix_choice, cf, p);
            cf.survival(p);
            // push current individual back to queue
            event_queue.push(track_time(cf));

        
        } // Death condition 
        else {
            nests[cnestid].adult_females.erase(nests[cnestid].adult_females.begin() + current_index);
        }

        Individual<2>& cf{nests[cnestid].adult_females[current_index]};
        nests[current.nest_id].printIndividualEventCSV(p.params_to_record, lou_file, current, cf, event);
        event++;
    }
    lou_file.close();
}

// returns index of selected random male for mating
std::tuple<bool, size_t> Population::choose_RndmMale(){
    if (adult_males.size() != 0) {
        size_t index = uni_int(0, adult_males.size());
        return std::make_tuple(true, index);
    }
    else return std::make_tuple(false, 0);
}

// Mate female with random male if available
void Population::mate(Individual<2>& female){
    std::tuple<bool, size_t> index_tuple = choose_RndmMale();
    if (std::get<0>(index_tuple)){
        female.mate(adult_males[std::get<1>(index_tuple)]);
    }
}

// updates empty nest list and returns tuple of the form < if_empty, ID >
std::tuple<bool, unsigned int> Population::update_emptyNests() {
    empty_nests.clear();        // clear empty_nests vector

    for (size_t i = 0; i < nests.size(); ++i) {
        // add nest ID to vector if corrsesponding nest is empty
        if (!nests[i].adult_females.size()) {
            empty_nests.push_back(nests[i].nest_id);
        }
    }
    if (empty_nests.empty()) {
        return std::make_tuple(false, 0); // No empty nests found
    } else {
        size_t randomIndex = uni_int(0, empty_nests.size());    // random index chosen from empty_nests vector 
        return std::make_tuple(true, empty_nests[randomIndex]); // return random Nest ID that is empty
    }
}

// function to remove dead males based on t_death compared to gtime
void Population::removeDeadMales() {
    // Check if enough time has passed since the last removal
    if (gtime - last_dead_male_removal_time < dMaleRemovalTime) {
        return; // Skip removal if not enough time has passed
    }

    auto Condition = [](const Individual<1>& male) {
        return male.t_death <= gtime;
    };
    adult_males.erase(std::remove_if(adult_males.begin(), adult_males.end(), Condition), adult_males.end());

    // Update the last removal time
    last_dead_male_removal_time = gtime;
}

// function to remove dead larvae by comparing td_larva to gtime
// loops through nests
void Population::removeDeadLarva() {
    // Check if enough time has passed since the last removal
    if (gtime - last_dead_larval_removal_time < dLarvalRemovalTime) {
        return; // Skip removal if not enough time has passed
    }

    // separate lambda functions cause template + lambda was causing some issues
    auto cond_male = [](const Individual<1>& male) {
        return male.td_larva <= gtime;
    };
    auto cond_female = [](const Individual<2>& female) {
        return female.td_larva <= gtime;
    };

    // loop through nests removing dead larvae
    for (auto& nest : nests) {
        std::vector<Individual<2>>& lf = nest.larval_females;
        std::vector<Individual<1>>& lm = nest.larval_males;

        lf.erase(std::remove_if(lf.begin(), lf.end(), cond_female), lf.end());
        lm.erase(std::remove_if(lm.begin(), lm.end(), cond_male), lm.end());
    }


    // Update the last removal time
    last_dead_larval_removal_time = gtime;
}

// Write basis matrix used for this simulation
void Population::writeBasisMatrix() {

    fs::path basisPath = fs::path("./output_sim/" + std::to_string(simulationID) + "_basis.csv");
    std::ofstream basis_file(basisPath);


    for (int i = 0; i < basis_matrix_choice.rows(); ++i) {
        for (int j = 0; j < basis_matrix_choice.cols(); ++j) {
            basis_file << basis_matrix_choice(i, j) << ',';
        }
        basis_file << '\n';
    }
    basis_file.flush();

    basis_file.close();
}

// function to print population state compared to gtime
void Population::printPopulationState(const std::vector< float >& param_values, std::ostream& csv_file, const unsigned long int event) {
    // Check if enough time has passed since the last removal
    if (gtime - last_evolution_time < dOutputTimeInterval) {
        return; // Skip removal if not enough time has passed
    }
    
    for (auto i : param_values) {
      csv_file << i << ',';
    }
    
    csv_file << gtime << "," << event;
    
    std::vector<double> dispersal_values;
    std::vector<std::vector<double>> beta_values(n_knots, std::vector<double>());
    std::vector<int> fem_values;
    std::vector<int> femLarv_values;
    std::vector<int> malLarv_values;
    std::vector<int> totLarv_values;
    int total_females = 0;
    // Collect dispersal values for all females
    for (auto& nest : nests) {
        fem_values.push_back(nest.adult_females.size());
        femLarv_values.push_back(nest.larval_females.size());
        malLarv_values.push_back(nest.larval_males.size());
        total_females += nest.adult_females.size();
        totLarv_values.push_back(nest.larval_females.size() + nest.larval_males.size());

        for (auto& female : nest.adult_females) {
            dispersal_values.push_back(female.phenotype_dispersal);
            // Loop through betas and collect values
            for (int beta_index = 0; beta_index < n_knots; ++beta_index) {
                beta_values[beta_index].push_back(female.choice_phenotype(beta_index, 0));
            }
        }
    }

    // Calculate mean and standard deviation for choice intercept
    std::tuple<double, double> stat;

    stat = mean_std(dispersal_values);
    // Output mean and standard deviation to CSV
    csv_file << "," << std::get<0>(stat) << "," << std::get<1>(stat);

    // male and female size
    csv_file << "," << total_females << "," << adult_males.size();
    
    // LC:: Test statement to see progression of code in SLURM outputs
    // std::cout << total_females << " : " << gtime <<std::endl;

    stat = mean_std(fem_values);
    // Output mean and standard deviation to CSV
    csv_file << "," << std::get<0>(stat) << "," << std::get<1>(stat);

    stat = mean_std(femLarv_values);
    // Output mean and standard deviation to CSV
    csv_file << "," << std::get<0>(stat) << "," << std::get<1>(stat);

    stat = mean_std(malLarv_values);
    // Output mean and standard deviation to CSV
    csv_file << "," << std::get<0>(stat) << "," << std::get<1>(stat);
    
    stat = mean_std(totLarv_values);
    // Output mean and standard deviation to CSV
    csv_file << "," << std::get<0>(stat) << "," << std::get<1>(stat);

    std::vector<double> femaleGeneValues;
    std::vector<double> larvalGeneValues;
    
    for (size_t i = 0; i < nests.size(); ++i) {
        
        if (nests[i].adult_females.size() > 0 and (nests[i].larval_males.size() + nests[i].larval_females.size()) > 0) {
            
            // obtain gene values for relatedness calculation
            femaleGeneValues.push_back(0.5 * (nests[i].adult_females[uni_int(0, nests[i].adult_females.size())].genome[0].neutral_gene + nests[i].adult_females[uni_int(0, nests[i].adult_females.size())].genome[1].neutral_gene));
            if (bernoulli(nests[i].larval_males.size() / (nests[i].larval_males.size() + nests[i].larval_females.size()))) {
                larvalGeneValues.push_back(nests[i].larval_males[uni_int(0, nests[i].larval_males.size())].genome[0].neutral_gene);
            } else {
                larvalGeneValues.push_back(0.5 * (nests[i].larval_females[uni_int(0, nests[i].larval_females.size())].genome[0].neutral_gene + nests[i].larval_females[uni_int(0, nests[i].larval_females.size())].genome[1].neutral_gene));
            }
        }
    }
    
    // calculate relatedness
    double relatedness  = covariance(femaleGeneValues, larvalGeneValues) / (standard_deviation(femaleGeneValues) * standard_deviation(larvalGeneValues));
    
    csv_file << "," << relatedness;
    
    // Loop through beta values and output mean and standard deviation for each beta
    for (int beta_index = 0; beta_index < n_knots; ++beta_index) {
        stat = mean_std(beta_values[beta_index]);
        csv_file << "," << std::get<0>(stat) << "," << std::get<1>(stat);
    }

    // End the CSV line
    csv_file << "\n";
    csv_file.flush();

    // Update the last removal time
    last_evolution_time = gtime;

}

// function to print dead individual data and clear the vector
void Population::printDeadIndividualData(const std::vector< float >& param_values, std::ostream& csv_file) {
    // Check if enough time has passed since the last removal
    if (gtime - last_deadInd_time < dOutputTimeInterval) {
        return; // Skip removal if not enough time has passed
    }
    // gtime, pertime_foraging, pertask_foraging,  num_choices, nest_id

    for (size_t index = 0; index < deadInd_data.size(); ++index) {
        for (auto i : param_values) {
            csv_file << i << ',';
        }
        auto dInd = deadInd_data[index];
        csv_file << gtime << "," << std::get<1>(dInd) << ","
                << std::get<2>(dInd) << "," << std::get<3>(dInd) << ","
                << std::get<4>(dInd) << "," << std::get<5>(dInd);
        auto dIndGene = deadInd_geneData[index];
        for (int beta_index = 0; beta_index < n_knots; beta_index++) {
            csv_file << "," << dIndGene(beta_index, 0);
        }
        csv_file << std::endl;
    }
    
    csv_file.flush();
    // Update the last removal time
    last_deadInd_time = gtime;
    deadInd_data.clear();
    deadInd_geneData.clear();
}

// Print individual details for debugging TST
// LC: used this function only when testing, not used in current version
// Outputs in console
template<int Ploidy>
void printIndividualDetails(const Individual<Ploidy>& individual) {
    std::cout << "Individual ID: " << individual.ind_id << " | Nest ID: " << individual.nest_id << std::endl;
    std::cout << "Genome Values: ";
    for (int i = 0; i < Ploidy; ++i) {
        std::cout << "(" << individual.genome[i].genes_dispersal << ", " << individual.genome[i].genes_choice[0] << ", " << individual.genome[i].genes_choice[1] << ") ";
    }
    std::cout << std::endl;
    std::cout << "Phenotype Dispersal: " << individual.phenotype_dispersal << std::endl;
    std::cout << "Phenotype Choice Intercept: " << individual.phenotype_choice[0] << std::endl;
    std::cout << "Phenotype Choice Slope: " << individual.phenotype_choice[1] << std::endl;
    std::cout << "Is Alive: " << (individual.is_alive ? "true" : "false") << std::endl;
    std::cout << "Is Larva: " << (individual.is_larva ? "true" : "false") << std::endl;
    std::cout << "Is Foraging: " << (individual.is_foraging ? "true" : "false") << std::endl;
    std::cout << "Is Disperser: " << (individual.is_disperser ? "true" : "false") << std::endl;
    std::cout << "Is Mated: " << (individual.is_mated ? "true" : "false") << std::endl;
    std::cout << "Body Size: " << individual.body_size << std::endl;
    std::cout << "t_death: " << individual.t_death << std::endl;
    // std::cout << "Number of Offspring: " << individual.num_offspring << std::endl;
    // std::cout << "Number of Female Offspring: " << individual.num_fem_offspring << std::endl;
    // std::cout << "Number of Larvae: " << individual.num_larva << std::endl;
    // std::cout << "Number of Female Larvae: " << individual.num_female_larva << std::endl;
    std::cout << std::endl;
}

#endif /* Population_hpp */

