//
//  Individual.hpp
//  OGH_Eusociality
//
//  Created by Lakshya Chauhan on 26/09/2023.
//  Copyright © 2023 Lakshya Chauhan. All rights reserved.
//  Large code snippets borrowed from Ella Rees-Baylis
//  -> defines haplodiploid individuals (larvae and adults alike) and associated functions
//

#ifndef Individual_hpp
#define Individual_hpp

#include "Haplotype.hpp"

using diploid_genome = std::array<Haplotype, 2>;
using haploid_genome = std::array<Haplotype, 1>;

template <int Ploidy>
class Individual {
public:

    // Individual constructors
    // male and female default + initialised constructors overloaded
    Individual(const int id);
    Individual(const int id, const Individual<2>& mum, const params& p);   
    
    Haplotype sperm;                                // Male sperm from single mating instance
    std::array<Haplotype, Ploidy> genome;           // genome of individual with 1 or 2 haplotypes
    
    bool is_alive = true;       // Death status of adult individual
    bool is_larva = false;      // Maturity status of individual
    double t_death = -1.0;      // If next step is death of adult, death time; default is -1 to avoid confusions
    double t_next;              // Next update time of individual
    double t_birth = 0.0;       // Birth time of individual, 0 for initialiser population
    double td_larva = -1.0;     // death time of larva
    double tb_larva = -1.0;     // birth time of larva
    int ind_id;                 // Individual ID
    int mom_id = -1;            // Mother ID
    int dad_id = -1;            // Father ID
    unsigned int nest_id;       // Nest identifier
    int mate_id = -1;           // Mate ID
    double foraging_propensity; // Phenotypic propensity at particular larval value and time point
                                // Obtained by evaluating spline

    bool is_disperser = false;  // Disperser status of individual
    bool is_foraging = false;   // Foraging status of individual, breeder if false
    bool previous_task_is_forager = false;  // Previous task status
    bool is_mated = false;      // Mating status for female adults
    
    double body_size = 0.0;     // body size, used for larvae to decide maturation point
    int num_larva = 0;          // Number of larval offsprings
    int num_female_larva = 0;   // Number of female larval offsprings
    int num_mates = 0;          // Number of mates for males
    int num_choices = 0;        // Number of task choices made since maturation
    int num_foraging = 0;       // Number of foraging choices made since maturation
    // LC: if we implement continuous time update for foraging here,
    // Might make sense to add total_time_alive and time_spent_foraging as parameters
    Eigen:: Matrix<double, n_knots, 1> choice_phenotype;
    double phenotype_dispersal;

    // Individual funcions, names are self explanatory
    // more explanation given above function definition
    void mate(Individual<1>& male); 
    void mutate(const params& p);
    void calculate_phenotype();
    void survival(const params& p);
    bool check_mature(double& birth_time, const params& p);
    bool check_disperser();
    haplotype_choice_type init_phenotype_choice();

};

// Initialise choice_phenotype function
template<>
haplotype_choice_type Individual<2>::init_phenotype_choice() {
    haplotype_choice_type init_matrix;
    for (int i = 0; i < n_knots; ++i) {
        init_matrix(i, 0) = 0.0;
    }
    return init_matrix;
}

// calculate phenotype at larval birth by taking average across haplotypes
template<>
void Individual<2>::calculate_phenotype() {
    // If additive expression of genes
    if (bIsAdditive) {
        phenotype_dispersal = (genome[0].genes_dispersal + genome[1].genes_dispersal) * 0.5;      
        for (int i = 0; i < n_knots; ++i) {
            choice_phenotype(i,0) = (genome[0].haplotype_choice(i, 0) + genome[1].haplotype_choice(i, 0)) * 0.5;
        }
    } else {
        // Random paternal/maternal copy expression of genes
        phenotype_dispersal = genome[bernoulli()].genes_dispersal;
        for (int i = 0; i < n_knots; ++i) {
            choice_phenotype(i, 0) = genome[bernoulli(0.5)].haplotype_choice(i, 0);
        }
    }
}

// default constructor male
template <>
Individual<1>::Individual (const int id) : ind_id(id), t_death(-1.0) { }

// default constructor female
template <>
Individual<2>::Individual (const int id) : ind_id(id) {
    calculate_phenotype();
    choice_phenotype = init_phenotype_choice();
}

// constructor for males (haploid)
// assigns death time to larva too
template <>
Individual<1>::Individual (const int id, const Individual<2>& mum, const params& p) : is_larva(true), ind_id(id), mom_id(mum.ind_id), tb_larva(gtime) { //LD added initaliser to tb_larva
    // If locus-wise recombination
    if (bRecombLocus) {
        genome[0].genes_dispersal = mum.genome[bernoulli()].genes_dispersal;
        for(int i = 0; i < n_knots; ++i) {
            genome[0].haplotype_choice(i, 0) = mum.genome[bernoulli()].haplotype_choice(i, 0);
        }
        genome[0].neutral_gene = mum.genome[bernoulli()].neutral_gene;
    } else { // traitwise recombination
        // son inherits genesets from mum (with 50:50 chance of each geneset)
        genome[0].genes_dispersal = mum.genome[bernoulli()].genes_dispersal;
        genome[0].haplotype_choice = mum.genome[bernoulli(0.5)].haplotype_choice;
        genome[0].neutral_gene = mum.genome[bernoulli()].neutral_gene;
    }
    mutate(p);          // individual is created then mutates
    td_larva = tb_larva + exponential(p.dLarvaeLambda); //LD
}

// constructor for females (diploid)
// assigns death time to larva too
template <>
Individual<2>::Individual (const int id, const Individual<2>& mum, const params& p) : nest_id(mum.nest_id), is_larva(true), ind_id(id), mom_id(mum.ind_id), dad_id(mum.mate_id), tb_larva(gtime) { //LD added initaliser to tb_larva
    // daughter inherits one haplotype from sperm stored with mum
    genome[0] = mum.sperm;
    // If locuswise recombination
    if (bRecombLocus) {
        genome[1].genes_dispersal = mum.genome[bernoulli()].genes_dispersal;
        for(int i = 0; i < n_knots; ++i) {
            genome[1].haplotype_choice(i, 0) = mum.genome[bernoulli()].haplotype_choice(i, 0);
        }
        genome[1].neutral_gene = mum.genome[bernoulli()].neutral_gene;
    } else {
        // daughter inherits genesets from mum (with 50:50 chance of each geneset)
        genome[1].genes_dispersal = mum.genome[bernoulli()].genes_dispersal;
        genome[1].haplotype_choice = mum.genome[bernoulli()].haplotype_choice;
        genome[1].neutral_gene = mum.genome[bernoulli()].neutral_gene;
    }
    mutate(p);          // individual is created then mutates
    calculate_phenotype();
    td_larva = tb_larva + exponential(p.dLarvaeLambda);
}

// mate function, stores the male haploid genome as sperm
template <>
void Individual<2>::mate(Individual<1>& male) {
    sperm = male.genome[0]; // females store sperm from mate
    mate_id = male.ind_id;
    is_mated = true;
    male.num_mates++; // increase male mate count
    male.is_mated = true;
    male.num_mates++;
}

// mutate function
template <int Ploidy>
void Individual<Ploidy>::mutate(const params& p) {
    for (int i=0; i<Ploidy; ++i) {
        genome[i].mutate(p);
    }
}

// survival check for females based on their current task
template <>
void Individual<2>::survival(const params& p) {
    // If foraging and survives XOR reproducing and survives
    // condition probability applied checking for previous tasks and if transition occurs
    double aa = is_foraging ? p.dSurvForage : p.dSurvBrood;
    double bb = ((previous_task_is_forager && !is_foraging) ? p.dSurvTransitionBroodingForaging : 1.0);
    double cc = ((!previous_task_is_forager && is_foraging) ? p.dSurvTransitionForagingBrooding : 1.0);
    double survival_prob = aa*bb*cc;
    if (!bernoulli(survival_prob)) {
        is_alive = false;
        t_death = gtime + p.dDeathTime;
        t_next = t_death;
    }
}

// function to check maturity of male larvae after being fed
// Also assigns death time to males
template <> 
bool Individual<1>::check_mature(double& birth_time, const params& p) {
    if (body_size > p.dLarvaMatureSize) {
        is_larva = false;
        t_birth = birth_time + uni_real();
        t_death = birth_time + exponential(p.dMaleLambda);
        return true;
    }
    return false;
}

// function to check maturity of female larvae after being fed
template <> 
bool Individual<2>::check_mature(double& birth_time, const params& p) {
    if (body_size > p.dLarvaMatureSize) {
        is_larva = false;
        t_birth = birth_time + uni_real();
        return true;
    }
    return false;
}

// function to check disperser status of mature female larva
template <>
bool Individual<2>::check_disperser(){
    if (bernoulli(logistic(phenotype_dispersal))) { 
        is_disperser = true;
        return true;
    }
    return false;
}

#endif /* Individual_hpp */
