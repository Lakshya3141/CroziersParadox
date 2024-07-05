#!/bin/bash

#### SLURM settings ####
#SBATCH --job-name=FirstOutput
#SBATCH --output=individual.out
#SBATCH --time=07:00:00
#SBATCH --mem=2GB
#SBATCH --partition=regular

module load  R/4.3.2-gfbf-2023a
module load foss/2023a

Rscript create_ini.R
g++ -std=c++2a -O2 Random.hpp main.cpp Parameters.hpp Individual.hpp Population.hpp config_parser.h -o myprog
chmod +x myprog
./myprog config.ini
