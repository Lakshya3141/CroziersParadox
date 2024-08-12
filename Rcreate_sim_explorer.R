source("Rcreate_ini.R")

#### Base param grid ####
iKillChoice <- c(0, 1)
iConstStockChoice <- c(2)
iFoodReset <- c(1)
iRepChoice <- c(0)
dTickTime <- c(1, 2, 4)
dConstantPopStock <- c(50)
dMutationStrengthCues <- c(5)
dFracKilled <- c(0.4)
dMetabolicCost <- c(40)
dExpParam <- c(0.1)
iModelChoice <- c(0, 1, 2, 3, 4, 5, 6)
replicates <- c(1:10)

base_grid <- expand.grid(
  iKC = iKillChoice, 
  iCSC = iConstStockChoice,
  iFR = iFoodReset,
  iRC = iRepChoice,
  dTT = dTickTime,
  dCPS = dConstantPopStock, 
  dMSC = dMutationStrengthCues, 
  dFK = dFracKilled,
  dMC = dMetabolicCost,
  dEP = dExpParam, 
  iMC = iModelChoice, 
  rp = replicates
)

#### dMetabolicCost param grid ####
iKillChoice <- c(0, 1)
iConstStockChoice <- c(2)
iFoodReset <- c(1)
iRepChoice <- c(0)
dTickTime <- c(1, 2, 4)
dConstantPopStock <- c(50)
dMutationStrengthCues <- c(5)
dFracKilled <- c(0.4)
dMetabolicCost <- c(1, 10, 20, 40, 80, 200)
dExpParam <- c(0.1)
iModelChoice <- c(0, 1, 2, 3, 4, 5, 6)
replicates <- c(1:10)

dMC_grid <- expand.grid(
  iKC = iKillChoice, 
  iCSC = iConstStockChoice,
  iFR = iFoodReset,
  iRC = iRepChoice,
  dTT = dTickTime,
  dCPS = dConstantPopStock, 
  dMSC = dMutationStrengthCues, 
  dFK = dFracKilled,
  dMC = dMetabolicCost,
  dEP = dExpParam, 
  iMC = iModelChoice, 
  rp = replicates
)

#### dMutationStrengthCues param grid ####
iKillChoice <- c(0, 1)
iConstStockChoice <- c(2)
iFoodReset <- c(1)
iRepChoice <- c(0)
dTickTime <- c(1, 2, 4)
dConstantPopStock <- c(50)
dMutationStrengthCues <- c(0.1, 0.5, 1, 5, 10)
dFracKilled <- c(0.4)
dMetabolicCost <- c(40)
dExpParam <- c(0.1)
iModelChoice <- c(0, 1, 2, 3, 4, 5, 6)
replicates <- c(1:10)

dMSC_grid <- expand.grid(
  iKC = iKillChoice, 
  iCSC = iConstStockChoice,
  iFR = iFoodReset,
  iRC = iRepChoice,
  dTT = dTickTime,
  dCPS = dConstantPopStock, 
  dMSC = dMutationStrengthCues, 
  dFK = dFracKilled,
  dMC = dMetabolicCost,
  dEP = dExpParam, 
  iMC = iModelChoice, 
  rp = replicates
)

#### dFracKilled param grid ####
iKillChoice <- c(0, 1)
iConstStockChoice <- c(2)
iFoodReset <- c(1)
iRepChoice <- c(0)
dTickTime <- c(1, 2, 4)
dConstantPopStock <- c(50)
dMutationStrengthCues <- c(5)
dFracKilled <- c(0.1, 0.3, 0.5, 0.7, 0.9)
dMetabolicCost <- c(40)
dExpParam <- c(0.1)
iModelChoice <- c(0, 1, 2, 3, 4, 5, 6)
replicates <- c(1:10)

dFK_grid <- expand.grid(
  iKC = iKillChoice, 
  iCSC = iConstStockChoice,
  iFR = iFoodReset,
  iRC = iRepChoice,
  dTT = dTickTime,
  dCPS = dConstantPopStock, 
  dMSC = dMutationStrengthCues, 
  dFK = dFracKilled,
  dMC = dMetabolicCost,
  dEP = dExpParam, 
  iMC = iModelChoice, 
  rp = replicates
)

#### iFoodReset and iRepChoice param grid ####
iKillChoice <- c(0, 1)
iConstStockChoice <- c(2)
iFoodReset <- c(0, 1)
iRepChoice <- c(0, 2)
dTickTime <- c(1, 2, 4)
dConstantPopStock <- c(50)
dMutationStrengthCues <- c(5)
dFracKilled <- c(0.4)
dMetabolicCost <- c(40)
dExpParam <- c(0.1)
iModelChoice <- c(0, 1, 2, 3, 4, 5, 6)
replicates <- c(1:10)

iFR_iRC_grid <- expand.grid(
  iKC = iKillChoice, 
  iCSC = iConstStockChoice,
  iFR = iFoodReset,
  iRC = iRepChoice,
  dTT = dTickTime,
  dCPS = dConstantPopStock, 
  dMSC = dMutationStrengthCues, 
  dFK = dFracKilled,
  dMC = dMetabolicCost,
  dEP = dExpParam, 
  iMC = iModelChoice, 
  rp = replicates
)

#### ConstFood param grid ####
iKillChoice <- c(0, 1)
iConstStockChoice <- c(1)
iFoodReset <- c(0, 1)
iRepChoice <- c(0, 2)
dTickTime <- c(2)
dConstantPopStock <- c(1, 5, 10, 25, 50, 75, 100, 200, 500)
dMutationStrengthCues <- c(5)
dFracKilled <- c(0.4)
dMetabolicCost <- c(40)
dExpParam <- c(0.1)
iModelChoice <- c(0, 1, 2, 3)
replicates <- c(1:10)

ConstFood_grid <- expand.grid(
  iKC = iKillChoice, 
  iCSC = iConstStockChoice,
  iFR = iFoodReset,
  iRC = iRepChoice,
  dTT = dTickTime,
  dCPS = dConstantPopStock, 
  dMSC = dMutationStrengthCues, 
  dFK = dFracKilled,
  dMC = dMetabolicCost,
  dEP = dExpParam, 
  iMC = iModelChoice, 
  rp = replicates
)

#### Combine all grids into one param_grid ####
param_grid <- rbind(
  dMC_grid,
  dMSC_grid,
  dFK_grid,
  iFR_iRC_grid,
  ConstFood_grid
)

#### Create a CSV mapping file ####
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
  focal_iCSC <- param_grid$iCSC[i]
  focal_iFR <- param_grid$iFR[i]
  focal_iRC <- param_grid$iRC[i]
  focal_dCPS <- param_grid$dCPS[i]
  focal_dFK <- param_grid$dFK[i]
  focal_dMC <- param_grid$dMC[i]
  
  # Create a directory for the current simulation inside the output folder
  dir.create(file.path("output", as.character(i)))
  setwd(file.path("output", as.character(i)))
  
  # Create the config file
  create_config(
    dMutationStrengthCues = focal_dMSC, 
    dExpParam = focal_dEP, 
    dTickTime = focal_dTT, 
    iKillChoice = focal_iKC, 
    iModelChoice = focal_iMC,
    iConstStockChoice = focal_iCSC,
    iFoodReset = focal_iFR,
    iRepChoice = focal_iRC,
    dConstantPopStock = focal_dCPS,
    dFracKilled = focal_dFK,
    dMetabolicCost = focal_dMC,
    params_to_record = "iKillChoice,iModelChoice,iRepChoice"
  )
  
  # Change back to the parent directory
  setwd("../..")
}

# done
