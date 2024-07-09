#!/bin/bash

#### SLURM settings ####
#SBATCH --ntasks=1
#SBATCH --job-name=BaseTransSurv
#SBATCH --output=slurm.%j.out
#SBATCH --time=1-20:00:00
#SBATCH --mem=3GB
#SBATCH --array=1-81
#SBATCH --partition=regular

module load  R/4.3.2-gfbf-2023a
module load foss/2023a

g++ -std=c++2a -O2 Random.hpp main.cpp Parameters.hpp Individual.hpp Population.hpp config_parser.h -o myprog
chmod +x myprog

parSet=$SLURM_ARRAY_TASK_ID

mkdir $parSet  
cd $parSet
cp ../myprog .
cp ../create_sim_script_Old2.R .
cp ../create_ini.R .
Rscript create_sim_script_Old2.R ${parSet}
chmod +x myprog
./myprog config.ini