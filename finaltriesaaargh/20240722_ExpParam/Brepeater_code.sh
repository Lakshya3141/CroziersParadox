#!/bin/bash

#### SLURM settings ####
#SBATCH -J mysimplejob           # Job name
#SBATCH -o ./slurm_output/mysimplejob.%A_%a.out    # Specify stdout output file (%j expands to jobId)
#SBATCH -p parallel              # Queue name
#SBATCH -N 1                     # Total number of nodes requested (20 cores/node on a standard Broadwell-node)
#SBATCH -n 1                     # Total number of tasks
#SBATCH --array=1-34
#SBATCH -t 00:50:00              # Run time (hh:mm:ss) - 0.5 hours
#SBATCH --mem 500M
#SBATCH -A m2_jgu-tee            # Specify allocation to charge against

module load compiler/GCC/11.2.0
parSet=$SLURM_ARRAY_TASK_ID

# directory and move into it
repeat=(1050 1055 1060 1080 1115 1135 1175 1245 1350 1355 1360 1415 1480 155 210 215 25 335 40 450 455 460 515 520 575 635 653 690 755 815 865 899 935 990)

# Convert 1-based SLURM_ARRAY_TASK_ID to 0-based index for the array
spec_repeat=${repeat[$((parSet - 1))]}

# Move into the specified directory
cd ./output/${spec_repeat} || { echo "Directory not found: ./output/${spec_repeat}"; exit 1; }

# Ensure the binary has execution permissions again (in the new directory)
chmod +x myprog

# Run the binary with config.ini
rm -r ./output_sim
./myprog config.ini