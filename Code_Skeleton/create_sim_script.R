source("create_ini.R")

# example parameter exploration here:
# dForagingTime <- c(4, 10)
# dBroodingTime <- c(4.0, 10.0)
# dTransitionForagingBrooding <- c(1.0, 5.0)
# dTransitionBroodingForaging <- c(1, 5)
dSurvTransitionForagingBrooding <- seq(0.9, 1.0, 0.05)
# dSurvTransitionBroodingForaging <- c(0.99, 0.97)
# dSurvForage <- c()
# dSurvBrood <- c()
dForagingMean <- c(0.5, 80)
# dForagingSD <- c()
# dLarvaMatureSize <- c(1.0, 2.0)
# dDeathTime <- seq(2.0, 10.0, 8.0)
replicates <- c(1:3)

#### Create param grid ####
param_grid <- expand.grid(dfm = dForagingMean, dstfb = dSurvTransitionForagingBrooding, rp = replicates)
param_grid$condition <- ""

#### Add condition names that make graphing easier ####
for (i in 1:dim(param_grid)[1]) {
  if (param_grid$dfm[i] == 0.5) {
    param_grid$condition[i] <- paste0("lM_TS",param_grid$dstfb[i]*100)
  } else {
    param_grid$condition[i] <- paste0("hM_TS",param_grid$dstfb[i]*100)
  }
}
write.csv(param_grid, "mapping_dual.csv")

# read in the parameters from the command line:
args = commandArgs(trailingOnly = TRUE)
sim_number = as.numeric(args[[1]])

focal_dForagingMean <- param_grid$dfm[sim_number]
focal_dTransitionForagingBrooding <- param_grid$dtfb[sim_number]
focal_dSurvTransition <- param_grid$dstfb[sim_number]

create_config(dForagingMean = focal_dForagingMean,
              dSurvTransitionBroodingForaging = focal_dSurvTransition,
              dSurvTransitionForagingBrooding = focal_dSurvTransition,
              params_to_record = "dForagingMean,dSurvTransitionBroodingForaging,dSurvTransitionForagingBrooding")

# done
