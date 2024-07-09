//
//  Population.hpp
//  Croziers Paradox
//
//  Created by Lakshya Chauhan on 18/04/2024.
//  Copyright © 2024 Lakshya Chauhan. All rights reserved.
//  -> Defines population class and corresponding functions
//  -> Also defines simulation and output functions
//  Pt 5

#ifndef Population_hpp
#define Population_hpp    

#include "Nest.hpp"
#include <queue>
#include <iomanip> // For std::setprecision
#include <sstream> // For std::ostringstream

namespace fs = std::filesystem;

// track_time struct for event queue ordered by next task time
struct track_time {
    double time;
    unsigned int nest_id;
    int ind_id;

    // event constructor using initializer lists
    track_time(const Individual& input) :
        time{input.t_next},
        nest_id{input.nest_id},
        ind_id{input.ind_id}
    {}
};

// Lambda function for maintaining priority queue
auto cmptime = [](const track_time& a, const track_time& b) { return a.time > b.time; };

class Population {
public:
    // Constructor for population from parameter struct
    Population(const params& par) : p(par), event_queue(cmptime) { };

    std::vector<Nest> nests;                        // Vector containing nests
    std::vector<Nest> deadnests;                    // holds dead nests till they can be printed
    unsigned int nest_id_counter = 1;               // nest ID counter 
    params p;                                       // Parameters defining current population
    double PopStock = p.dInitFoodStock;             // population food stock
    // vector to store nest IDs and food stocks corresponding to nest indexes
    // becomes important as nests die
    std::vector<unsigned int> storer_nest_id;
    std::vector<double> storer_stocks;

    void initialise_pop();                                      // Initialise population
    void simulate(const std::vector<std::string>& param_names); // Simulate population
    void update_storer();                                       // Updates the storer vectors
    void kill_nest(const unsigned int nestId);                  // Kills specific nest 
    void reproduce_nest();                                      // Single reproduction event
    int findIndexByNestId(unsigned int nestId);                 // returns index of Nest ID in nests vector
    void mass_kill();                                           // kills nests in mass
    void mass_reproduce();                                      // mass reproduces colonies
    void regenerate_food();                                     // linearly increase food stock
    int target_nest(Individual& indi);                          // find nest to steal from, or forage
    void check_nests(const unsigned int nestId);                // Check if nestID is alive, kill if not 

    // Output functions
    void printPopulationState(const std::vector< float >& param_values, std::ostream& csv_file);
    void printLastPopulationState(std::ostream& csv_file);
    void printDeadNestsData(const std::vector< float >& param_values, std::ostream& csv_file);

private:
    double last_MassKill_time = 0.0;                // Time since last purge of colonies
    double last_MassRep_time = 0.0;                 // Time since last mass reproduction event
    double last_TickUpdate_time = 0.0;              // Time since last pop stock was updated IF tick based food
    void random_kill();                             // in mass kill, doesnt sort
    void sorted_kill();                             // in mass kill, sorts and kills
    void remove_nest(const unsigned int nestID);    // remove nests used in mass kill
    std::vector<double> calculateMeanProfile() const;   // Calculates mean profile of population
    double tlastregen = 0.0;                        // Last food regeneration time
    double last_evolution_time = 0.0;               // Last time of population output
    double last_deadnest_time = 0.0;                // Last time of deadnest output
    // Event queue below for maintaining gillespe
    std::priority_queue<track_time, std::vector<track_time>, decltype(cmptime)> event_queue; 
    std::vector<Nest> deadNests;                    // Vector to store all the dead nests collected
    // count variables for sanity checks below
    double cnt_sucrentry = 0;
    double cnt_sucfood = 0;
    double cnt_steal = 0;
    double cnt_sucsteal = 0;
    double cnt_sucforage = 0;
    double cnt_rentry = 0;
    double cnt_leave = 0;
    // Tuples and variables to store population outputs
    std::tuple<double, double, double> gen_stuff;
    std::tuple<double, double> stat_bc_nest;
    std::tuple<double, double> stat_bc_ant;
    std::tuple<double, double> stat_shannons;
    std::tuple<double, double> stat_simpsons;
    std::tuple<double, double> stat_shannonsant;
    std::tuple<double, double> stat_simpsonsant;
    std::tuple<double, double> stat_neutral;
    std::tuple<double, double> stat_intercepts;
    std::tuple<double, double> stat_slopes;
    std::tuple<double, double> stat_cueabun;
    std::tuple<double, double> stat_offsprings;
    std::tuple<double, double> simp_shan_offspring;
    std::tuple<double, double> stat_time_alive;
    std::tuple<double, double> max_min_time;
    double relatedness;
};

// Function to calculate the mean profile of the population
std::vector<double> Population::calculateMeanProfile() const {
    if (nests.empty()) {
        // If there are no nests, return an empty vector or handle it accordingly
        return std::vector<double>();
    }

    std::vector<double> meanProfile(p.iNumCues, 0.0);

    // Variables to accumulate profiles and count workers
    size_t totalWorkers = 0;

    for (const auto& nest : nests) {
        for (const auto& worker : nest.NestWorkers) {
            for (size_t i = 0; i < p.iNumCues; ++i) {
                meanProfile[i] += worker.IndiCues[i];
            }
            ++totalWorkers;
        }
    }

    // Calculate the mean for each profile element
    for (size_t i = 0; i < p.iNumCues; ++i) {
        meanProfile[i] /= static_cast<double>(totalWorkers);
    }

    return meanProfile;
}

// initialise population function
void Population::initialise_pop() {
    // Create nests and push them to nests and storer_nest_id vector
    for(int i=0; i < p.iNumColonies; ++i) {
        nests.emplace_back(nest_id_counter, p);
        ++nest_id_counter;
    }
    update_storer();
}

void Population::simulate(const std::vector<std::string>& param_names){
    // Created a priority queue to track individuals by their next action time
    // Priority queue initialised in the private section of Population
    // Initialize the event queue with individuals and their initial next action times
    for (auto& nest : nests) {
        for (auto& individual : nest.NestWorkers) {
            event_queue.push(track_time(individual));
        }
    }

    // Create output files for entire simulation, dead nests and final state file
    fs::path evolutionPath = fs::path("./output_sim/" + std::to_string(simulationID) + "_evolution.csv");
    std::ofstream evolution_file(evolutionPath);

    fs::path deadnestPath = fs::path("./output_sim/" + std::to_string(simulationID) + "_deadNests.csv");
    std::ofstream dn_file(deadnestPath);
    
    fs::path finalState = fs::path("./output_sim/" + std::to_string(simulationID) + "_finState.csv");
    std::ofstream fs_file(finalState);

    // Add headers and parameter names to be recorded to first row
    for (auto i : param_names) {
        evolution_file << i << ',';
        dn_file << i << ',';
    }
    evolution_file << "gtime,popstock,popsize,bcnest_avg,bcnest_std,bcind_avg,bcind_std,nshan_avg,nshan_std,nsimp_avg,nsimp_std,ishan_avg,ishan_std,isimp_avg,isimp_std,relatedness,neutral_avg,neutral_std,int_avg,int_std,slope_avg,slope_std,cueabun_avg,cueabun_std,steal,sucsteal,leave,sucfor,rentry,sucrentr,sucfood,offprings_avg,offspring_std,offsimp,offshan,timealive_avg,timealive_std,maxtime_alive,mintime_alive";
    evolution_file << std::endl;
    evolution_file.flush();
    fs_file << "gtime,popstock,popsize,glasttime,popstocklast,popsizelast,bcnest_avg,bcnest_std,bcind_avg,bcind_std,nshan_avg,nshan_std,nsimp_avg,nsimp_std,ishan_avg,ishan_std,isimp_avg,isimp_std,relatedness,neutral_avg,neutral_std,int_avg,int_std,slope_avg,slope_std,cueabun_avg,cueabun_std,steal,sucsteal,leave,sucfor,rentry,sucrentr,sucfood,offprings_avg,offspring_std,offsimp,offshan,timealive_avg,timealive_std,maxtime_alive,mintime_alive";
    fs_file << std::endl;
    fs_file.flush();
    dn_file << "gtime,tbirth,nest_id,neststock,mom_id,num_steal,num_sucsteal,num_leave,num_forage,num_rentry,num_sucrentry,num_raid,num_sucraid,num_actions,int,slope,offspring,neutral_gene,popavg_dist";
    // Add headers for cue values
    for (int cue_index = 0; cue_index < p.iNumCues; ++cue_index) {
        dn_file << ",cue" << cue_index;
    }

    dn_file << std::endl;
    dn_file.flush();

    // Start simulation loop
    while (gtime < max_gtime_evolution) {

        if (event_queue.empty()) {
            // No more events to process
            // Can happen in case of hostile situations when populaton dies out
            std::cout << "ERROR: event_queue empty" << std::endl;
            break;
        }

        //Call massk_kill, mass_reproduce and output functions every single time
        mass_kill();
        mass_reproduce();
        printPopulationState(p.params_to_record, evolution_file);
        printDeadNestsData(p.params_to_record, dn_file);

        // Take the next action indiviual and pop it from the queue
        track_time next_event = event_queue.top();
        event_queue.pop();

        // Find nest index, ID and individual ID from next event
        size_t cnestindex = findIndexByNestId(next_event.nest_id);
        auto cindid = next_event.ind_id;
        auto cnestid = next_event.nest_id;
        gtime = next_event.time;                // Increment global time
        regenerate_food();                      // Regenerate pop stock as per model choice

        // If current individual is from colonies ALIVE
        if (cnestindex != -1) {
            auto cindindex = nests[cnestindex].findIndexById(cindid);
            // current points to memory location of current individual
            Individual& current{nests[cnestindex].NestWorkers[cindindex]};
            nests[cnestindex].metabolic_cost(p);                // Subtract metabolic burden and regenerate
            update_storer();
            current.t_next += exponential(p.dMeanActionTime);   // Update next action time
            nests[cnestindex].nactions++;

            // Check whether in colony or out
            if (current.bIsGoing) {
                // If outside colony, check whether foraging or steal
                int if_target = target_nest(current);
                // If foraging
                nests[cnestindex].nleave++;
                cnt_leave++;     
                if (current.bForage) {
                    PopStock -= 1.0;            // Reduce population stock size
                    current.bSuccesfulFood = true;
                    cnt_sucforage++;
                    nests[cnestindex].nsucforage++;
                } else {
                    // If stealing
                    int target_nest_index = findIndexByNestId(if_target);
                    // Check if intrusion is successful
                    bool success = nests[target_nest_index].check_Intruder(p, current.IndiCues);
                    cnt_steal++;   
                    nests[cnestindex].nsteal++;
                    nests[target_nest_index].nraids++;

                    // if successful in stealing
                    if (success) {
                        nests[target_nest_index].NestStock -= 1.0;
                        update_storer();
                        current.bSuccesfulFood = true;
                        nests[target_nest_index].nsucraids++;
                        check_nests(if_target);
                        cnt_sucsteal++; 
                        nests[cnestindex].nsucsteal++;
                    }
                    current.bSuccesfulFood = false;
                }
                // Action done, change to incoming
                current.bIsGoing = false;
            } else {
                // If returning to colony, check whether successful or not
                if (current.bSuccesfulFood) {
                    // Returning with food, resident check
                    bool greatEntry = nests[cnestindex].check_Resident(p, current);
                    cnt_sucfood++;
                    nests[cnestindex].nsucfood++;
                    if (greatEntry) {
                        nests[cnestindex].NestStock += 1.0;
                        update_storer();
                        cnt_sucrentry++;           
                        nests[cnestindex].nsucrentry++;
                    }
                }
                cnt_rentry++;           //LC
                nests[cnestindex].nrentry++;
                // Success or No success, simply add back to colony
                current.bIsGoing = true;
            }
            // std::cout << "Nest ID: " << current.nest_id << ", Individual ID: " << current.ind_id 
            // << ", t_birth: " << current.t_birth << ", t_next: " << current.t_next << ", Go: " << current.bIsGoing << ", Steal: " << !current.bForage  << std::endl;
            // std::cout << cnt_sucrentry << "/" << cnt_sucfood << "  Res|Int  " << cnt_sucsteal << "/" << cnt_steal;  //LC
            // std::cout << "   For:" << cnt_sucforage << "   Rer:" << cnt_rentry << "   Go:" << cnt_forage;
            // std::cout << "   PopSt:" << PopStock << std::endl;
            event_queue.push(current);
            check_nests(cnestid);
        }
        // Last action time of population assigned to tlastregen
        tlastregen = gtime;
    }
    // Output last point of output
    printLastPopulationState(fs_file);
    fs_file.close();
    evolution_file.close();
    dn_file.close();
}

// Function to check nest ID for negative food
// Kill nest if negative food is found
void Population::check_nests(const unsigned int nestId) {
    int nest_index = findIndexByNestId(nestId);
    if (storer_stocks[nest_index] < 0.0) {
        kill_nest(nestId);
    }
}

// Function to regenerate food as per model choice
void Population::regenerate_food(){
    if(p.iConstStockChoice == 1) {
        PopStock = p.dConstantPopStock;
    } else if (p.iConstStockChoice == 0) {
        if (PopStock < 0.0) {
            PopStock = 0.0;
        }
        PopStock += (gtime - tlastregen)*p.dRatePopStock;
    } else if (p.iConstStockChoice == 2) {
        if (gtime - last_TickUpdate_time < dTickTime) {
            return; // Skip removal if not enough time has passed
        }
        PopStock = p.dInitFoodStock;
        last_TickUpdate_time = gtime;
    }
}

// Function to find foraging or which nest to steal from
// based on population stock of food left and num colonies alive
int Population::target_nest(Individual& indi){
    double num = static_cast<double>(nests.size() - 1);
    double denom = static_cast<double>(PopStock + nests.size() - 1);
    bool decision = bernoulli(num/denom);
    // Take bernoulli of fraction
    if (!decision) {
        indi.bForage = true;
        return -1;
    } else {
        // Stealing from other colony
        indi.bForage = false;
        int target_nest = indi.nest_id;
        std::vector<double> dumvec(nests.size(), 1.0);
        // Ensure target colony isnt the same
        while (target_nest == indi.nest_id) {
            target_nest = storer_nest_id[chooseProbableIndex(dumvec)];
        }
        return target_nest;
    }
}

// Function to loop through nests and update the
// storer vectors to avoid mismatch
void Population::update_storer(){

    // dummy variables
    std::vector<unsigned int> dummy_nest_id;
    std::vector<double> dummy_stocks; 

    // Push values to dummy storers
    for (auto& curnest : nests) {
        dummy_nest_id.push_back(curnest.nest_id);
        dummy_stocks.push_back(curnest.NestStock);
    }

    // Assign values
    storer_stocks = dummy_stocks;
    storer_nest_id = dummy_nest_id;

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

// Function to kill a particular nest ID from nests vector
// and also from storer_nest_id vector
void Population::kill_nest(const unsigned int nestID) {
    int nestIndex = findIndexByNestId(nestID);    // Find index of nest in storer and nests vector
    if(bernoulli(dFracDeadNest)) {
        deadNests.push_back(nests[nestIndex]);    // Push to deadNests vector
    }
    remove_from_vec(nests, nestIndex);            // Remove from nest
    update_storer();

    // Since we also call kill_nest when food runs low
    // if mass reproduction is not allowed, then produce 1 colony at the same time
    if (p.iRepChoice == 1 || p.iRepChoice == 2) {
        reproduce_nest();
    }
}

// Function to remove a particular nest ID from nests vector
// used in masskill
void Population::remove_nest(const unsigned int nestID) {
    int nestIndex = findIndexByNestId(nestID);    // Find index of nest in storer and nests vector
    if(bernoulli(dFracDeadNest)) {
        deadNests.push_back(nests[nestIndex]);    // Push to deadNests vector
    }

    remove_from_vec(nests, nestIndex);            // Remove from nest
    update_storer();
}

// Function to look at current food stocks, and take those as the viability
// potentials of nests, and one nest reproduces
void Population::reproduce_nest() {
    int MotherIndex = chooseProbableIndex(storer_stocks);
    int MotherNID = storer_nest_id[MotherIndex];

    if (nests.size() < p.iNumColonies) { 
        // Memory location of mother nest stored in mom_nest
        Nest& mom_nest{nests[MotherIndex]};
        // Reproduce
        nests.emplace_back(nest_id_counter, p, mom_nest);
        ++nest_id_counter;

        // Add new individuals to event queue
        for (auto ind : nests.back().NestWorkers){
            event_queue.push(track_time(ind));
        }

        // Increase mother offspring count
        mom_nest.num_offsprings++;
    }
    update_storer();
}

// Reproduces in mass right after mass kill
void Population::mass_reproduce() {
    // Check last mass reproduce time
    if (gtime - last_MassRep_time < dRemovalTime) {
        return; // Skip removal if not enough time has passed
    }

    // Mass reproduction is done
    if (p.iRepChoice == 0 || p.iRepChoice == 2) {
        int num_currentNests = nests.size();
        while (num_currentNests < p.iNumColonies) {
            int MotherIndex = chooseProbableIndex(storer_stocks);
            int MotherNID = storer_nest_id[MotherIndex];
            Nest& mom_nest{nests[MotherIndex]};
            // Reproduce
            nests.emplace_back(nest_id_counter, p, mom_nest);
            ++nest_id_counter;
            num_currentNests = nests.size();
            mom_nest.num_offsprings++;

            // Add new workers to event queue
            for (auto ind : nests.back().NestWorkers){
                event_queue.push(track_time(ind));
            }
        }
        if (p.iFoodResetChoice == 1) {
            for (auto& nest : nests) {
                nest.NestStock = p.dInitNestStock;
            }
            PopStock = p.dInitFoodStock;
        }
        update_storer();
    }
    last_MassRep_time = gtime;
}

// Mass kill function. Depending on value of iKillChoice
// Does random kill, sorted kill or NO kill
void Population::mass_kill() {
    // Check last mass kill time
    if (gtime - last_MassKill_time < dRemovalTime) {
        return; // Skip removal if not enough time has passed
    }

    // Implement choice of killing
    if (p.iKillChoice == 0) {
        random_kill();
    } else if (p.iKillChoice == 1) {
        sorted_kill();
    } else if (p.iKillChoice == 2) {
        int dummyVar = 0;
    } else {
        throw std::runtime_error("Wrong choice of iKillChoice");
    }

    last_MassKill_time = gtime;             // Update last massKill time
}

// implicit function called in mass kill
// Implements random kill
void Population::random_kill() {
    // Calculate number of colonies to be killed
    int alreadyDead = p.iNumColonies - nests.size();
    int toKill = floor(p.dFracKilled*p.iNumColonies) - alreadyDead;

    // In case we have individual and mass reproduction both
    // then toKill is simply fracKilled x numColonies
    if (p.iRepChoice == 2) {
        toKill = floor(p.dFracKilled*p.iNumColonies);
    }

    // Take random subset of nestIDs and kill
    if (toKill > 0) {
        auto toKillNestIDs = randomSubset(storer_nest_id, toKill);
        for (int i = 0; i < toKill; i++) {
            remove_nest(toKillNestIDs[i]);
        }
    }
}

// implicit function called in mass kill
// Implements sorted kill
void Population::sorted_kill() {
    // Calculate number of colonies to be killed
    int alreadyDead = p.iNumColonies - nests.size();
    int toKill = floor(p.dFracKilled*p.iNumColonies) - alreadyDead;

    // In case we have individual and mass reproduction both
    // then toKill is simply fracKilled x numColonies
    if (p.iRepChoice == 2) {
        toKill = floor(p.dFracKilled*p.iNumColonies);
    }

    double threshold_stock = 0.0;
    
    // Find food stock threshold that determines death
    if (toKill > 0) {
        auto sorted_stock = storer_stocks;
        std::sort(sorted_stock.begin(), sorted_stock.end());
        threshold_stock = sorted_stock[toKill - 1];
        // Kill colonies with food stock lower than threshold food stock
        auto dummy_nestIDs = storer_nest_id;
        auto dummy_stocks = storer_stocks;

        // Remove nests using IDs
        for (int i = 0; i < dummy_stocks.size(); i++) {
            if (dummy_stocks[i] <= threshold_stock) {
                remove_nest(dummy_nestIDs[i]);
            }
        }
    }

    
}

void Population::printPopulationState(const std::vector< float >& param_values, std::ostream& csv_file) {
    if (gtime - last_evolution_time < dOutputTime) {
        return; // Skip removal if not enough time has passed
    }
    // evolution_file << "gtime,popstock,popsize,bcnest_avg,bcnest_std,bcind_avg,bcind_std,shannons_avg,shannons_std,simpsons_avg,simpsons_std,shannonsant_avg,shannonsant_std,simpsonsant_avg,simpsonsant_std,relatedness,neutral_avg,neutral_std,intercepts_avg,intercepts_std,slopes_avg,slopes_std,cueabun_avg,cueabun_std,steal,sucsteal,for,sucfor,rentry,sucrentr,sucfood,offsprings_avg,offsprings_std,offsimp,offshan,timealive_avg,timealive_std,maxtime_alive,mintime_alive";

    for (auto i : param_values) {
        csv_file << i << ',';
    }
    gen_stuff = std::make_tuple(gtime, PopStock, nests.size());
    csv_file << std::get<0>(gen_stuff) << "," << std::get<1>(gen_stuff) << "," << std::get<2>(gen_stuff);

    std::vector<std::vector<double>> nestProfiles;
    std::vector<std::vector<double>> antProfiles;
    std::vector<double> shannons;
    std::vector<double> simpsons;
    std::vector<double> shannonsant;
    std::vector<double> simpsonsant;
    std::vector<double> intercepts;
    std::vector<double> slopes;
    std::vector<double> cueabun;
    std::vector<double> offsprings;
    std::vector<double> neutral;
    std::vector<double> time_alive;

    for (auto& nest: nests){
        nestProfiles.push_back(nest.NestMean);
        for (auto& ant: nest.NestWorkers){
            antProfiles.push_back(ant.IndiCues);
            shannonsant.push_back(calculateShannonDiversity({ant.IndiCues}));
            simpsonsant.push_back(calculateSimpsonDiversity({ant.IndiCues}));
        }
        shannons.push_back(calculateShannonDiversity({nest.NestMean}));
        simpsons.push_back(calculateSimpsonDiversity({nest.NestMean}));
        neutral.push_back(nest.NestNeutralGene);
        intercepts.push_back(nest.TolIntercept);
        slopes.push_back(nest.TolSlope);
        cueabun.push_back(nest.TotalAbundance);
        offsprings.push_back(nest.num_offsprings);
        time_alive.push_back(gtime - nest.tbirth);
    }

    stat_bc_nest = calculatePairwiseBrayCurtis(nestProfiles);
    csv_file << "," << std::get<0>(stat_bc_nest) << "," << std::get<1>(stat_bc_nest);

    stat_bc_ant = calculatePairwiseBrayCurtis(antProfiles);
    csv_file << "," << std::get<0>(stat_bc_ant) << "," << std::get<1>(stat_bc_ant);

    stat_shannons = mean_std(shannons);
    csv_file << "," << std::get<0>(stat_shannons) << "," << std::get<1>(stat_shannons);

    stat_simpsons = mean_std(simpsons);
    csv_file << "," << std::get<0>(stat_simpsons) << "," << std::get<1>(stat_simpsons);

    stat_shannonsant = mean_std(shannonsant);
    csv_file << "," << std::get<0>(stat_shannonsant) << "," << std::get<1>(stat_shannonsant);

    stat_simpsonsant = mean_std(simpsonsant);
    csv_file << "," << std::get<0>(stat_simpsonsant) << "," << std::get<1>(stat_simpsonsant);

    // Calculate relatedness
    std::vector<double> geneValuesNest1;
    std::vector<double> geneValuesNest2;
    
    for (const auto& nest : nests) {
        size_t randomIndex1 = uni_int(0, static_cast<int>(p.iNumWorkers));
        size_t randomIndex2;
        do {
            randomIndex2 = uni_int(0, static_cast<int>(p.iNumWorkers));
        } while (randomIndex1 == randomIndex2);

        geneValuesNest1.push_back(nest.NestWorkers[randomIndex1].NeutralGene);
        geneValuesNest2.push_back(nest.NestWorkers[randomIndex2].NeutralGene);
    }

    relatedness = covariance(geneValuesNest1, geneValuesNest2) / (standard_deviation(geneValuesNest1) * standard_deviation(geneValuesNest2));
    csv_file << "," << relatedness;

    stat_neutral = mean_std(neutral);
    csv_file << "," << std::get<0>(stat_neutral) << "," << std::get<1>(stat_neutral);

    stat_intercepts = mean_std(intercepts);
    csv_file << "," << std::get<0>(stat_intercepts) << "," << std::get<1>(stat_intercepts);

    stat_slopes = mean_std(slopes);
    csv_file << "," << std::get<0>(stat_slopes) << "," << std::get<1>(stat_slopes);

    stat_cueabun = mean_std(cueabun);
    csv_file << "," << std::get<0>(stat_cueabun) << "," << std::get<1>(stat_cueabun);

    csv_file << "," << cnt_steal;
    csv_file << "," << cnt_sucsteal;
    csv_file << "," << cnt_leave;
    csv_file << "," << cnt_sucforage;
    csv_file << "," << cnt_rentry;
    csv_file << "," << cnt_sucrentry;
    csv_file << "," << cnt_sucfood;

    stat_offsprings = mean_std(offsprings);
    simp_shan_offspring = std::make_tuple(calculateSimpsonDiversity({offsprings}),calculateShannonDiversity({offsprings}));
    csv_file << "," << std::get<0>(stat_offsprings) << "," << std::get<1>(stat_offsprings);
    csv_file << "," << std::get<0>(simp_shan_offspring) << "," << std::get<1>(simp_shan_offspring);

    stat_time_alive = mean_std(time_alive);
    max_min_time = std::make_tuple(*std::max_element(time_alive.begin(), time_alive.end()),*std::min_element(time_alive.begin(), time_alive.end()));
    csv_file << "," << std::get<0>(stat_time_alive) << "," << std::get<1>(stat_time_alive);
    csv_file << "," << std::get<0>(max_min_time) << "," << std::get<1>(max_min_time);

    // End the CSV line
    csv_file << "\n";
    csv_file.flush();

    // Update the last removal time
    last_evolution_time = gtime;
}


void Population::printLastPopulationState(std::ostream& csv_file) {
    csv_file << gtime << "," << PopStock << "," << nests.size();
    csv_file << "," <<  std::get<0>(gen_stuff) << "," << std::get<1>(gen_stuff) << "," << std::get<2>(gen_stuff);
    csv_file << "," << std::get<0>(stat_bc_nest) << "," << std::get<1>(stat_bc_nest);
    csv_file << "," << std::get<0>(stat_bc_ant) << "," << std::get<1>(stat_bc_ant);
    csv_file << "," << std::get<0>(stat_shannons) << "," << std::get<1>(stat_shannons);
    csv_file << "," << std::get<0>(stat_simpsons) << "," << std::get<1>(stat_simpsons);
    csv_file << "," << std::get<0>(stat_shannonsant) << "," << std::get<1>(stat_shannonsant);
    csv_file << "," << std::get<0>(stat_simpsonsant) << "," << std::get<1>(stat_simpsonsant);
    csv_file << "," << relatedness;
    csv_file << "," << std::get<0>(stat_neutral) << "," << std::get<1>(stat_neutral);
    csv_file << "," << std::get<0>(stat_intercepts) << "," << std::get<1>(stat_intercepts);
    csv_file << "," << std::get<0>(stat_slopes) << "," << std::get<1>(stat_slopes);
    csv_file << "," << std::get<0>(stat_cueabun) << "," << std::get<1>(stat_cueabun);
    csv_file << "," << cnt_steal;
    csv_file << "," << cnt_sucsteal;
    csv_file << "," << cnt_leave;
    csv_file << "," << cnt_sucforage;
    csv_file << "," << cnt_rentry;
    csv_file << "," << cnt_sucrentry;
    csv_file << "," << cnt_sucfood;
    csv_file << "," << std::get<0>(stat_offsprings) << "," << std::get<1>(stat_offsprings);
    csv_file << "," << std::get<0>(simp_shan_offspring) << "," << std::get<1>(simp_shan_offspring);
    csv_file << "," << std::get<0>(stat_time_alive) << "," << std::get<1>(stat_time_alive);
    csv_file << "," << std::get<0>(max_min_time) << "," << std::get<1>(max_min_time);
    // End the CSV line
    csv_file << "\n";
    csv_file.flush();
}

void Population::printDeadNestsData(const std::vector< float >& param_values, std::ostream& csv_file){
    if (gtime - last_deadnest_time < dOutputTime) {
        return; // Skip removal if not enough time has passed
    }
    // dn_file << "gtime,tbirth,nest_id,neststock,mom_id,num_steal,num_sucsteal,num_forage,num_sucforage,num_rentry,num_sucrentry,num_raid,num_sucraid,num_actions,int,slope,offspring,neutral_gene,popavg_dist";
    
    if (deadNests.size() > 0) {
        for (auto& nest : deadNests) {
            // -> here
            for (auto i : param_values) {
                csv_file << i << ',';
            }
            csv_file << gtime << "," << nest.tbirth << "," << nest.nest_id << "," << nest.NestStock << ",";
            csv_file << nest.mom_id << "," << nest.nsteal << "," << nest.nsucsteal << "," << nest.nleave << ",";
            csv_file << nest.nsucforage << "," << nest.nrentry << "," << nest.nsucrentry << "," << nest.nraids << ",";
            csv_file << nest.nsucraids << "," << nest.nactions << "," << nest.TolIntercept << "," << nest.TolSlope << ",";
            csv_file << nest.num_offsprings << "," << nest.NestNeutralGene << ",";

            auto pop_avg = calculateMeanProfile();
            csv_file << calculateBrayCurtisDistance(nest.NestMean, pop_avg) << ",";
            
            for (int cue_index = 0; cue_index < p.iNumCues; ++cue_index) {
                csv_file << nest.NestMean[cue_index] << "," ;
            }

            // End the CSV line
            csv_file << "\n";
            csv_file.flush();
        }
    }
    deadNests.clear();
    // Update the last removal time
    last_deadnest_time = gtime;
}
#endif /* Population_hpp */