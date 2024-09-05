# CroziersParadox
 Code for Lakshya's final semester thesis on resolving crozier's paradox

## Contents
1) Main folder files: Base scripts required to run a single instance of simulation
2) SlurmParallelExploration folder: Contains R and Bash Scripts for parallel exploration of parameters
3) PlottingAndAnalysis: Contains files to combine, plot and analyse results from slurm output
4) ProjectMaintenance: Additonal literature, presentations and reports for thesis requirements

## Running a single instance of simulation
1) Edit parameters as per requirement in the Rcreate_ini.R script and run it#
2) Run the main.cpp file with all header dependencies and config.ini as input file.
3) A new folder output_sim will be created with three different files and simulation ID seed as the initial part of the file name.

## Running multiple parameter explorations on SLURM
1) Move all files from SlurmParallelExploration folder to main folder
2) Edit parameter explorations as required in Rcreate_sim_explorer.R
3) Change the total number of sims in bash scripts based on the R script earlier.
4) Run Bcompiler_copier.sh followed by Bcode_runner.sh

## Combining results and plotting
1) Move all files from PlottingAndAnalsysis folder to main folder
2) Run Bcombining_results.sh, this creates a combined csv file of final population values
3) Different files correspond to different box plots, time series or linear model analyses

   
