# Ensure that scientific notation is disabled
options(scipen = 999)

# Function to create a configuration file with default or specified values
create_config <- function(config_file_name = "config.ini",
                          dFracKilled = 0.4,
                          dMetabolicCost = 40.0,
                          dMutationStrength = 1.0,
                          dFracIndMutStrength = 0.1,
                          dMutBias = 0.0,
                          iNumWorkers = 5,
                          iNumCues = 5,
                          iNumColonies = 5,
                          dInitNestStock = 25.0,
                          dInitFoodStock = 300.0,
                          dExpParam = 0.1,
                          dMeanActionTime = 1.0,
                          dRatePopStock = 5.0,
                          dRateNestStock = 0.0/24.0,
                          iModelChoice = 0.0,
                          iTolChoice = 2.0,
                          iKillChoice = 1,
                          iRepChoice = 2,
                          iFoodResetChoice = 0,
                          params_to_record = "dFracKilled,dMetabolicCost") {
  
  # Create a list to hold the parameters
  newini <- list()
  
  # Add the parameters to the list
  newini[["params"]] <- list("dFracKilled" = dFracKilled,
                             "dMetabolicCost" = dMetabolicCost,
                             "dMutationStrength" = dMutationStrength,
                             "dFracIndMutStrength" = dFracIndMutStrength,
                             "dMutBias" = dMutBias,
                             "iNumWorkers" = iNumWorkers,
                             "iNumCues" = iNumCues,
                             "iNumColonies" = iNumColonies,
                             "dInitNestStock" = dInitNestStock,
                             "dInitFoodStock" = dInitFoodStock,
                             "dExpParam" = dExpParam,
                             "dMeanActionTime" = dMeanActionTime,
                             "dRatePopStock" = dRatePopStock,
                             "dRateNestStock" = dRateNestStock,
                             "iModelChoice" = iModelChoice,
                             "iTolChoice" = iTolChoice,
                             "iKillChoice" = iKillChoice,
                             "iRepChoice" = iRepChoice,
                             "iFoodResetChoice" = iFoodResetChoice,
                             "params_to_record" = params_to_record)
  
  # Write the list to an INI file
  ini::write.ini(newini, config_file_name)
}

# Call the function to create the configuration file with default values
create_config(config_file_name = "config.ini")

