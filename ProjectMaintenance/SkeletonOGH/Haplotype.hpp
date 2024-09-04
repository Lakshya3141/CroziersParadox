//
//  Haplotype.hpp
//  OGH_Eusociality
//
//  Created by Lakshya Chauhan on 25/09/2023.
//  Copyright © 2023 Lakshya Chauhan. All rights reserved.
//  -> Defined one gene set (haplotype?) of an individual, and associated functions
//

#ifndef Haplotype_hpp
#define Haplotype_hpp

#include "Parameters.hpp"
#include "Random.hpp"
#include "Splines.hpp"

using haplotype_choice_type = Eigen::Matrix<double, n_knots, 1>; // we use the signal one
// CP: This is a definition where we will have the n genes for 

// NOTE: initialiser lists are computtionally efficient compared to declaring body
class Haplotype {
    public:
    // Default constructor for haplotype
    Haplotype() : genes_dispersal{dInitDispersal}, haplotype_choice{init_haplo_choice()}, neutral_gene{0.0} {}

    double genes_dispersal;                     // dispersal propensity gene
    haplotype_choice_type haplotype_choice;     // Trait set for defining choice spline
    double neutral_gene;                        // selectively neutral gene for relatedness calculation
    
    haplotype_choice_type init_haplo_choice();  // Initalise the trait set for choice spline
    void mutate(const params& p);               // mutate function
};

// Initialiser function for trait set for choice spline
haplotype_choice_type Haplotype::init_haplo_choice() {
    haplotype_choice_type init_matrix;
    for (int i = 0; i < n_knots; ++i) {
        init_matrix(i, 0) = 0.0;
    }
    return init_matrix;
}

// mutate function
void Haplotype::mutate(const params& p) {
    // mutation for dispersal gene
    if (bernoulli(p.dMutRate)) genes_dispersal += normal(p.dMutBias, p.dMutEffect);
    // mutation for task choice knot values
    for (int i = 0; i < n_knots; ++i) {
        if (bernoulli(p.dMutRate)) haplotype_choice(i, 0) += normal(p.dMutBias, p.dMutEffect);
    }
    if (bernoulli(p.dMutRate)) neutral_gene += normal(0, p.dMutEffect);
}

#endif /* Haplotype_hpp */
