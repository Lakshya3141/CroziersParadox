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
    unsigned int nest_id_counter = 0;               // nest ID counter 
    params p;                                       // Parameters defining current population

    // vector to store nest IDs and abundances corresponding to nest indexes
    // becomes important as nests die
    std::vector<unsigned int> storer_nest_id;
    std::vector<double> storer_abundance;

    void initialise_pop();                          // Initialise population
    void simulate();                                // Simulate population
    void kill_nest(const unsigned int nestId);      // Kills specific nest 
    void reproduce_nest();                          // Single reproduction event
    int findIndexByNestId(unsigned int nestId);     // returns index of Nest ID in nests vector
    void mass_kill();                               // kills nests in mass
    void mass_reproduce();                          // mass reproduces colonies
    

private:
    double last_MassKill_time = 0.0;                // Time since last purge of colonies
    double last_MassRep_time = 0.0;                 // Time since last mass reproduction event
    void random_kill();                             // in mass kill, doesnt sort
    void sorted_kill();                             // in mass kill, sorts and kills
};

// Lambda function for maintaining priority queue
auto cmptime = [](const track_time& a, const track_time& b) { return a.time > b.time; };

// initialise population function
void Population::initialise_pop() {
    // Create nests and push them to nests and storer_nest_id vector
    for(int i=0; i < p.iNumColonies; ++i) {
        nests.emplace_back(nest_id_counter, p);
        storer_nest_id.push_back(nest_id_counter);
        storer_abundance.push_back(p.iInitNestStock);
        ++nest_id_counter;
    }
    // Initialise natural stock of food
    int PopStock = p.iInitFoodStock;
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
        // mass_kill()
        // mass_reproduce();

        // Take the next action indiviual and pop it from the queue
        track_time next_event = event_queue.top();
        event_queue.pop();

        // Find nest index, ID and individual ID from next event
        size_t cnestindex = findIndexByNestId(next_event.nest_id);
        auto cindid = next_event.ind_id;
        auto cnestid = next_event.nest_id;
        gtime = next_event.time;        // Increment global time
        
        // If current individual is from colonies ALIVE
        if (cnestindex != -1) {

            auto cindindex = nests[cnestindex].findIndexById(cindid);
            // dummy current variable to hold old variable values for current individual
            auto current = nests[cnestindex].NestWorkers[cindindex];
            // cf points to the memory location of the individual
            Individual& cf{nests[cnestid].NestWorkers[cindindex]};

            // DUMMY INCREASE IN TIME
            // TO CHECK WORKING OF QUEUE
            cf.t_next += 1.0;

            // Check whether in colony or out
            if (current.bIsGoing) {
                // If outside colony, check whether foraging or steal
                if (current.bForage) {
                    // If foraging
                } else {
                    // If stealing
                }
            } else {
                // If returning to colony, check whether successful or not
                if (current.bSuccesfulFood) {
                    // Returning with food, resident check
                }
                // Success or No success, simply add back to colony
                // Also decide next task based on current status / LC or edit that at an earlier point
            }
            std::cout << "Nest ID: " << cf.nest_id << ", Individual ID: " << cf.ind_id 
            << ", t_birth: " << cf.t_birth << ", t_next: " << cf.t_next << std::endl;
            event_queue.push(cf);
        }
        
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

// Function to kill a particular nest ID from nests vector
// and also from storer_nest_id vector
void Population::kill_nest(const unsigned int nestID) {
    int nestIndex = findIndexByNestId(nestID);    // Find index of nest in storer and nests vector
    remove_from_vec(nests, nestIndex);            // Remove from nest
    remove_from_vec(storer_nest_id, nestIndex);   // Remove ID from storer nests
    remove_from_vec(storer_abundance, nestIndex); // Remove abundance from storer abundance

    // Since we also call kill_nest when food runs low
    // if mass reproduction is not allowed, then produce 1 colony at the same time
    if (p.iRepChoice == 1) {
        reproduce_nest();
    }
}

void Population::reproduce_nest() {
    int MotherIndex = chooseProbableIndex(storer_abundance);
    int MotherNID = storer_nest_id[MotherIndex];
    
    

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
        throw std::runtime_error("Wrong choice of dFracKilled");
    }

    last_MassKill_time = gtime;             // Update last massKill time
}

// implicit function called in mass kill
// Implements random kill
void Population::random_kill() {
    // Calculate number of colonies to be killed
    int alreadyDead = p.iNumColonies - nests.size();
    int toKill = floor(p.dFracKilled*p.iNumColonies) - alreadyDead;

    // Take random subset of nestIDs and kill
    if (toKill > 0) {
        auto toKillNestIDs = randomSubset(storer_nest_id, toKill);
        for (int i = 0; i < toKill; i++) {
            kill_nest(toKillNestIDs[i]);
        }
    }
}

// implicit function called in mass kill
// Implements sorted kill
void Population::sorted_kill() {
    // Calculate number of colonies to be killed
    int alreadyDead = p.iNumColonies - nests.size();
    int toKill = floor(p.dFracKilled*p.iNumColonies) - alreadyDead;
    double threshold_abundance = 0.0;
    
    // Find abundance threshold that determines death
    if (toKill > 0) {
        auto sorted_abundance = storer_abundance;
        std::sort(sorted_abundance.begin(), sorted_abundance.end());
        threshold_abundance = sorted_abundance[toKill];
    }

    // Kill colonies with abundance lower than threshold abundance
    int count = 0;
    while(toKill > 0) {
        if(storer_abundance[count] <= threshold_abundance) {
            kill_nest(storer_nest_id[count]);
            toKill--;
        }
        count++;
    }
}
#endif /* Population_hpp */