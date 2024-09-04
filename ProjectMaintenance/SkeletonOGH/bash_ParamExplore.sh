#!/bin/bash

#### SLURM settings ####
#SBATCH --ntasks=1
#SBATCH --job-name=BaseTransSurv
#SBATCH --output=slurm.%j.out
#SBATCH --time=1-20:00:00
#SBATCH --mem=15GB
#SBATCH --array=1-18
#SBATCH --partition=regular

module load  R/4.3.2-gfbf-2023a
module load foss/2023a
module load Qt5/5.15.7-GCCcore-12.2.0
module load tbb/2020.3-GCCcore-11.2.0
module load Eigen/3.4.0-GCCcore-12.3.0

g++ -std=c++2a -O2 Haplotype.hpp Random.hpp main.cpp Parameters.hpp Individual.hpp Population.hpp config_parser.h -o myprog
chmod +x myprog

parSet=$SLURM_ARRAY_TASK_ID

mkdir $parSet  
cd $parSet
cp ../myprog .
cp ../create_sim_script.R .
cp ../create_ini.R .
Rscript create_sim_script.R ${parSet}
chmod +x myprog
./myprog config.ini