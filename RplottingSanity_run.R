source("Rplotting_functions.R")

# Read the data
simulation_data <- read_simulation_data("./combined_simulation_results3.csv")
simulation_data <- add_string_columns(simulation_data)
simulation_data <- simulation_data[simulation_data$glasttime > 200*1000-1000, ]
simulation_data <- subsample_replicates(simulation_data, 20)

# Specify filters as a list
filters <- list(
  iKillChoice = c(1),
  iConstStockChoice = c(2),
  iFoodResetChoice = c(1),
  iRepChoice = c(0),
  dTickTime = c(2),
  dConstantPopStock = c(50),
  dMutationStrengthCues = c(5),
  dFracKilled = c(0.5),
  dMetabolicCost = c(40),
  dExpParam = c(0.1),
  iModelChoice = c(0)
)

# Filter the data
filtered_data <- filter_simulation_data(simulation_data, filters)

filtered_data$meanCueAbundance <- floor(1/filtered_data$dExpParam)
filtered_data$sucstealfrac <- filtered_data$sucsteal/filtered_data$steal
filtered_data$sucrentry <- filtered_data$sucrentr/filtered_data$rentry

## Sanity Check Vibes ##
x_col <- "sModelChoice"        # Specify the column for the x-axis
x_tit <- "Model Choice"
y_col <- "bcnest_avg"          # Specify the column for the y-axis
y_tit <- "Average Cue Diversity (N)"
group_col_x <- "dTickTime"  # Specify the column for grouping in the x direction
group_col_y <- "dExpParam" # Specify the column for grouping in the y direction
group_color <- "sKillChoice" # Specify the column for coloring within the same subplot
error_col <- NULL #"nsimp_std"      # Specify the column for the error bars (optional)

# Generate the plot
dummy <- generate_boxplots(filtered_data, x_col, y_col, x_tit, y_tit, 
                           group_col_x = group_col_x, group_col_y = group_col_y, 
                           group_color = group_color, box_width = 0.5, com_scale = TRUE)
print(dummy$boxplot)

# Assuming `filtered_data` is a data frame
columns_list <- colnames(filtered_data)
print(columns_list)
# Specify the columns you want to check for unique values
columns_to_check <- columns_list[1:32]  # Replace with your column names
columns_to_check <- c(columns_to_check, "rep_num")
for (column in columns_to_check) {
  if (column %in% colnames(filtered_data)) {
    unique_values <- unique(filtered_data[[column]])
    cat("Unique values in", column, ":", unique_values, "\n")
  } else {
    cat("Column '", column, "' does not exist in the data frame.\n")
  }
}



