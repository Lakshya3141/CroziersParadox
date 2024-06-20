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
#include <numeric>
#include <filesystem>
#include <cmath>

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

class Population {
public:
    // Constructor for population from parameter struct
    Population(const params& par) : p(par) { };

    std::vector<Nest> nests;                        // Vector containing nests
    unsigned int nest_id_counter = 1;               // nest ID counter 
    params p;                                       // Parameters defining current population
    double PopStock = p.dInitFoodStock;
    // vector to store nest IDs and food stocks corresponding to nest indexes
    // becomes important as nests die
    std::vector<unsigned int> storer_nest_id;
    std::vector<double> storer_stocks;

    void initialise_pop();                          // Initialise population
    void simulate();                                // Simulate population
    void update_storer();                           // Updates the storer vectors
    void kill_nest(const unsigned int nestId);      // Kills specific nest 
    void reproduce_nest();                          // Single reproduction event
    int findIndexByNestId(unsigned int nestId);     // returns index of Nest ID in nests vector
    void mass_kill();                               // kills nests in mass
    void mass_reproduce();                          // mass reproduces colonies
    void regenerate_food();                         // linearly increase food stock
    int target_nest(Individual& indi);               // find nest to steal from, or forage
    void check_nests(const unsigned int nestId);    // Check if nestID is alive, kill if not 

private:
    double last_MassKill_time = 0.0;                // Time since last purge of colonies
    double last_MassRep_time = 0.0;                 // Time since last mass reproduction event
    void random_kill();                             // in mass kill, doesnt sort
    void sorted_kill();                             // in mass kill, sorts and kills
    void remove_nest(const unsigned int nestID);    // remove nests used in mass kill
    double tlastregen = 0.0;    
};

// Lambda function for maintaining priority queue
auto cmptime = [](const track_time& a, const track_time& b) { return a.time > b.time; };

// initialise population function
void Population::initialise_pop() {
    // Create nests and push them to nests and storer_nest_id vector
    for(int i=0; i < p.iNumColonies; ++i) {
        nests.emplace_back(nest_id_counter, p);
        // storer_nest_id.push_back(nest_id_counter);  // LC remove
        // storer_stocks.push_back(p.iInitNestStock);   // LC remove
        ++nest_id_counter;
    }

    update_storer();
}

void Population::simulate(){
    // Create a priority queue to track individuals by their next action time
    std::priority_queue<track_time, std::vector<track_time>, decltype(cmptime)> event_queue(cmptime);
    
    // Initialize the event queue with individuals and their initial next action times
    for (auto& nest : nests) {
        for (auto& individual : nest.NestWorkers) {
            event_queue.push(track_time(individual));
        }
    }

    while (gtime < max_gtime_evolution) {

        if (event_queue.empty()) {
            // No more events to process
            std::cout << "ERROR: event_queue empty" << std::endl;
            break;
        }

        // LC: Call masskill and mass reproduce every single time
        mass_kill();
        mass_reproduce();

        // Take the next action indiviual and pop it from the queue
        track_time next_event = event_queue.top();
        event_queue.pop();

        // Find nest index, ID and individual ID from next event
        size_t cnestindex = findIndexByNestId(next_event.nest_id);
        auto cindid = next_event.ind_id;
        auto cnestid = next_event.nest_id;
        gtime = next_event.time;        // Increment global time
        regenerate_food();              // Regenerate pop stock linearly

        // If current individual is from colonies ALIVE
        if (cnestindex != -1) {

            auto cindindex = nests[cnestindex].findIndexById(cindid);
            // dummy current variable to hold old variable values for current individual
            auto oldrec = nests[cnestindex].NestWorkers[cindindex];
            // cf points to the memory location of the individual
            Individual& current{nests[cnestindex].NestWorkers[cindindex]};
            nests[cnestindex].metabolic_cost(p);        // Subtract metabolic burden and regenerate
            update_storer();

            current.t_next += exponential(p.dMeanActionTime);

            // Check whether in colony or out
            if (current.bIsGoing) {
                // If outside colony, check whether foraging or steal
                int if_target = target_nest(current);

                if (current.bForage) {
                    PopStock -= 1.0;            // Reduce population stock size
                    current.bIsGoing = false;
                    current.bSuccesfulFood = true;

                } else {
                    // If stealing
                    current.bIsGoing = false;
                    int target_nest_index = findIndexByNestId(if_target);
                    bool success = nests[target_nest_index].check_Intruder(p, current.IndiCues);
                    if (success) {
                        nests[target_nest_index].NestStock -= 1.0;
                        update_storer();
                        current.bSuccesfulFood = true;
                        check_nests(if_target);
                    }
                    current.bSuccesfulFood = false;
                }
            } else {
                // If returning to colony, check whether successful or not
                current.bIsGoing = true;
                if (current.bSuccesfulFood) {
                    // Returning with food, resident check
                    bool greatEntry = nests[cnestindex].check_Resident(p, current);
                    if (greatEntry) {
                        nests[cnestindex].NestStock += 1.0;
                        update_storer();
                    }
                }
                // Success or No success, simply add back to colony
                // Also decide next task based on current status / LC or edit that at an earlier point
            }
            std::cout << "Nest ID: " << oldrec.nest_id << ", Individual ID: " << oldrec.ind_id 
            << ", t_birth: " << oldrec.t_birth << ", t_next: " << oldrec.t_next << std::endl;
            event_queue.push(current);
            check_nests(cnestid);
        }

        tlastregen = gtime;
        
    }
}

// Function to check nest ID for negative food
void Population::check_nests(const unsigned int nestId) {
    int nest_index = findIndexByNestId(nestId);
    if (storer_stocks[nest_index] < 0.0) {
        kill_nest(nestId);
    }
}

// Function to regenerate food linearly
void Population::regenerate_food(){
    PopStock += (gtime - tlastregen)*p.dRatePopStock;
}

// Function to find foraging or which nest to steal from
// based on population stock of food left and num colonies alive
int Population::target_nest(Individual& indi){
    double num = static_cast<double>(nests.size() - 1);
    double denom = static_cast<double>(PopStock + nests.size() - 1);

    if (bernoulli(num/denom)) {
        indi.bForage = false;
        int target_nest = indi.nest_id;
        std::vector<double> dumvec(nests.size(), 1.0);
        while (target_nest == indi.nest_id) {
            target_nest = storer_nest_id[chooseProbableIndex(dumvec)];
        }
        return target_nest;

    } else {
        indi.bForage = true;
        return -1;
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

    // Print error message for checking in case mismatch
    // if (dummy_stocks != storer_stocks || dummy_nest_id != storer_nest_id) {
    //     std::cout << "Mismatch in storeres detected" << std::endl;
    // } // LC remove

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
    remove_from_vec(nests, nestIndex);            // Remove from nest
    // remove_from_vec(storer_nest_id, nestIndex);   // Remove ID from storer nests // LC remove
    // remove_from_vec(storer_stocks, nestIndex); // Remove food stock from storer food stock // LC remove
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
        // storer_nest_id.push_back(nest_id_counter);  // LC remove
        // storer_stocks.push_back(p.iInitNestStock);   // LC remove
        ++nest_id_counter;

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
        }
        if (p.iFoodResetChoice == 1) {
            for (auto& nest : nests) {
                nest.NestStock = p.iInitNestStock + uni_real()/10;
            }
        }
        update_storer();
    }

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
    }

    // Kill colonies with food stock lower than threshold food stock
    auto dummy_nestIDs = storer_nest_id;
    auto dummy_stocks = storer_stocks;

    for (int i = 0; i < dummy_stocks.size(); i++) {
        if (dummy_stocks[i] <= threshold_stock) {
            remove_nest(dummy_nestIDs[i]);
        }
    }
}

#endif /* Population_hpp */