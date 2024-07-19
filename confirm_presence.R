# THIS FILE READS A MAPPING DUAL FILE
# AND THEN LOOPS THROUGH SIMULATION FOLDERS
# TO REMOVE THE ONES THAT DIDNT COPY CORRECTLY
# ANOTHER PART OF IT READS THROUGH THE DATA
# AND MAKES SURE THERE ARE ACTUAL DATAPOINTS IN LOU

library(dplyr)
mapping <- read.csv("mapping_dual.csv")

#### This part checks ONLY if file is present or not ####
mapping$evolution <- 0
mapping$parameter <- 0
mapping$deadnest <- 0
mapping$finstate <- 0
# uncomment line below if conditions not predefined
mapping$condition <- ""
# mapping$oneofem <- 0

for (i in seq(1:dim(mapping)[1])) {
  deadnest <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_deadNests.csv", full.names = TRUE)
  evol <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_evolution.csv", full.names = TRUE)
  param <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_parameter.csv", full.names = TRUE)
  finstate <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_finState.csv", full.names = TRUE)
  
  mapping$evolution[i] = length(evol)
  mapping$deadnest[i] = length(deadnest)
  mapping$parameter[i] = length(param)
  mapping$finstate[i] = length(finstate)
}

for (i in seq(1:dim(mapping)[1])) {
  if (!(mapping$evolution[i] | mapping$deadnest[i] | mapping$parameter[i] | mapping$finstate[i])) {
    print(paste0("Check folder ",mapping$X[i]))
    mapping$condition[i] = NA
  }
}
write.csv(mapping, "mapping_condition.csv", row.names = FALSE)

#### Data check condition ####
# This checks if there is active data in the file #
# or only headers #
# Saves two files, one only boolean and another with row number
# details

mapping <- read.csv("mapping_dual.csv")
mapping$evolution <- 0
mapping$parameter <- 0
mapping$deadnest <- 0
mapping$finstate <- 0
mapping$condition <- ""
mapping$absolute <- 0

mapping_row <- mapping
for (i in seq(1:dim(mapping)[1])) {
  print(i)
  deadnest <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_deadNests.csv", full.names = TRUE)
  evol <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_evolution.csv", full.names = TRUE)
  param <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_parameter.csv", full.names = TRUE)
  finstate <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_finState.csv", full.names = TRUE)
  
  if (length(deadnest) > 0) {
    num_rows <- dim(read.csv(deadnest[1], row.names = NULL))[1]
    if (num_rows > 1) {
      mapping$deadnest[i] = 1
      mapping_row$deadnest[i] = num_rows
    }
  }
  
  if (length(evol) > 0) {
    num_rows <- dim(read.csv(evol[1]))[1]
    if (num_rows > 1) {
      mapping$evolution[i] = 1
      mapping_row$evolution[i] = num_rows
    }
  }
  
  if (length(param) > 0) {
    num_rows <- dim(read.csv(param[1]))[1]
    if (num_rows >= 1) {
      mapping$parameter[i] = 1
      mapping_row$parameter[i] = num_rows
    }
  }
  
  if (length(finstate) > 0) {
    num_rows <- dim(read.csv(finstate[1]))[1]
    if (num_rows >= 1) {
      mapping$finstate[i] = 1
      mapping_row$finstate[i] = num_rows
    }
  }
}

for (i in seq(1:dim(mapping)[1])) {
  if (!(mapping$evolution[i] | mapping$deadnest[i] | mapping$parameter[i] | mapping$finstate[i])) {
    print(paste0("Check folder ",mapping$X[i]))
    mapping$condition[i] = NA
  }
  if (mapping$evolution[i] & mapping$deadnest[i] & mapping$parameter[i] & mapping$finstate[i]){
    mapping$absolute[i] = 1
    mapping_row$absolute[i] = 1
  }
}

write.csv(mapping, "mapping_noDat.csv", row.names = FALSE)
write.csv(mapping_row, "mapping_rows.csv", row.names = FALSE)

