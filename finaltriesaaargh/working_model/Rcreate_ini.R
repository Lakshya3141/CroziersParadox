# Ensure that scientific notation is disabled
options(scipen = 999)

# Function to create a configuration file with default or specified values
create_config <- function(config_file_name = "config.ini",
                          dFracKilled = 0.4,
                          dMetabolicCost = 40.0,
                          dMutationStrength = 1.0,
                          dMutationStrengthCues = 1.0,
                          dFracIndMutStrength = 0.1,
                          dMutBias = 0.0,
                          iNumWorkers = 10,
                          iNumCues = 10,
                          iNumColonies = 50,
                          dInitNestStock = 25.0,
                          dInitFoodStock = 300.0,
                          dExpParam = 0.1,
                          dTickTime = 2,
                          dMeanActionTime = 1.0,
                          dRatePopStock = 0.0,
                          dConstantPopStock = 50.0,
                          dRateNestStock = 0.0 / 24.0,
                          iModelChoice = 0.0,
                          iTolChoice = 0.0,
                          iKillChoice = 1,
                          iRepChoice = 0,
                          iFoodResetChoice = 1,
                          iConstStockChoice = 2,
                          params_to_record = "iModelChoice,dMutationStrength,dFracKilled,dMetabolicCost") {
  
  # Create a list to hold the parameters
  newini <- list()
  
  # Add the parameters to the list
  newini[["params"]] <- list("dFracKilled" = dFracKilled,
                             "dMetabolicCost" = dMetabolicCost,
                             "dMutationStrength" = dMutationStrength,
                             "dMutationStrengthCues" = dMutationStrengthCues,
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
                             "dConstantPopStock" = dConstantPopStock,
                             "dTickTime" = dTickTime,
                             "dRateNestStock" = dRateNestStock,
                             "iModelChoice" = iModelChoice,
                             "iTolChoice" = iTolChoice,
                             "iKillChoice" = iKillChoice,
                             "iRepChoice" = iRepChoice,
                             "iFoodResetChoice" = iFoodResetChoice,
                             "iConstStockChoice" = iConstStockChoice,                             
                             "params_to_record" = params_to_record)
  
  # Write the list to an INI file
  ini::write.ini(newini, config_file_name)
  
  # Read the content of the INI file
  ini_content <- readLines(config_file_name)
  
  # Remove any extra empty lines at the end of the file
  cleaned_ini_content <- ini_content[ini_content != ""]
  
  # Write the cleaned content back to the INI file
  writeLines(cleaned_ini_content, config_file_name)
}

# Call the function to create the configuration file with default values
create_config(config_file_name = "config.ini")
