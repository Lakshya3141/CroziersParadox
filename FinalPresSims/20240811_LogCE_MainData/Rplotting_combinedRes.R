source("Rplotting_functions.R")

# Read the data
simulation_data <- read_simulation_data("./combined_simulation_results.csv")
simulation_data <- add_string_columns(simulation_data)
simulation_data <- simulation_data[simulation_data$glasttime > 200*1000-1000, ]
simulation_data <- subsample_replicates(simulation_data, 10)


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

# filters <- list(
#   iKillChoice = c(0, 1),
#   dMutationStrengthCues = c(0.1, 0.5, 1, 5, 10)
# )

# Filter the data
filtered_data <- filter_simulation_data(simulation_data, filters)

filtered_data$meanCueAbundance <- floor(1/filtered_data$dExpParam)
filtered_data$sucstealfrac <- filtered_data$sucsteal/filtered_data$steal
filtered_data$sucrentry <- filtered_data$sucrentr/filtered_data$rentry
filtered_data$modelnew <- paste0(filtered_data$sModelChoice,"_",filtered_data$iKillChoice)

filter2 <- list(modelnew = c("Control_0", "Gestalt_1", "D-present_1" ,"U-absent_1"))
filtered_data <- filter_simulation_data(filtered_data, filter2)

##### Diversity Plot ####
x_col <- "dConstantPopStock"        # Specify the column for the x-axis
x_tit <- "Constant Population Stock"
y_col <- "bcnest_avg"          # Specify the column for the y-axis
y_tit <- "Avg. Cue Diversity (N)"
group_col_x <- "dTickTime"  # Specify the column for grouping in the x direction
group_col_y <- "iFoodResetChoice" # Specify the column for grouping in the y direction
group_color <- "modelnew" # Specify the column for coloring within the same subplot
error_col <- NULL #"nsimp_std"      # Specify the column for the error bars (optional)


# Generate the plot
dummy <- generate_boxplots(filtered_data, x_col, y_col, x_tit, y_tit, 
                           group_col_x = group_col_x, group_col_y = group_col_y, 
                           group_color = group_color, box_width = 0.5, com_scale = TRUE)
print(dummy$boxplot)
# print(dummy$cplot)
  
#### Abundance Plot ####
y_col <- "cueabun_avg"          # Specify the column for the y-axis
y_tit <- "Avg. Cue Abundance"
dummy2 <- generate_boxplots(filtered_data, x_col, y_col, x_tit, y_tit, 
                           group_col_x = group_col_x, group_col_y = group_col_y, 
                           group_color = group_color, box_width = 0.5, com_scale = TRUE)
print(dummy2$boxplot)

#### Int Plot ####
y_col <- "int_avg"          # Specify the column for the y-axis
y_tit <- "Avg. Intercept"
dummy_int <- generate_boxplots(filtered_data, x_col, y_col, x_tit, y_tit, 
                            group_col_x = group_col_x, group_col_y = group_col_y, 
                            group_color = group_color, box_width = 0.5, com_scale = TRUE)
print(dummy_int$boxplot)

#### Slope Plot ####
y_col <- "slope_avg"          # Specify the column for the y-axis
y_tit <- "Avg. Slope"
dummy_slope <- generate_boxplots(filtered_data, x_col, y_col, x_tit, y_tit, 
                            group_col_x = group_col_x, group_col_y = group_col_y, 
                            group_color = group_color, box_width = 0.5, com_scale = TRUE)
print(dummy_slope$boxplot)

#### SucSteal Plot ####
y_col <- "sucstealfrac"          # Specify the column for the y-axis
y_tit <- "Suc Steal Frac"
dummy3 <- generate_boxplots(filtered_data, x_col, y_col, x_tit, y_tit, 
                            group_col_x = group_col_x, group_col_y = group_col_y, 
                            group_color = group_color, box_width = 0.5, com_scale = FALSE)
print(dummy3$boxplot)

#### SucRentry Plot ####
y_col <- "sucrentry"          # Specify the column for the y-axis
y_tit <- "Suc Rentry"
dummy4 <- generate_boxplots(filtered_data, x_col, y_col, x_tit, y_tit, 
                            group_col_x = group_col_x, group_col_y = group_col_y, 
                            group_color = group_color, box_width = 0.5, com_scale = FALSE)
print(dummy4$boxplot)
