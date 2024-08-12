#!/bin/bash

#### SLURM settings ####
#SBATCH -J mysimplejob           # Job name
#SBATCH -o ./slurm_output/mysimplejob.%A_%a.out    # Specify stdout output file (%j expands to jobId)
#SBATCH -p parallel              # Queue name
#SBATCH -N 1                     # Total number of nodes requested (20 cores/node on a standard Broadwell-node)
#SBATCH -n 1                     # Total number of tasks
#SBATCH --array=1-5640
#SBATCH -t 00:40:00              # Run time (hh:mm:ss) - 0.5 hours
#SBATCH --mem 500M
#SBATCH -A m2_jgu-tee            # Specify allocation to charge against

module load compiler/GCC/11.2.0

parSet=$((SLURM_ARRAY_TASK_ID+5640))

# directory and move into it
 
cd ./output/${parSet}

# Ensure the binary has execution permissions again (in the new directory)
chmod +x myprog

# Run the binary with config.ini
./myprog config.ini