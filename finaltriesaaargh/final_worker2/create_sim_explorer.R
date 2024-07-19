source("create_ini.R")

# Example parameter exploration
dMutationStrengthCues <- c(1, 5, 20)
dMetabolicCost <- c(20, 40, 80)
dFracKilled <- c(0.1, 0.4, 0.8)
iKillChoice <- c(0, 1)
iModelChoice <- c(0, 1, 2)
replicates <- c(1:10)

#### Create param grid ####
param_grid <- expand.grid(dMSC = dMutationStrengthCues, dMC = dMetabolicCost, dFK = dFracKilled, iKC = iKillChoice, iMC = iModelChoice, rp = replicates)

# Create a CSV mapping file
write.csv(param_grid, "mapping_dual.csv", row.names = FALSE)

# Create the output directory if it does not exist
if (!dir.exists("output")) {
  dir.create("output")
}

if (!dir.exists("slurm_output")) {
  dir.create("slurm_output")
}

# Loop over each row of the param grid
for (i in 1:nrow(param_grid)) {
  print(i)
  # Extract parameters for the current row
  focal_dMSC <- param_grid$dMSC[i]
  focal_dMC <- param_grid$dMC[i]
  focal_dFK <- param_grid$dFK[i]
  focal_iKC <- param_grid$iKC[i]
  focal_iMC <- param_grid$iMC[i]
  
  # Create a directory for the current simulation inside the output folder
  dir.create(file.path("output", as.character(i)))
  setwd(file.path("output", as.character(i)))
  
  # Create the config file
  create_config(dMutationStrengthCues = focal_dMSC, dFracKilled = focal_dFK, dMetabolicCost = focal_dMC, iKillChoice = focal_iKC, iModelChoice = focal_iMC,
                params_to_record = "iModelChoice,dMutationStrength,dFracKilled,dMetabolicCost,iKillChoice")
  
  # Change back to the parent directory
  setwd("../..")
}

# done
