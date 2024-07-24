library(dplyr)
library(readr)

# Get list of numbered directories
dirs <- list.dirs(path = "./output/", full.names = TRUE, recursive = FALSE)

# Initialize an empty list to store combined data and failed directories
combined_data <- list()
combined_finstates <- list()
failed_dirs <- c()
failed_folds <- list()

mapping <- read.csv("./mapping_dual.csv")
count <- 0
# Loop through each directory
for (dir in dirs) {
  # print(basename(dir))
  print(paste0("Done: ", count, " / ", dim(mapping)[1]))
  count <- count + 1
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
        # Combine the data into one dataframe using a full join
        combined <- full_join(parameter_data, finstate_data, by = intersect(names(parameter_data), names(finstate_data)))
        
        # Add a column for the directory name
        combined$simulation_folder <- basename(dir)
        combined$rep_num <- mapping$rp[[as.numeric(basename(dir))]]
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
# cat("Failed directories:\n")
# print(failed_folds)

sort(as.numeric(failed_folds))
failed_folds_line <- paste("(", paste(failed_folds, collapse = " "), ")\n", as.character(length(failed_folds)), sep = "")
writeLines(failed_folds_line, "./additional/failed_runs_third.txt")
writeLines(as.character(length(failed_folds)), "./additional/failed_total_third.txt", )

# Optionally, save the central dataset to a CSV file
write_csv(central_dataset, "combined_simulation_results.csv")
write_csv(central_finstates, "combined_finstates.csv")
