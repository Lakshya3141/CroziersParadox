source("Rcreate_ini.R")

# Example parameter exploration
dMetabolicCost <- c(20, 40, 80)
dConstantPopStock <- c(20, 50, 80)
dMutationStrengthCues <- c(1, 5, 10)
iKillChoice <- c(0, 1)
iModelChoice <- c(0, 1, 2, 3, 4, 5, 6)
replicates <- c(1:25)

#### Create param grid ####
param_grid <- expand.grid(dMC = dMetabolicCost, dCPS = dConstantPopStock, dMCS = dMutationStrengthCues, iKC = iKillChoice, iMC = iModelChoice, rp = replicates)

# Create a CSV mapping file
write.csv(param_grid, "mapping_dual.csv", row.names = FALSE)

# Create the output directory if it does not exist
if (!dir.exists("output")) {
  dir.create("output")
}

if (!dir.exists("slurm_output")) {
  dir.create("slurm_output")
}

if (!dir.exists("additional")) {
  dir.create("additional")
}

# Loop over each row of the param grid
for (i in 1:nrow(param_grid)) {
  print(i)
  # Extract parameters for the current row
  focal_dMC <- param_grid$dMC[i]
  focal_dCPS <- param_grid$dCPS[i]
  focal_dMCS <- param_grid$dMCS[i]
  focal_iKC <- param_grid$iKC[i]
  focal_iMC <- param_grid$iMC[i]
  
  # Create a directory for the current simulation inside the output folder
  dir.create(file.path("output", as.character(i)))
  setwd(file.path("output", as.character(i)))
  
  # Create the config file
  create_config(dMetabolicCost = focal_dMC, dMutationStrengthCues = focal_dMCS, dConstantPopStock = focal_dCPS, iKillChoice = focal_iKC, iModelChoice = focal_iMC,
                params_to_record = "iModelChoice,dMetabolicCost,dMutationStrengthCues,dConstantPopStock,iKillChoice")
  
  # Change back to the parent directory
  setwd("../..")
}

# done
