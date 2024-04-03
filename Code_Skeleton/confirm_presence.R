# THIS FILE READS A MAPPING DUAL FILE
# AND THEN LOOPS THROUGH SIMULATION FOLDERS
# TO REMOVE THE ONES THAT DIDNT COPY CORRECTLY
# ANOTHER PART OF IT READS THROUGH THE DATA
# AND MAKES SURE THERE ARE ACTUAL DATAPOINTS IN LOU

library(dplyr)
mapping <- read.csv("mapping_dual.csv")

#### This part checks ONLY if file is present or not ####
mapping$evolution <- 0
mapping$lou <- 0
mapping$deadInd <- 0
# uncomment line below if conditions not predefined
# mapping$condition <- ""
mapping$oneofem <- 0

for (i in seq(1:dim(mapping)[1])) {
  deadInd <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_deadIndividuals.csv", full.names = TRUE)
  evol <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_evolution.csv", full.names = TRUE)
  lou <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_LastOfUs.csv", full.names = TRUE)
  
  mapping$evolution[i] = length(deadInd)
  mapping$lou[i] = length(lou)
  mapping$deadInd[i] = length(evol)
}

for (i in seq(1:dim(mapping)[1])) {
  if (!(mapping$evolution[i] | mapping$lou[i] | mapping$deadInd[i])) {
    print(paste0("Check folder ",mapping$X[i]))
    mapping$condition[i] = NA
  }
  if ((mapping$evolution[i] | mapping$lou[i] | mapping$deadInd[i])) {
    print(paste0("Can map ",mapping$X[i]))
    mapping$oneofem[i] = 1
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
mapping$lou <- 0
mapping$deadInd <- 0
# mapping$condition <- ""
mapping$oneofem <- 0

mapping_row <- mapping
for (i in seq(1:dim(mapping)[1])) {
  print(i)
  deadInd <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_deadIndividuals.csv", full.names = TRUE)
  evol <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_evolution.csv", full.names = TRUE)
  lou <- list.files(paste0(getwd(),"/",mapping$X[i],"/output_sim"), pattern = "_LastOfUs.csv", full.names = TRUE)
  
  if (length(deadInd) > 0) {
    num_rows <- dim(read.csv(deadInd[1]))[1]
    if (num_rows > 1) {
      mapping$deadInd[i] = 1
      mapping_row$deadInd[i] = num_rows
    }
  }
  
  if (length(evol) > 0) {
    num_rows <- dim(read.csv(evol[1]))[1]
    if (num_rows > 1) {
      mapping$evolution[i] = 1
      mapping_row$evolution[i] = num_rows
    }
  }
  
  if (length(lou) > 0) {
    num_rows <- dim(read.csv(lou[1]))[1]
    if (num_rows > 1) {
      mapping$lou[i] = 1
      mapping_row$lou[i] = num_rows
    }
  }
}

for (i in seq(1:dim(mapping)[1])) {
  if (!(mapping$evolution[i] | mapping$lou[i] | mapping$deadInd[i])) {
    print(paste0("Check folder ",mapping$X[i]))
    mapping$condition[i] = NA
  }
  if ((mapping$evolution[i] | mapping$lou[i] | mapping$deadInd[i])) {
    print(paste0("Can map ",mapping$X[i]))
    mapping$oneofem[i] = 1
  }
}

write.csv(mapping, "mapping_noDat.csv", row.names = FALSE)
write.csv(mapping_row, "mapping_rows.csv", row.names = FALSE)

# #### NumRows data ####
# mapping <- read.csv("mapping_dual.csv")
# mapping$evolution <- 0
# mapping$lou <- 0
# mapping$deadInd <- 0
# # mapping$condition <- ""
# mapping$oneofem <- 0
# for (i in seq(1:dim(mapping)[1])) {
#   deadInd <- list.files(paste0(getwd(),"/",mapping$X[i]), pattern = "_deadIndividuals.csv", full.names = TRUE)
#   evol <- list.files(paste0(getwd(),"/",mapping$X[i]), pattern = "_evolution.csv", full.names = TRUE)
#   lou <- list.files(paste0(getwd(),"/",mapping$X[i]), pattern = "_LastOfUs.csv", full.names = TRUE)
#   
#   if (length(deadInd) > 0) {
#     num_rows <- dim(read.csv(deadInd[1]))[1]
#     if (num_rows > 1) {
#       mapping$deadInd[i] = num_rows
#     }
#   }
#   
#   if (length(evol) > 0) {
#     num_rows <- dim(read.csv(evol[1]))[1]
#     if (num_rows > 1) {
#       mapping$evolution[i] = num_rows
#     }
#   }
#   
#   if (length(lou) > 0) {
#     num_rows <- dim(read.csv(lou[1]))[1]
#     if (num_rows > 1) {
#       mapping$lou[i] = num_rows
#     }
#   }
# }
# 
# write.csv(mapping, "mapping_condition_rows.csv", row.names = FALSE)