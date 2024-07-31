source("Rplotting_functions.R")


# Read the data
simulation_data <- read_simulation_data("./combined_simulation_results.csv")
simulation_data <- add_string_columns(simulation_data)
simulation_data <- simulation_data[simulation_data$glasttime > 200*1000-1000, ]
simulation_data <- subsample_replicates(simulation_data)

# Specify filters as a list
filters <- list(
  dExpParam = c(0.1),
  iModelChoice = c(0, 1, 2, 3, 4, 5, 6),
  iKillChoice = c(0, 1),
  dTickTime = c(2, 4)
)

# Filter the data
filtered_data <- filter_simulation_data(simulation_data, filters)

filtered_data$logmeanCueAbundance <- log10(1/filtered_data$dExpParam)

# User-defined parameters for the plot
x_col <- "sModelChoice"        # Specify the column for the x-axis
x_tit <- "Model Choice"
y_col <- "cueabun_avg"          # Specify the column for the y-axis
y_tit <- "Average population cue abundance"
group_col_x <- "dTickTime"  # Specify the column for grouping in the x direction
group_col_y <- "dExpParam" # Specify the column for grouping in the y direction
group_color <- "sKillChoice" # Specify the column for coloring within the same subplot
error_col <- NULL #"nsimp_std"      # Specify the column for the error bars (optional)

# Generate the plot
dummy <- generate_boxplots(filtered_data, x_col, y_col, x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, group_color = group_color, box_width = 0.5)
