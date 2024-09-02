# source("Rplotting_functions.R")

# Read the data
simulation_data <- read_simulation_data("./combined_simulation_results.csv")
simulation_data <- add_string_columns(simulation_data)
simulation_data <- simulation_data[simulation_data$glasttime > 200*1000-1000, ]
simulation_data <- subsample_replicates(simulation_data, 20)

# Specify filters as a list
filter <- list(
  iKillChoice = c(0, 1),
  iConstStockChoice = c(2),
  iRepChoice = c(0),
  dTickTime = c(2),
  dConstantPopStock = c(50),
  dMutationStrengthCues = c(5),
  dFracKilled = c(0.4),
  dMetabolicCost = c(10, 20, 40, 80),
  dExpParam = c(0.1),
  iModelChoice = c(0, 1, 2, 3)
)

# Filter the data
name_file = "metabolic"
color_pallete = "Set1"
if (!dir.exists(paste0("./additional/",name_file))) {
  dir.create(paste0("./additional/",name_file))
}
filtered_data <- filter_simulation_data(simulation_data, filter)
filtered_data$meanCueAbundance <- floor(1/filtered_data$dExpParam)
filtered_data$sucstealfrac <- filtered_data$sucsteal/filtered_data$steal
filtered_data$sucrentry <- filtered_data$sucrentr/filtered_data$rentry
filtered_data <- filtered_data %>%
  mutate(modelnew = paste0(iModelChoice, "_", iKillChoice), 
         sMi = case_when(
           modelnew == "0_1" ~ "Gestalt",
           modelnew == "1_1" ~ "D_present",
           modelnew == "2_1" ~ "U-absent",
           modelnew == "3_0" ~ "Control (MP)",
           FALSE ~ NA  # Default case: retain the original modelnew value
         ))

filtered_data <- filtered_data[!is.na(filtered_data$sMi), ]

# filter2 <- list(modelnew = c("Control_0", "Gestalt_1", "D-present_1" ,"U-absent_1"))
# filtered_data <- filter_simulation_data(filtered_data, filter2)
##### Diversity Cues Plot ####
x_col <- "gtime"        # Specify the column for the x-axis
x_tit <- expression("Simulated time (x10"^4*" units)")
y_col <- "bcnest_avg"    # Specify the column for the y-axis
y_tit <- "Cue Diversity"
group_col_x <- "dMetabolicCost"  # Specify the column for grouping in the x direction
group_col_y <- "dFracKilled" # Specify the column for grouping in the y direction
group_color <- "sMi" # Specify the column for coloring within the same subplot
error_col <- NULL # "bcind_std" # Specify the column for the error bars (optional)

# plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
#                                   x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y,
#                                   group_color = group_color, error_col = error_col, num_samples = num_samples,
#                                   com_scale = TRUE, mutate_func = correct_dExpParam)
# ggsave(paste0("./additional/",name_file,"/time_div.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)
# ggsave(paste0("./additional/",name_file,"/time_counts.png"), plot = plots$count_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)
dev.new()
print(plots$series_plot)

##### Diversity Neutral Cues Plot ####
y_col <- "ntrlbc_avg"          # Specify the column for the y-axis
y_tit <- "Drifting Profile Diversity"
# plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
#                                   x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
#                                   group_color = group_color, error_col = error_col, num_samples = num_samples, 
#                                   com_scale = TRUE, mutate_func = correct_dExpParam)
# ggsave(paste0("./additional/",name_file,"/time_div_drift.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)

##### Intercept Plot ####
y_col <- "int_avg"          # Specify the column for the y-axis
y_tit <- "Y-axis intercept (b)"

# Generate the plot with fixed aspect ratio and no panel spacing
plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
                                  x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
                                  group_color = group_color, error_col = error_col, num_samples = num_samples, 
                                  com_scale = TRUE, mutate_func = correct_dExpParam)
ggsave(paste0("./additional/",name_file,"/time_intercept.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)

##### Slope Plot ####
y_col <- "slope_avg"          # Specify the column for the y-axis
y_tit <- "Linear slope (a)"

# Generate the plot with fixed aspect ratio and no panel spacing
plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
                                  x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
                                  group_color = group_color, error_col = error_col, num_samples = num_samples, 
                                  com_scale = TRUE, mutate_func = correct_dExpParam)
ggsave(paste0("./additional/",name_file,"/time_slope.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)


##### Abundance Cues Plot ####
y_col <- "cueabun_avg"          # Specify the column for the y-axis
y_tit <- "Cue Abundance"
# plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
#                                   x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
#                                   group_color = group_color, error_col = error_col, num_samples = num_samples, 
#                                   com_scale = TRUE, mutate_func = correct_dExpParam)
# ggsave(paste0("./additional/",name_file,"/time_abun.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)

##### Abundance Neutral Plot ####
y_col <- "ntrlabun_avg"          # Specify the column for the y-axis
y_tit <- "Drifting Profile Abundance"
# plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
#                                   x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
#                                   group_color = group_color, error_col = error_col, num_samples = num_samples, 
#                                   com_scale = TRUE, mutate_func = correct_dExpParam)
# ggsave(paste0("./additional/",name_file,"/time_abun_drift.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)

##### SucSteal Plot ####
y_col <- "sucstealfrac"          # Specify the column for the y-axis
y_tit <- "Succesful Steals"

# Generate the plot with fixed aspect ratio and no panel spacing
# plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
#                                   x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
#                                   group_color = group_color, error_col = error_col, num_samples = num_samples, 
#                                   com_scale = TRUE, mutate_func = correct_dExpParam)
# 
# # Save the boxplot with fixed dimensions
# ggsave(paste0("./additional/",name_file,"/time_stealfrac.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)

##### SucRentry Plot ####
y_col <- "sucrentry"          # Specify the column for the y-axis
y_tit <- "Succesful Rentry"

# plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
#                                   x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
#                                   group_color = group_color, error_col = error_col, num_samples = num_samples, 
#                                   com_scale = TRUE, mutate_func = correct_dExpParam)
# 
# ggsave(paste0("./additional/",name_file,"/time_rentryfrac.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)

##### Lineages Plot ####
y_col <- "uniq_lins"          # Specify the column for the y-axis
y_tit <- "Surviving lineages"

# plots <- generate_plot_series_new(filtered_data, x_col = x_col, y_col = y_col,
#                                   x_tit, y_tit, group_col_x = group_col_x, group_col_y = group_col_y, 
#                                   group_color = group_color, error_col = error_col, num_samples = num_samples, 
#                                   com_scale = TRUE, mutate_func = correct_dExpParam)
# 
# # Save the boxplot with fixed dimensions
# ggsave(paste0("./additional/",name_file,"/time_lineages.png"), plot = plots$series_plot, width = plots$width, height = plots$height, units = "in", dpi = 300)
