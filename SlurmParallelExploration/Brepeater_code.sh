#!/bin/bash

#### SLURM settings ####
#SBATCH -J mysimplejob           # Job name
#SBATCH -o ./slurm_output/mysimplejob.%A_%a.out    # Specify stdout output file (%j expands to jobId)
#SBATCH -p parallel              # Queue name
#SBATCH -N 1                     # Total number of nodes requested (20 cores/node on a standard Broadwell-node)
#SBATCH -n 1                     # Total number of tasks
#SBATCH --array=1-56
#SBATCH -t 00:50:00              # Run time (hh:mm:ss) - 0.5 hours
#SBATCH --mem 500M
#SBATCH -A m2_jgu-tee            # Specify allocation to charge against

module load compiler/GCC/11.2.0
parSet=$SLURM_ARRAY_TASK_ID

# directory and move into it
repeat=(1066 1165 1291 1292 1415 1417 1418 1444 1519 154 1540 1706 1795 1798 1811 1813 1884 1886 1921 1940 1943 2170 2175 2296 2297 2299 2312 2428 2443 246 2473 2518 2551 2567 2573 2643 28 280 2803 2806 2824 3036 3055 3094 31 3144 406 409 519 532 678 785 790 805 913 940)

# Convert 1-based SLURM_ARRAY_TASK_ID to 0-based index for the array
spec_repeat=${repeat[$((parSet - 1))]}

# Move into the specified directory
cd ./output/${spec_repeat} || { echo "Directory not found: ./output/${spec_repeat}"; exit 1; }

# Ensure the binary has execution permissions again (in the new directory)
chmod +x myprog

# Run the binary with config.ini
rm -r ./output_sim
./myprog config.ini