source("Rplotting_functions.R")

file_path <- "./combined_simulation_results3.csv"
simulation_data <- read_simulation_data(file_path)
simulation_data <- add_string_columns(simulation_data)
simulation_data <- simulation_data[simulation_data$glasttime > 200*1000-1000, ]

# Specify filters as a list
filters <- list(
  iKillChoice = c(0, 1),
  iConstStockChoice = c(1),
  iFoodResetChoice = c(1),
  iRepChoice = c(0),
  dTickTime = c(2),
  dConstantPopStock = c(1, 5, 10, 25, 50, 75, 100, 200, 500),
  dMutationStrengthCues = c(5),
  dFracKilled = c(0.4),
  dMetabolicCost = c(40),
  dExpParam = c(0.1),
  iModelChoice = c(0, 1, 2, 3)
)

# Filter the data
filtered_data <- filter_simulation_data(simulation_data, filters)
filtered_data$frac <- filtered_data$sucsteal/filtered_data$leave
filtered_data$meanCueAbundance <- floor(1/filtered_data$dExpParam)
filtered_data$sucstealfrac <- filtered_data$sucsteal/filtered_data$steal
filtered_data$sucrentry <- filtered_data$sucrentr/filtered_data$rentry

correct_dExpParam <- function(sim_data) {
  sim_data$sucstealfrac <- sim_data$sucsteal/sim_data$steal
  sim_data$sucrentry <- sim_data$sucrentr/sim_data$rentry
  # sim_data$meanCueAbundance <-  floor(1/sim_data$dExpParam)
  sim_data$modelnew <- paste0(sim_data$sModelChoice,"_",sim_data$iKillChoice)
  return(sim_data)
}

filtered_data$modelnew <- paste0(filtered_data$sModelChoice,"_",filtered_data$iKillChoice)

filter2 <- list(modelnew = c("Control_0", "Gestalt_1", "D-present_1" ,"U-absent_1"))
filtered_data <- filter_simulation_data(filtered_data, filter2)

# User-defined parameters for the plot
x_col <- "gtime"        # Specify the column for the x-axis
x_tit <- "Simulated time"
y_col <- "bcnest_avg"    # Specify the column for the y-axis
y_tit <- "Avg. Cue Diversity (N)"
group_col_x <- "dConstantPopStock"  # Specify the column for grouping in the x direction
group_col_y <- "dTickTime" # Specify the column for grouping in the y direction
group_color <- "sModelChoice" # Specify the column for coloring within the same subplot
error_col <- NULL # "bcind_std" # Specify the column for the error bars (optional)
num_samples <- 3  # Specify the number of samples

# Generate the plot series
# dumdum <- generate_plot_indiseries(filtered_data, x_col = x_col, y_col = y_col, x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, group_color = group_color, num_samples = num_samples)
dumdum2 <- generate_plot_series(filtered_data, x_col = x_col, y_col = y_col,
                               x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
                               group_color = group_color, error_col = error_col, num_samples = num_samples, 
                               com_scale = TRUE, mutate_func = correct_dExpParam)
print(dumdum2$timeseries)
