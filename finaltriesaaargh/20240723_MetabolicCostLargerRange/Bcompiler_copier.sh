#!/bin/bash

#### SLURM settings ####
#SBATCH -J mysimplejob           # Job name
#SBATCH -o ./firstscript.out    # Specify stdout output file (%j expands to jobId)
#SBATCH -p parallel              # Queue name
#SBATCH -t 00:15:00              # Run time (hh:mm:ss) - 20 hours
#SBATCH --mem 500M
#SBATCH -A m2_jgu-tee            # Specify allocation to charge against

num_tot=4200

module load lang/R
module load compiler/GCC/11.2.0

Rscript Rcreate_sim_explorer.R

# Compile the program
g++ -std=c++2a -O2 Random.hpp main.cpp Parameters.hpp Individual.hpp Population.hpp config_parser.h -o myprog -lstdc++fs

# Check if compilation was successful
if [ $? -ne 0 ]; then
  echo "Compilation failed"
  exit 1
fi

# Ensure the binary has execution permissions
chmod +x myprog

# Print out the architecture of the node
uname -m

# Print out the file type of the binary
file ./myprog

# Function to copy files with retry mechanism
copy_with_retry() {
  local src=$1
  local dest=$2
  local max_retries=5
  local count=0

  while [ $count -lt $max_retries ]; do
    cp $src $dest
    if [ $? -eq 0 ]; then
      echo "Successfully copied $src to $dest"
      return 0
    else
      echo "Failed to copy $src to $dest. Retrying..."
      ((count++))
      # sleep 1  # wait for a second before retrying
    fi
  done

  echo "Failed to copy $src to $dest after $max_retries attempts"
  exit 1
}

# Create the output directory if it does not exist
mkdir -p output

for ((i=1; i<=num_tot; i++))
do
   
   # Copy the binary to the subdirectory
   copy_with_retry ./myprog ./output/${i}/myprog
   
   # Ensure the binary has execution permissions in the new directory
   chmod +x ./output/${i}/myprog
done
