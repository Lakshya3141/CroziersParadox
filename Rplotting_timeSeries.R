source("Rplotting_functions.R")

file_path <- "./combined_simulation_results.csv"
simulation_data <- read_simulation_data(file_path)
simulation_data <- add_string_columns(simulation_data)
simulation_data <- simulation_data[simulation_data$glasttime > 200*1000-1000, ]

# Specify filters as a list
filters <- list(
  dExpParam = c(0.1),
  dMetabolicCost = c(40),
  dFracKilled = c(0.4),
  iModelChoice = c(0, 3),
  iKillChoice = c(0, 1),
  dTickTime = c(2, 4)
)

# Filter the data
filtered_data <- filter_simulation_data(simulation_data, filters)

# User-defined parameters for the plot
x_col <- "gtime"        # Specify the column for the x-axis
x_tit <- "Simulated time"
y_col <- "bcnest_avg"    # Specify the column for the y-axis
y_tit <- "Average population diversity"
group_col_x <- "sModelChoice"  # Specify the column for grouping in the x direction
group_col_y <- "dTickTime" # Specify the column for grouping in the y direction
group_color <- "sKillChoice" # Specify the column for coloring within the same subplot
error_col <- NULL # "bcind_std" # Specify the column for the error bars (optional)
num_samples <- 10  # Specify the number of samples

# Generate the plot series
dumdum <- generate_plot_series(filtered_data, x_col = x_col, y_col = y_col, x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, group_color = group_color, error_col = error_col, num_samples = num_samples)
