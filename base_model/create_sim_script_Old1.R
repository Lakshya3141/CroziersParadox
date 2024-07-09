source("create_ini.R")

# example parameter exploration here:
dMutationStrengthCues <- c(1, 5, 20)
dMetabolicCost <- c(20, 40, 80)
dFracKilled <- c(0.1, 0.4, 0.8)
iModelChoice <- c(0, 1, 2)
replicates <- c(1:3)

#### Create param grid ####
param_grid <- expand.grid(dMSC = dMutationStrengthCues, dMC = dMetabolicCost, dFK = dFracKilled, iMC = iModelChoice, rp = replicates)

# read in the parameters from the command line:
args = commandArgs(trailingOnly = TRUE)
sim_number = as.numeric(args[[1]])
write.csv(param_grid, "mapping_dual.csv")


focal_dMSC <- param_grid$dMSC[sim_number]
focal_dMC <- param_grid$dMC[sim_number]
focal_dFK <- param_grid$dFK[sim_number]
focal_iMC <- param_grid$iMC[sim_number]
create_config(dMutationStrengthCues = focal_dMSC, dFracKilled = focal_dFK, dMetabolicCost = focal_dMC, iModelChoice = focal_iMC,
              params_to_record = "iModelChoice,dMutationStrength,dFracKilled,dMetabolicCost")

# done
