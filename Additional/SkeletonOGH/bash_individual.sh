#!/bin/bash

#### SLURM settings ####
#SBATCH --job-name=FirstOutput
#SBATCH --output=individual.out
#SBATCH --time=05:00:00
#SBATCH --mem=200GB
#SBATCH --partition=regular

module load  R/4.3.2-gfbf-2023a
module load foss/2023a
module load Qt5/5.15.7-GCCcore-12.2.0
module load tbb/2020.3-GCCcore-11.2.0
module load Eigen/3.4.0-GCCcore-12.3.0

Rscript create_ini.R
g++ -std=c++2a -O2 Haplotype.hpp Random.hpp main.cpp Parameters.hpp Individual.hpp Population.hpp config_parser.h -o myprog
chmod +x myprog
./myprog config.ini
