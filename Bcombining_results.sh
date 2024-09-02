#!/bin/bash

#### SLURM settings ####
#SBATCH -J mysimplejob           # Job name
#SBATCH -o ./slurm_output/combined_results.out    # Specify stdout output file (%j expands to jobId)
#SBATCH -p parallel              # Queue name
#SBATCH -t 02:00:00              # Run time (hh:mm:ss) - 20 hours
#SBATCH --mem 3G
#SBATCH -A m2_jgu-tee            # Specify allocation to charge against


module load lang/R

Rscript Rcombining_results.R