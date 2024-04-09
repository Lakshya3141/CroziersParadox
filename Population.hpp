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
    track_time(const Individual& input) :
        time{input.t_next},
        nest_id{input.nest_id},
        ind_id{input.ind_id}
    {}
};

class Population {
public:
    Population(const params& par) : p(par) { };

    std::vector<Nest> nests;
    unsigned int nest_id_counter = 0;               // nest ID counter 
    unsigned int ind_id_counter = 0;                // ind ID counter
    int PopStock = iInitFoodStock;
    params p;

    std::vector<unsigned int> storer_nest_id;       // vector to store nest IDs corresponding to nest indexes

    void initialise_pop();                          // Initialise populations
    void simulate();

    int findIndexByNestId(unsigned int nestId);     // returns index of Nest ID in nests vector
};

// Lambda function for maintaining priority queue
auto cmptime = [](const track_time& a, const track_time& b) { return a.time > b.time; };

// initialise population function
void Population::initialise_pop() {
    for(int i=0; i < iNumColonies; ++i) {
        nests.emplace_back(nest_id_counter, p);
        storer_nest_id.push_back(nest_id_counter);
        ++nest_id_counter;
    }
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

        track_time next_event = event_queue.top();
        event_queue.pop();

        size_t cnestindex = findIndexByNestId(next_event.nest_id);
        auto cindid = next_event.ind_id;
        auto cnestid = next_event.nest_id;
        auto cindindex = nests[cnestindex].findIndexById(cindid);

        // dummy current to hold old variable values for current individual
        auto current = nests[cnestindex].NestWorkers[cindindex];
        Individual& cf{nests[cnestid].NestWorkers[cindindex]};

        gtime = next_event.time;

        // DUMMY FUNCTIONS HERE FOR NOW
        cf.t_next += 1.0;
        // Push to queue

        std::cout << "Nest ID: " << cf.nest_id << ", Individual ID: " << cf.ind_id 
          << ", t_birth: " << cf.t_birth << ", t_next: " << cf.t_next << std::endl;


        event_queue.push(cf);
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


#endif /* Population_hpp */