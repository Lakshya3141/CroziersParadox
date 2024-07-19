# Load necessary libraries
library(dplyr)
library(readr)

# Set the working directory to the results folder
# setwd("/path/to/results")  # Update with your actual path

# Get list of numbered directories
dirs <- list.dirs(path = ".", full.names = TRUE, recursive = FALSE)

# Initialize an empty list to store combined data and failed directories
combined_data <- list()
combined_finstates <- list()
failed_dirs <- list()
failed_folds <- list()

# Loop through each directory
for (dir in dirs) {
  # Check if output_sim folder exists
  output_sim_path <- file.path(dir, "output_sim")
  if (dir.exists(output_sim_path)) {
    # List all CSV files in the output_sim folder
    csv_files <- list.files(output_sim_path, pattern = "\\.csv$", full.names = TRUE)
    
    # Initialize placeholders for the _parameter and _finState files
    parameter_file <- NULL
    finstate_file <- NULL
    
    # Loop through the CSV files to find the relevant ones
    for (csv_file in csv_files) {
      if (grepl("_parameter\\.csv$", csv_file)) {
        parameter_file <- csv_file
      } else if (grepl("_finState\\.csv$", csv_file)) {
        finstate_file <- csv_file
      }
    }
    
    # Check if both files are found
    if (!is.null(parameter_file) & !is.null(finstate_file)) {
      # Read the CSV files
      parameter_data <- read_csv(parameter_file, col_types = cols())
      finstate_data <- read_csv(finstate_file, col_types = cols())
      
      # Check if both data frames are not empty
      if (nrow(parameter_data) > 0 & nrow(finstate_data) > 0) {
        # Combine the data into one dataframe
        combined <- cbind(parameter_data, finstate_data)
        
        # Add a column for the directory name
        combined$simulation_folder <- basename(dir)
        finstate_data$simulation_folder <- basename(dir)
        # Add the combined data to the central dataset list
        combined_data[[dir]] <- combined
        combined_finstates[[dir]] <- finstate_data
      } else {
        # Log the directory as failed if any data frame is empty
        failed_dirs <- c(failed_dirs, dir)
        failed_folds <- c(failed_folds, as.numeric(basename(dir)))
      }
    } else {
      # Log the directory as failed if any file is missing
      failed_dirs <- c(failed_dirs, dir)
      failed_folds <- c(failed_folds, as.numeric(basename(dir)))
    }
  } else {
    # Log the directory as failed if output_sim folder is missing
    failed_dirs <- c(failed_dirs, dir)
    failed_folds <- c(failed_folds, as.numeric(basename(dir)))
  }
}

# Combine all the dataframes into one central dataframe
central_dataset <- bind_rows(combined_data)
central_finstates <- bind_rows(combined_finstates)

# Print the failed directories
cat("Failed directories:\n")
print(failed_folds)

# Optionally, save the central dataset to a CSV file
write_csv(central_dataset, "combined_simulation_results.csv")
write_csv(central_finstates, "combined_finstates.csv")