source("Rcreate_ini.R")

# Example parameter exploration
dMutationStrengthCues <- c(0.1, 0.5, 1, 5 ,10)
dTickTime <- c(2, 4)
dExpParam <- c(0.1)
iKillChoice <- c(0, 1)
iModelChoice <- c(0, 1, 2, 3, 5, 6)
replicates <- c(1:25)

#### Create param grid ####
param_grid <- expand.grid(dMSC = dMutationStrengthCues, dTT = dTickTime, dEP = dExpParam, iKC = iKillChoice, iMC = iModelChoice, rp = replicates)

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
  focal_dMSC <- param_grid$dMSC[i]
  focal_dTT <- param_grid$dTT[i]
  focal_dEP <- param_grid$dEP[i]
  focal_iKC <- param_grid$iKC[i]
  focal_iMC <- param_grid$iMC[i]
  
  # Create a directory for the current simulation inside the output folder
  dir.create(file.path("output", as.character(i)))
  setwd(file.path("output", as.character(i)))
  
  # Create the config file
  create_config(dMutationStrengthCues = focal_dMSC, dExpParam = focal_dEP, dTickTime = focal_dTT, iKillChoice = focal_iKC, iModelChoice = focal_iMC,
                params_to_record = "iModelChoice,dMutationStrength,dExpParam,dTickTime,iKillChoice")
  
  # Change back to the parent directory
  setwd("../..")
}

# done
