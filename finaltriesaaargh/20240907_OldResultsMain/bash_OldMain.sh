#!/bin/bash

#### SLURM settings ####
#SBATCH --ntasks=1
#SBATCH --job-name=BaseTransSurv
#SBATCH --output=slurm.%j.out
#SBATCH --time=20:00:00
#SBATCH --mem=1GB
#SBATCH --array=1-810
#SBATCH --partition=regular

module load R/4.3.2-gfbf-2023a
module load foss/2023a

# Compile the program
g++ -std=c++2a -O2 Random.hpp main.cpp Parameters.hpp Individual.hpp Population.hpp config_parser.h -o myprog

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

parSet=$SLURM_ARRAY_TASK_ID

# Create directory and move into it
mkdir $parSet  
cd $parSet

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
      sleep 1  # wait for a second before retrying
    fi
  done

  echo "Failed to copy $src to $dest after $max_retries attempts"
  exit 1
}

# Copy files with retry
copy_with_retry ../myprog ./myprog
copy_with_retry ../create_sim_script_OldMain.R ./create_sim_script_OldMain.R
copy_with_retry ../create_ini.R ./create_ini.R

# Ensure the binary has execution permissions again (in the new directory)
chmod +x myprog

# Run the R script
Rscript create_sim_script_OldMain.R ${parSet}

# Run the binary with config.ini
./myprog config.ini
