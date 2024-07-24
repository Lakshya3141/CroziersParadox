# Load necessary libraries
library(dplyr)
library(readr)
library(ggplot2)

# Function to read and preprocess data
read_simulation_data <- function(file_path) {
  data <- read_csv(file_path, col_types = cols())
  return(data)
}

# Function to filter data
filter_simulation_data <- function(data, filters) {
  for (col in names(filters)) {
    if (col %in% names(data)) {
      data <- data %>% filter(!!sym(col) %in% filters[[col]])
    } else {
      stop(paste("Column", col, "does not exist in the data."))
    }
  }
  return(data)
}

# Main script
file_path <- "./output/combined_simulation_results.csv"

# Read the data
simulation_data <- read_simulation_data(file_path)

# Specify filters as a list
filters <- list(
  dMutationStrengthCues = c(1, 5),
  dMetabolicCost = c(40),
  dFracKilled = c(0.1, 0.4, 0.8),
  iKillChoice = c(0)
)

# Filter the data
filtered_data <- filter_simulation_data(simulation_data, filters)

# Function to generate plots with optional error bars and jitter
generate_plots <- function(data, x_col, y_col, group_col = NULL, error_col = NULL, jitter_width = 0.2, error_width = 0.1) {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data))) {
    stop("Specified columns do not exist in the data.")
  }
  
  # Apply jitter manually
  set.seed(42) # for reproducibility
  data <- data %>% mutate(jittered_x = !!sym(x_col) + runif(n(), -jitter_width, jitter_width))
  
  # Generate the desired plot
  plot <- ggplot(data, aes(x = jittered_x, y = !!sym(y_col)))
  
  if (!is.null(group_col) && group_col %in% names(data)) {
    plot <- plot + aes(color = !!sym(group_col))
  }
  
  plot <- plot + geom_point() +
    theme_minimal() +
    labs(x = x_col, y = y_col, title = paste("Plot of", y_col, "vs", x_col)) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      axis.title.x = element_text(face = "bold"),
      axis.title.y = element_text(face = "bold"),
      legend.position = "bottom"
    ) +
    scale_color_brewer(palette = "Set1")
  
  if (!is.null(error_col) && error_col %in% names(data)) {
    plot <- plot + geom_errorbar(aes(ymin = !!sym(y_col) - !!sym(error_col), ymax = !!sym(y_col) + !!sym(error_col)), width = error_width)
  }
  
  if (!is.null(group_col) && group_col %in% names(data)) {
    plot <- plot + facet_wrap(as.formula(paste("~", group_col)))
  }
  
  print(plot)
}

# User-defined parameters for the plot
x_col <- "dFracKilled"       # Specify the column for the x-axis
y_col <- "cueabun_avg"       # Specify the column for the y-axis
# group_col <- "dMutationStrengthCues" # Specify the column for grouping (optional)
# error_col <- "cueabun_std"   # Specify the column for the error bars (optional)

# Generate the plot with collective error bars
generate_plots(filtered_data, x_col, y_col, error_col = NULL, jitter_width = 0.05, error_width = 0.07)
