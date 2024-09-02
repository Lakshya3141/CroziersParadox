library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)
library(cowplot)
library(gridExtra)
library(emmeans)

numleg = 2

# Function to read data
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

# Function to add string values to data for better plotting
add_string_columns <- function(data) {
  data <- data %>%
    mutate(
      sModelChoice = if ("iModelChoice" %in% names(data)) {
        as.factor(case_when(
          iModelChoice == 0 ~ "Gestalt",
          iModelChoice == 1 ~ "D-present",
          iModelChoice == 2 ~ "U-absent",
          iModelChoice == 3 ~ "Control (M)",
          iModelChoice == 4 ~ "Gestalt Ind",
          iModelChoice == 5 ~ "D-present Ind",
          iModelChoice == 6 ~ "U-absent Ind",
          TRUE ~ as.character(iModelChoice)
        ))
      } else {
        NULL
      },
      sTolChoice = if ("iTolChoice" %in% names(data)) {
        as.factor(case_when(
          iTolChoice == 0 ~ "linear",
          iTolChoice == 1 ~ "logistic",
          iTolChoice == 2 ~ "Tcontrol",
          TRUE ~ as.character(iTolChoice)
        ))
      } else {
        NULL
      },
      sKC = if ("iKillChoice" %in% names(data)) {
        as.factor(case_when(
          iKillChoice == 0 ~ "Control (P)",
          iKillChoice == 1 ~ "Seasonal",
          iKillChoice == 2 ~ "Individual",
          TRUE ~ as.character(iKillChoice)
        ))
      } else {
        NULL
      },
      sRepChoice = if ("iRepChoice" %in% names(data)) {
        as.factor(case_when(
          iRepChoice == 0 ~ "Seasonal",
          iRepChoice == 1 ~ "individual",
          iRepChoice == 2 ~ "Both",
          TRUE ~ as.character(iRepChoice)
        ))
      } else {
        NULL
      },
      sConstStockChoice = if ("iConstStockChoice" %in% names(data)) {
        as.factor(case_when(
          iConstStockChoice == 0 ~ "linear",
          iConstStockChoice == 1 ~ "constant stock",
          iConstStockChoice == 2 ~ "pulsing",
          TRUE ~ as.character(iConstStockChoice)
        ))
      } else {
        NULL
      }
    )
  return(data)
}

extract_legend <- function(plot) {
  g <- ggplotGrob(plot)
  legend <- g$grobs[which(sapply(g$grobs, function(x) x$name) == "guide-box")][[1]]
  return(legend)
}

# Function to subsample replicates for unique parameter sets
# for final value plots, not time series plots
subsample_replicates <- function(data, num_samples = 20) {
  # Define the columns that are considered as parameter variables
  parameter_vars <- c(
    "max_gtime_evolution", "dRemovalTime", "dReproductionTime", "dTickTime", "dOutputTime",
    "dFracDeadNest", "dFracResetSteal", "dInitIntercept", "dInitSlope", "bIsCoevolve",
    "dFracKilled", "dMetabolicCost", "dMutationStrength", "dMutationStrengthCues",
    "dFracIndMutStrength", "dMutBias", "iNumWorkers", "iNumCues", "iNumColonies",
    "dInitNestStock", "dInitFoodStock", "dExpParam", "dMeanActionTime", "dRatePopStock",
    "dConstantPopStock", "dRateNestStock", "iTolChoice", "iKillChoice", "iRepChoice",
    "iFoodResetChoice", "iConstStockChoice", "iModelChoice"
  )
  
  # Check if any parameter sets have fewer than the required number of replicates
  parameter_sets <- data %>%
    group_by(across(all_of(parameter_vars))) %>%
    summarise(n = n(), .groups = 'drop') %>%
    filter(n < num_samples)
  
  if (nrow(parameter_sets) > 0) {
    print(paste0("Some parameter sets have fewer than ", num_samples, " replicates."))
    print(nrow(parameter_sets))
  }
  
  # Group by the unique parameter sets and sample replicates
  subsampled_data <- data %>%
    group_by(across(all_of(parameter_vars))) %>%
    sample_n(size = min(n(), num_samples), replace = FALSE) %>%
    ungroup()
  
  return(subsampled_data)
}

generate_plot_series <- function(data, x_col = "gtime", y_col, x_tit, y_tit, group_col_x, group_col_y, group_color, error_col = NULL, num_samples, com_scale = TRUE, mutate_func = NULL) {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data)) | 
      !(group_col_x %in% names(data)) | !(group_col_y %in% names(data)) | !(group_color %in% names(data))) {
    stop("One or more specified columns do not exist in the data.")
  }
  
  # Convert group columns to factors
  data[[group_col_x]] <- as.factor(data[[group_col_x]])
  data[[group_col_y]] <- as.factor(data[[group_col_y]])
  data[[group_color]] <- as.factor(data[[group_color]])
  
  # Create an empty list to store plots
  plot_list <- list()
  cplot_list <- list()
  
  # Initialize variables for global y-axis limits
  global_y_min <- Inf
  global_y_max <- -Inf
  
  # Loop through each unique combination of group_col_x and group_col_y
  for (gy in unique(data[[group_col_y]])) {
    for (gx in unique(data[[group_col_x]])) {
      sub_data <- data %>% filter(!!sym(group_col_x) == gx & !!sym(group_col_y) == gy)
      
      plot <- ggplot() +
        theme_minimal() +
        labs(
          x = x_col, 
          y = y_col, 
          title = paste(group_col_x, "=", gx, "&", group_col_y, "=", gy)
        ) +
        theme(
          plot.title = element_text(size = 7, hjust = 0.5, face = "bold"),
          axis.title.x = element_blank(), #element_text(face = "bold", size = 14),
          axis.title.y = element_blank(), #element_text(face = "bold", size = 14),
          axis.text.x = element_text(size = 9),
          axis.text.y = element_text(size = 9),
          strip.text = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 12),
          legend.position = "none",
          panel.border = element_rect(color = "black", fill = NA, size = 1)
        )
      
      cplot <- plot
      
      for (gc in unique(sub_data[[group_color]])) {
        rep_count <- 0
        subset_data <- sub_data %>% filter(!!sym(group_color) == gc)
        all_sim_data <- list()
        
        for (i in 1:nrow(subset_data)) {
          sim_folder <- subset_data$simulation_folder[i]
          file_path <- list.files(path = paste0("./output/", sim_folder, "/output_sim/"), pattern = "_evolution.csv", full.names = TRUE)[1]
          if (file.exists(file_path)) {
            sim_data <- read_csv(file_path, col_types = cols())
            if (nrow(sim_data) == 3991) {
              rep_count <- rep_count + 1
              if (!is.null(mutate_func)) {
                sim_data <- mutate_func(sim_data)
              }
              sim_data <- add_string_columns(sim_data)
              sim_data[[group_color]] <- as.factor(sim_data[[group_color]])
              all_sim_data[[length(all_sim_data) + 1]] <- sim_data
              if (rep_count == num_samples) {
                break
              }
            }
          }
        }
        
        if (length(all_sim_data) > 0) {
          # Ensure all simulations have the same x_col values
          x_vals <- all_sim_data[[1]][[x_col]]
          y_matrix <- sapply(all_sim_data, function(df) df[[y_col]])
          
          # Aggregate data by taking mean and standard deviation
          agg_data <- data.frame(
            x_col = x_vals,
            mean_y = rowMeans(y_matrix, na.rm = TRUE),
            sd_y = apply(y_matrix, 1, sd, na.rm = TRUE),
            count = ncol(y_matrix)
          )
          
          # Update global y-axis limits
          current_y_min <- min(agg_data$mean_y - agg_data$sd_y, na.rm = TRUE)
          current_y_max <- max(agg_data$mean_y + agg_data$sd_y, na.rm = TRUE)
          global_y_min <- min(global_y_min, current_y_min)
          global_y_max <- max(global_y_max, current_y_max)
          
          # Add the data points to the plot with fill
          plot <- plot + 
            geom_line(data = agg_data, aes_string(x = "x_col", y = "mean_y", color = paste0("'", as.character(gc), "'"))) +
            geom_ribbon(data = agg_data, aes_string(x = "x_col", ymin = "mean_y - sd_y", ymax = "mean_y + sd_y", fill = paste0("'", as.character(gc), "'")), alpha = 0.2) +
            scale_fill_manual(values = scales::hue_pal()(length(unique(sub_data[[group_color]]))), guide = "none") +  # No fill legend
            scale_color_manual(name = group_color, values = scales::hue_pal()(length(unique(sub_data[[group_color]]))))  # Update color legend
          cplot <- cplot +
            geom_line(data = agg_data, aes_string(x = "x_col", y = "count", color = paste0("'", as.character(gc), "'"))) +
            scale_fill_manual(values = scales::hue_pal()(length(unique(sub_data[[group_color]]))), guide = "none") +  # No fill legend
            scale_color_manual(name = group_color, values = scales::hue_pal()(length(unique(sub_data[[group_color]]))))  # Update color legend
          
        }
      }
      
      # Add the plot to the list of plots
      plot_list[[paste(gy, gx, sep = "_")]] <- plot
      cplot_list[[paste(gy, gx, sep = "_")]] <- cplot
    }
  }
  
  # Apply the global y-axis limits to all plots
  if (com_scale) {
    plot_list <- lapply(plot_list, function(p) {
      p + ylim(global_y_min, global_y_max)
    })
  }
  
  cplot_list <- lapply(cplot_list, function(p) {
    p + ylim(0, 25)
  })
  
  
  # Create a dummy plot to extract the legend
  legend_plot <- ggplot(data, aes_string(x = x_col, y = y_col, color = group_color)) +
    geom_line() +
    scale_color_manual(name = group_color, values = scales::hue_pal()(length(unique(data[[group_color]])))) +
    theme_void() + 
    theme(legend.position = "bottom")
  
  # Extract the legend from the dummy plot
  legend <- extract_legend(legend_plot)
  
  # Combine all plots into a single grid
  combined_plot <- plot_grid(
    plot_grid(
      plotlist = plot_list,
      ncol = length(unique(data[[group_col_x]])),   # Number of columns
      nrow = length(unique(data[[group_col_y]])),   # Number of rows
      align = 'hv',  # Align plots horizontally and vertically
      axis = 'tblr'  # Align top, bottom, left, and right axes
    )
  )
  combined_cplot <- plot_grid(
    plot_grid(
      plotlist = cplot_list,
      ncol = length(unique(data[[group_col_x]])),   # Number of columns
      nrow = length(unique(data[[group_col_y]])),   # Number of rows
      align = 'hv',  # Align plots horizontally and vertically
      axis = 'tblr'  # Align top, bottom, left, and right axes
    )
  )
  
  # Add common axis titles and combine with the legend
  combined_plot_with_labels <- ggdraw() +
    draw_plot(combined_plot) +
    draw_label(x_tit, 
               x = 0.5, y = -0.05, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold") +
    draw_label(y_tit, 
               x = -0.02, y = 0.5, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold", angle = 90)  +
    theme(plot.margin = margin(1, 1, 1, 1, "cm"))  # Increased bottom margin for legend
  
  final_combined_plot <- plot_grid(
    combined_plot_with_labels,
    legend,
    ncol = 1,
    rel_heights = c(1, 0.1)  # Adjust height ratio between plots and legend
  )
  
  combined_cplot_with_labels <- ggdraw() +
    draw_plot(combined_cplot) +
    draw_label(x_tit, 
               x = 0.5, y = -0.05, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold") +
    draw_label("Counts / Replicates", 
               x = -0.02, y = 0.5, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold", angle = 90)  +
    theme(plot.margin = margin(1, 1, 1, 1, "cm"))  # Increased bottom margin for legend
  
  final_combined_cplot <- plot_grid(
    combined_cplot_with_labels,
    legend,
    ncol = 1,
    rel_heights = c(1, 0.1)  # Adjust height ratio between plots and legend
  )
  # Print the combined plot grid with common axis titles and legend
  # print(final_combined_plot)
  # print(final_combined_cplot)
  return(list(timeseries = final_combined_plot, cplot = final_combined_cplot))
}

generate_plot_indiseries <- function(data, x_col = "gtime", y_col, x_tit, y_tit, group_col_x, group_col_y, group_color, num_samples, com_scale = TRUE, mutate_func = NULL) {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data)) | 
      !(group_col_x %in% names(data)) | !(group_col_y %in% names(data)) | !(group_color %in% names(data))) {
    stop("One or more specified columns do not exist in the data.")
  }
  
  # Convert group columns to factors
  data[[group_col_x]] <- as.factor(data[[group_col_x]])
  data[[group_col_y]] <- as.factor(data[[group_col_y]])
  data[[group_color]] <- as.factor(data[[group_color]])
  
  # Create an empty list to store plots
  plot_list <- list()
  
  # Initialize variables for global y-axis limits
  global_y_min <- Inf
  global_y_max <- -Inf
  
  # Loop through each unique combination of group_col_x and group_col_y
  for (gy in unique(data[[group_col_y]])) {
    for (gx in unique(data[[group_col_x]])) {
      sub_data <- data %>% filter(!!sym(group_col_x) == gx & !!sym(group_col_y) == gy)
      
      plot <- ggplot() +
        theme_minimal() +
        labs(
          x = x_col, 
          y = y_col, 
          title = paste(group_col_x, "=", gx, "&", group_col_y, "=", gy)
        ) +
        theme(
          plot.title = element_text(size = 7, hjust = 0.5, face = "bold"),
          axis.title.x = element_blank(), 
          axis.title.y = element_blank(), 
          axis.text.x = element_text(size = 9),
          axis.text.y = element_text(size = 9),
          strip.text = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 12),
          legend.position = "none",
          panel.border = element_rect(color = "black", fill = NA, size = 1)
        )
      
      for (gc in unique(sub_data[[group_color]])) {
        rep_count <- 0
        subset_data <- sub_data %>% filter(!!sym(group_color) == gc)
        all_sim_data <- list()
        
        for (i in 1:nrow(subset_data)) {
          sim_folder <- subset_data$simulation_folder[i]
          file_path <- list.files(path = paste0("./output/", sim_folder, "/output_sim/"), pattern = "_evolution.csv", full.names = TRUE)[1]
          if (file.exists(file_path)) {
            sim_data <- read_csv(file_path, col_types = cols())
            if (nrow(sim_data) == 3991) {
              rep_count <- rep_count + 1
              if (!is.null(mutate_func)) {
                sim_data <- mutate_func(sim_data)
              }
              sim_data <- add_string_columns(sim_data)
              sim_data[[group_color]] <- as.factor(sim_data[[group_color]])
              all_sim_data[[length(all_sim_data) + 1]] <- sim_data
              if (rep_count == num_samples) {
                break
              }
            }
          }
        }
        
        if (length(all_sim_data) > 0) {
          # Ensure all simulations have the same x_col values
          x_vals <- all_sim_data[[1]][[x_col]]
          
          # Add each individual time series to the plot
          for (sim_data in all_sim_data) {
            plot <- plot + 
              geom_line(data = sim_data, aes_string(x = x_col, y = y_col, color = paste0("'", as.character(gc), "'"))) +
              scale_color_manual(name = group_color, values = scales::hue_pal()(length(unique(sub_data[[group_color]]))))  # Update color legend
          }
          
          # Update global y-axis limits
          current_y_min <- min(sapply(all_sim_data, function(df) min(df[[y_col]], na.rm = TRUE)))
          current_y_max <- max(sapply(all_sim_data, function(df) max(df[[y_col]], na.rm = TRUE)))
          global_y_min <- min(global_y_min, current_y_min)
          global_y_max <- max(global_y_max, current_y_max)
        }
      }
      
      # Add the plot to the list of plots
      plot_list[[paste(gy, gx, sep = "_")]] <- plot
    }
  }
  
  # Apply the global y-axis limits to all plots
  if(com_scale){
    plot_list <- lapply(plot_list, function(p) {
      p + ylim(global_y_min, global_y_max)
    })
  }
  
  # Create a dummy plot to extract the legend
  legend_plot <- ggplot(data, aes_string(x = x_col, y = y_col, color = group_color)) +
    geom_line() +
    scale_color_manual(name = group_color, values = scales::hue_pal()(length(unique(data[[group_color]])))) +
    theme_void() + 
    theme(legend.position = "bottom")
  
  # Extract the legend from the dummy plot
  legend <- extract_legend(legend_plot)
  
  # Combine all plots into a single grid
  combined_plot <- plot_grid(
    plot_grid(
      plotlist = plot_list,
      ncol = length(unique(data[[group_col_x]])),   # Number of columns
      nrow = length(unique(data[[group_col_y]])),   # Number of rows
      align = 'hv',  # Align plots horizontally and vertically
      axis = 'tblr'  # Align top, bottom, left, and right axes
    )
  )
  
  # Add common axis titles and combine with the legend
  combined_plot_with_labels <- ggdraw() +
    draw_plot(combined_plot) +
    draw_label(x_tit, 
               x = 0.5, y = -0.05, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold") +
    draw_label(y_tit, 
               x = -0.02, y = 0.5, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold", angle = 90)  +
    theme(plot.margin = margin(1, 1, 1, 1, "cm"))  # Increased bottom margin for legend
  
  final_combined_plot <- plot_grid(
    combined_plot_with_labels,
    legend,
    ncol = 1,
    rel_heights = c(1, 0.1)  # Adjust height ratio between plots and legend
  )
  
  # Print the combined plot grid with common axis titles and legend
  return(list(timeseries = final_combined_plot))
}

generate_boxplots <- function(data, x_col, y_col, x_tit, y_tit, group_col_x = NULL, group_col_y = NULL, group_color = NULL, box_width = 0.5, com_scale = TRUE) {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data))) {
    stop("Specified columns do not exist in the data.")
  }
  
  # Convert group columns to factors if they are continuous
  if (!is.null(group_col_x) && group_col_x %in% names(data) && !is.factor(data[[group_col_x]])) {
    data[[group_col_x]] <- as.factor(data[[group_col_x]])
  }
  if (!is.null(group_col_y) && group_col_y %in% names(data) && !is.factor(data[[group_col_y]])) {
    data[[group_col_y]] <- as.factor(data[[group_col_y]])
  }
  if (!is.null(group_color) && group_color %in% names(data) && !is.factor(data[[group_color]])) {
    data[[group_color]] <- as.factor(data[[group_color]])
  } 
  
  # Ensure x_col is treated as a factor and use the corresponding string columns
  data[[x_col]] <- as.factor(data[[x_col]])
  
  # Create empty lists to store plots
  plot_list <- list()
  cplot_list <- list()
  
  # Initialize variables for global y-axis limits
  global_y_min <- Inf
  global_y_max <- -Inf
  
  # Loop through each unique combination of group_col_x and group_col_y
  for (gy in unique(data[[group_col_y]])) {
    for (gx in unique(data[[group_col_x]])) {
      sub_data <- data %>% filter(!!sym(group_col_x) == gx & !!sym(group_col_y) == gy)
      
      # Generate the base plot with boxplots
      plot <- ggplot(sub_data, aes(x = !!sym(x_col), y = !!sym(y_col), fill = !!sym(group_color))) + 
        geom_boxplot(width = box_width, position = position_dodge(width = 0.3)) +
        theme_minimal() +
        labs(x = x_col, y = y_col, title = paste(group_col_x, "=", gx, "&", group_col_y, "=", gy)) +
        theme(
          plot.title = element_text(size = 7, hjust = 0.5, face = "bold"),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_text(size = 9, angle = 45, hjust = 1),
          axis.text.y = element_text(size = 9),
          strip.text = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 12),
          legend.position = "none",
          panel.border = element_rect(color = "black", fill = NA, size = 1)
        ) +
        scale_fill_brewer(palette = "Set1") +
        scale_x_discrete()
      
      # Generate the cplot showing the number of samples
      counts <- sub_data %>%
        group_by(!!sym(x_col), !!sym(group_color)) %>%
        summarise(count = n(), .groups = 'drop')
      
      cplot <- ggplot(counts, aes(x = !!sym(x_col), y = count, color = !!sym(group_color))) +
        geom_point(size = 3) +
        theme_minimal() +
        labs(x = x_col, y = "Count", title = paste(group_col_x, "=", gx, "&", group_col_y, "=", gy)) +
        theme(
          plot.title = element_text(size = 7, hjust = 0.5, face = "bold"),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_text(size = 9, angle = 45, hjust = 1),
          axis.text.y = element_text(size = 9),
          strip.text = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 12),
          legend.position = "none",
          panel.border = element_rect(color = "black", fill = NA, size = 1)
        ) +
        scale_color_brewer(palette = "Set1") +
        scale_x_discrete()
      
      # Update global y-axis limits
      current_y_min <- min(sub_data[[y_col]], na.rm = TRUE)
      current_y_max <- max(sub_data[[y_col]], na.rm = TRUE)
      global_y_min <- min(global_y_min, current_y_min)
      global_y_max <- max(global_y_max, current_y_max)
      
      # Add the plots to the respective lists
      plot_list[[paste(gy, gx, sep = "_")]] <- plot
      cplot_list[[paste(gy, gx, sep = "_")]] <- cplot
    }
  }
  
  if(com_scale){
    plot_list <- lapply(plot_list, function(p) {
      p + ylim(global_y_min, global_y_max)
    })
  }
  
  cplot_list <- lapply(cplot_list, function(p) {
    p + ylim(0, 25)
  })
  
  # Create a dummy plot to extract the legend
  legend_plot <- ggplot(data, aes_string(x = x_col, y = y_col, fill = group_color)) +
    geom_boxplot() +
    scale_fill_brewer(palette = "Set1") +
    theme_void() + 
    theme(legend.position = "bottom")
  
  # Extract the legend from the dummy plot
  legend <- extract_legend(legend_plot)
  
  # Combine all boxplots into a single grid
  combined_boxplot <- plot_grid(
    plot_grid(
      plotlist = plot_list,
      ncol = length(unique(data[[group_col_x]])),   # Number of columns
      nrow = length(unique(data[[group_col_y]])),   # Number of rows
      align = 'hv',  # Align plots horizontally and vertically
      axis = 'tblr'  # Align top, bottom, left, and right axes
    )
  )
  
  # Combine all cplots into a single grid
  combined_cplot <- plot_grid(
    plot_grid(
      plotlist = cplot_list,
      ncol = length(unique(data[[group_col_x]])),   # Number of columns
      nrow = length(unique(data[[group_col_y]])),   # Number of rows
      align = 'hv',  # Align plots horizontally and vertically
      axis = 'tblr'  # Align top, bottom, left, and right axes
    )
  )
  
  # Add common axis titles and combine with the legend for boxplots
  combined_boxplot_with_labels <- ggdraw() +
    draw_plot(combined_boxplot) +
    draw_label(x_tit, 
               x = 0.5, y = -0.05, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold") +
    draw_label(y_tit, 
               x = -0.02, y = 0.5, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold", angle = 90) +
    theme(plot.margin = margin(1, 1, 1, 1, "cm"))  # Increased bottom margin for legend
  
  final_combined_boxplot <- plot_grid(
    combined_boxplot_with_labels,
    legend,
    ncol = 1,
    rel_heights = c(1, 0.1)  # Adjust height ratio between plots and legend
  )
  
  # Add common axis titles and combine with the legend for cplots
  combined_cplot_with_labels <- ggdraw() +
    draw_plot(combined_cplot) +
    draw_label(x_tit, 
               x = 0.5, y = -0.05, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold") +
    draw_label("Count", 
               x = -0.02, y = 0.5, hjust = 0.5, vjust = 0.5,
               size = 14, fontface = "bold", angle = 90) +
    theme(plot.margin = margin(1, 1, 1, 1, "cm"))  # Increased bottom margin for legend
  
  final_combined_cplot <- plot_grid(
    combined_cplot_with_labels,
    legend,
    ncol = 1,
    rel_heights = c(1, 0.1)  # Adjust height ratio between plots and legend
  )
  
  # Print the combined plot grids with common axis titles and legend
  # print(final_combined_boxplot)
  # print(final_combined_cplot)
  
  return(list(boxplot = final_combined_boxplot, cplot = final_combined_cplot))
}

generate_dotplots <- function(data, x_col, y_col, x_tit, y_tit, group_col_x = NULL, group_col_y = NULL, group_color = NULL, error_col = NULL, jitter_width = 0.2, error_width = 0.1) {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data))) {
    stop("Specified columns do not exist in the data.")
  }
  
  # Convert group columns to factors if they are continuous
  if (!is.null(group_col_x) && group_col_x %in% names(data) && !is.factor(data[[group_col_x]])) {
    data[[group_col_x]] <- as.factor(data[[group_col_x]])
  }
  if (!is.null(group_col_y) && group_col_y %in% names(data) && !is.factor(data[[group_col_y]])) {
    data[[group_col_y]] <- as.factor(data[[group_col_y]])
  }
  if (!is.null(group_color) && group_color %in% names(data) && !is.factor(data[[group_color]])) {
    data[[group_color]] <- as.factor(data[[group_color]])
  }
  
  # Apply jitter manually if x_col is not a factor
  set.seed(42) # for reproducibility
  if (!is.factor(data[[x_col]])) {
    data <- data %>% mutate(jittered_x = !!sym(x_col) + runif(n(), -jitter_width, jitter_width))
  } else {
    data <- data %>% mutate(jittered_x = !!sym(x_col))
  }
  
  # Generate the base plot
  plot <- ggplot(data, aes(x = jittered_x, y = !!sym(y_col), color = !!sym(group_color))) 
  
  # Add points and error bars
  plot <- plot + geom_point(size = 1) +
    theme_minimal() +
    labs(x = x_tit, y = y_tit, title = paste("Plot of", x_tit, "vs", y_tit)) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      axis.title.x = element_text(size = 14, face = "bold"),
      axis.title.y = element_text(size = 14, face = "bold"),
      axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 12),
      strip.text = element_text(size = 12, face = "bold"),  # For subplot titles
      legend.text = element_text(size = 14),
      legend.title = element_text(size = 14, face = "bold"),
      legend.position = "bottom"
    ) +
    scale_color_brewer(palette = "Set1") + 
    theme(panel.border = element_rect(colour = "black", fill=NA, linewidth =1))
  
  if (!is.null(error_col) && error_col %in% names(data)) {
    plot <- plot + geom_errorbar(aes(ymin = !!sym(y_col) - !!sym(error_col), ymax = !!sym(y_col) + !!sym(error_col)), width = error_width)
  }
  
  # Add facet wrapping for subplots
  facet_formula <- NULL
  if (!is.null(group_col_x) && group_col_x %in% names(data)) {
    if (!is.null(group_col_y) && group_col_y %in% names(data)) {
      facet_formula <- as.formula(paste(group_col_y, "~", group_col_x))
      facet_labels <- labeller(.rows = label_both, .cols = label_value)
    } else {
      facet_formula <- as.formula(paste("~", group_col_x))
      facet_labels <- labeller(.cols = label_both)
    }
  } else if (!is.null(group_col_y) && group_col_y %in% names(data)) {
    facet_formula <- as.formula(paste("~", group_col_y))
    facet_labels <- labeller(.rows = label_both)
  }
  
  if (!is.null(facet_formula)) {
    plot <- plot + facet_grid(facet_formula, labeller = facet_labels)
  }
  
  # Conditionally adjust x-axis scale if x_col is a factor
  if (is.factor(data[[x_col]])) {
    plot <- plot + scale_x_discrete()
  } else {
    plot <- plot + scale_x_continuous()
  }
  
  print(plot)
}

generate_boxplots_combined <- function(data, x_col, y_col, x_tit, y_tit, group_col_x = NULL, group_col_y = NULL, group_color = NULL, box_width = 0.5, com_scale = TRUE, color_palette = "Set1") {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data))) {
    stop("Specified columns do not exist in the data.")
  }
  
  # Convert group columns to factors if they are continuous
  if (!is.null(group_col_x) && group_col_x %in% names(data) && !is.factor(data[[group_col_x]])) {
    data[[group_col_x]] <- as.factor(data[[group_col_x]])
  }
  if (!is.null(group_col_y) && group_col_y %in% names(data) && !is.factor(data[[group_col_y]])) {
    data[[group_col_y]] <- as.factor(data[[group_col_y]])
  }
  if (!is.null(group_color) && group_color %in% names(data) && !is.factor(data[[group_color]])) {
    data[[group_color]] <- as.factor(data[[group_color]])
  }
  
  # Ensure x_col is treated as a factor
  data[[x_col]] <- as.factor(data[[x_col]])
  
  # Calculate number of rows and columns for facets
  n_rows <- length(unique(data[[group_col_y]]))
  n_cols <- length(unique(data[[group_col_x]]))
  
  # Set base dimensions for the plot
  base_width <- 3 # Base width in inches
  base_height <- 6 # Base height in inches
  
  # Calculate dimensions based on number of rows and columns
  plot_width <- base_width + 1.5 * n_cols
  plot_height <- base_height + 1.5 * n_rows
  
  # Ensure the plot is not too stretched; set min and max dimensions
  # plot_width <- max(min(plot_width, 16), 8) # Minimum 8 inches, maximum 16 inches
  # plot_height <- max(min(plot_height, 16), 6) # Minimum 6 inches, maximum 16 inches
  
  # Generate the base plot with boxplots and facetting
  boxplot <- ggplot(data, aes_string(x = x_col, y = y_col, fill = group_color)) +
    geom_boxplot(width = box_width, position = position_dodge(width = 0.75)) +
    theme_minimal() +
    labs(x = x_tit, y = y_tit) +
    facet_grid(as.formula(paste(group_col_y, "~", group_col_x)), labeller = label_both) +
    theme(
      strip.text = element_text(size = 14, face = "bold"),
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 12),
      plot.title = element_text(size = 16, hjust = 0.5),
      panel.border = element_rect(color = "black", fill = NA, size = 1),
      axis.text = element_text(size = 13),
      axis.title = element_text(size = 15),
      strip.background = element_blank(),
      panel.spacing = unit(0.5, "lines"),
      legend.position = "bottom",
      legend.box.margin = margin(0, 0, 10, 0) # Add margin to legend to avoid overlap
    ) +
    scale_fill_brewer(palette = color_palette)
  
  # Adjust the y-axis scale if com_scale is TRUE
  if(com_scale) {
    boxplot <- boxplot + coord_cartesian(ylim = range(data[[y_col]], na.rm = TRUE))
  }
  
  # Create the count plot
  counts <- data %>%
    group_by(across(all_of(c(x_col, group_col_x, group_col_y, group_color)))) %>%
    summarise(count = n(), .groups = 'drop')
  
  cplot <- ggplot(counts, aes_string(x = x_col, y = "count", color = group_color)) +
    geom_point(size = 3) +
    theme_minimal() +
    labs(x = x_tit, y = "Count") +
    facet_grid(as.formula(paste(group_col_y, "~", group_col_x)), labeller = label_both) +
    theme(
      strip.text = element_text(size = 14, face = "bold"),
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 12),
      plot.title = element_text(size = 16, hjust = 0.5),
      panel.border = element_rect(color = "black", fill = NA, size = 1),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 12),
      strip.background = element_blank(),
      panel.spacing = unit(0.5, "lines"),
      legend.position = "bottom",
      legend.box.margin = margin(0, 0, 10, 0) # Add margin to legend to avoid overlap
    ) +
    scale_color_brewer(palette = color_palette)
  
  # Return the final plots and dimensions
  return(list(boxplot = boxplot, cplot = cplot, width = plot_width, height = plot_height))
}

generate_boxplots_combined_no_spacing <- function(data, x_col, y_col, x_tit, y_tit, group_col_x = NULL, group_col_y = NULL, group_color = NULL, box_width = 0.5, com_scale = TRUE, color_palette = "Set1", aspect_ratio = 1, x_angle = 45, dodge_width = 0.75, jitter_width = 0.2, outlier_size = 1.5) {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data))) {
    stop("Specified columns do not exist in the data.")
  }
  
  # Convert group columns to factors if they are continuous
  if (!is.null(group_col_x) && group_col_x %in% names(data) && !is.factor(data[[group_col_x]])) {
    data[[group_col_x]] <- as.factor(data[[group_col_x]])
  }
  if (!is.null(group_col_y) && group_col_y %in% names(data) && !is.factor(data[[group_col_y]])) {
    data[[group_col_y]] <- as.factor(data[[group_col_y]])
  }
  if (!is.null(group_color) && group_color %in% names(data) && !is.factor(data[[group_color]])) {
    data[[group_color]] <- as.factor(data[[group_color]])
  }
  
  # Ensure x_col is treated as a factor
  data[[x_col]] <- as.factor(data[[x_col]])
  
  # Calculate number of rows and columns for facets
  n_rows <- length(unique(data[[group_col_y]]))
  n_cols <- length(unique(data[[group_col_x]]))
  
  base_height <- 1
  base_width <- 0.5
  
  # Set base size for each panel
  panel_size <- 4 # Size of each panel in inches
  
  # Calculate plot dimensions based on the number of rows and columns
  plot_width <- panel_size * n_cols + base_width
  plot_height <- panel_size * n_rows * aspect_ratio + base_height
  
  # Generate the base plot with boxplots and facetting
  boxplot <- ggplot(data, aes_string(x = x_col, y = y_col, fill = group_color)) +
    geom_boxplot(width = box_width, position = position_dodge(width = dodge_width), outlier.size = outlier_size) +
    theme_minimal() +
    labs(x = x_tit, y = y_tit) +
    facet_grid(as.formula(paste(group_col_y, "~", group_col_x)), labeller = label_both) +
    theme(
      strip.text = element_text(size = 14, face = "bold"),
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 12),
      plot.title = element_text(size = 16, hjust = 0.5),
      panel.border = element_rect(color = "black", fill = NA, size = 1),
      axis.title = element_text(size = 15),
      axis.text.x = element_text(size = 13, angle = x_angle, hjust = 1),
      axis.text.y = element_text(size = 13),
      strip.background = element_blank(),
      panel.spacing = unit(0.0, "lines"),
      legend.position = "bottom",
      legend.box.margin = margin(0, 0, 10, 0), # Add margin to legend to avoid overlap
      panel.grid.major = element_line(color = "grey70"),
      panel.grid.minor = element_line(color = "grey70")
    ) +
    guides(fill = guide_legend(nrow = numleg)) + # Place legend items in 2 rows
    coord_fixed(ratio = aspect_ratio) + # Fix the aspect ratio
    scale_fill_brewer(palette = color_palette)
  
  # Create the count plot
  counts <- data %>%
    group_by(across(all_of(c(x_col, group_col_x, group_col_y, group_color)))) %>%
    summarise(count = n(), .groups = 'drop')
  
  cplot <- ggplot(counts, aes_string(x = x_col, y = "count", color = group_color)) +
    geom_point(size = 2, position = position_jitter(width = jitter_width, height = 0)) + # Reduce point size and add jitter
    theme_minimal() +
    labs(x = x_tit, y = "Count") +
    facet_grid(as.formula(paste(group_col_y, "~", group_col_x)), labeller = label_both) +
    theme(
      strip.text = element_text(size = 14, face = "bold"),
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 12),
      plot.title = element_text(size = 16, hjust = 0.5),
      panel.border = element_rect(color = "black", fill = NA, size = 1),
      axis.title = element_text(size = 15),
      axis.text.x = element_text(size = 13, angle = x_angle, hjust = 1),
      axis.text.y = element_text(size = 13),
      strip.background = element_blank(),
      panel.spacing = unit(0.0, "lines"),
      legend.position = "bottom",
      legend.box.margin = margin(0, 0, 10, 0),
      panel.grid.major = element_line(color = "grey70"),
      panel.grid.minor = element_line(color = "grey70")
    ) +
    guides(color = guide_legend(nrow = numleg)) + # Place legend items in 2 rows
    coord_fixed(ratio = aspect_ratio) + # Fix the aspect ratio
    scale_color_brewer(palette = color_palette)
  
  # Adjust the y-axis scale if com_scale is TRUE
  if(com_scale) {
    boxplot <- boxplot + coord_cartesian(ylim = range(data[[y_col]], na.rm = TRUE))
    cplot <- cplot + coord_cartesian(ylim = c(0,25))
  }
  
  # Return the final plots and dimensions
  return(list(boxplot = boxplot, cplot = cplot, width = plot_width, height = plot_height))
}

generate_bigcount <- function(data, x_col, y_col, x_tit, y_tit, group_col_x = NULL, group_col_y = NULL, group_color = NULL, box_width = 0.5, com_scale = TRUE, color_palette = "Set1", aspect_ratio = 1, x_angle = 45, dodge_width = 0.75, jitter_width = 0.2, outlier_size = 1.5) {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data))) {
    stop("Specified columns do not exist in the data.")
  }
  
  # Convert group columns to factors if they are continuous
  if (!is.null(group_col_x) && group_col_x %in% names(data) && !is.factor(data[[group_col_x]])) {
    data[[group_col_x]] <- as.factor(data[[group_col_x]])
  }
  if (!is.null(group_col_y) && group_col_y %in% names(data) && !is.factor(data[[group_col_y]])) {
    data[[group_col_y]] <- as.factor(data[[group_col_y]])
  }
  if (!is.null(group_color) && group_color %in% names(data) && !is.factor(data[[group_color]])) {
    data[[group_color]] <- as.factor(data[[group_color]])
  }
  
  # Ensure x_col is treated as a factor
  data[[x_col]] <- as.factor(data[[x_col]])
  
  # Calculate number of rows and columns for facets
  n_rows <- length(unique(data[[group_col_y]]))
  n_cols <- length(unique(data[[group_col_x]]))
  
  base_height <- 1
  base_width <- 0.5
  
  # Set base size for each panel
  panel_size <- 4 # Size of each panel in inches
  
  # Calculate plot dimensions based on the number of rows and columns
  plot_width <- panel_size * n_cols + base_width
  plot_height <- panel_size * n_rows * aspect_ratio + base_height
  
  # Generate the base plot with boxplots and facetting
  boxplot <- ggplot(data, aes_string(x = x_col, y = y_col, fill = group_color)) +
    geom_boxplot(width = box_width, position = position_dodge(width = dodge_width), outlier.size = outlier_size) +
    theme_minimal() +
    labs(x = x_tit, y = y_tit) +
    facet_grid(as.formula(paste(group_col_y, "~", group_col_x)), labeller = label_both) +
    theme(
      strip.text = element_text(size = 14, face = "bold"),
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 12),
      plot.title = element_text(size = 16, hjust = 0.5),
      panel.border = element_rect(color = "black", fill = NA, size = 1),
      axis.title = element_text(size = 15),
      axis.text.x = element_text(size = 13, angle = x_angle, hjust = 1),
      axis.text.y = element_text(size = 13),
      strip.background = element_blank(),
      panel.spacing = unit(0.0, "lines"),
      legend.position = "bottom",
      legend.box.margin = margin(0, 0, 10, 0), # Add margin to legend to avoid overlap
      panel.grid.major = element_line(color = "grey70"),
      panel.grid.minor = element_line(color = "grey70")
    ) +
    guides(fill = guide_legend(nrow = numleg)) + # Place legend items in 2 rows
    coord_fixed(ratio = aspect_ratio) + # Fix the aspect ratio
    scale_fill_brewer(palette = color_palette)
  
  # Create the count plot
  counts <- data %>%
    group_by(across(all_of(c(x_col, group_col_x, group_col_y, group_color)))) %>%
    summarise(count = n(), .groups = 'drop')
  
  cplot <- ggplot(counts, aes_string(x = x_col, y = "count", color = group_color)) +
    geom_point(size = 2, position = position_jitter(width = jitter_width, height = 0)) + # Reduce point size and add jitter
    theme_minimal() +
    labs(x = x_tit, y = "Count") +
    facet_grid(as.formula(paste(group_col_y, "~", group_col_x)), labeller = label_both) +
    theme(
      strip.text = element_text(size = 14, face = "bold"),
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 12),
      plot.title = element_text(size = 16, hjust = 0.5),
      panel.border = element_rect(color = "black", fill = NA, size = 1),
      axis.title = element_text(size = 15),
      axis.text.x = element_text(size = 13, angle = x_angle, hjust = 1),
      axis.text.y = element_text(size = 13),
      strip.background = element_blank(),
      panel.spacing = unit(0.0, "lines"),
      legend.position = "bottom",
      legend.box.margin = margin(0, 0, 10, 0),
      panel.grid.major = element_line(color = "grey70"),
      panel.grid.minor = element_line(color = "grey70")
    ) +
    guides(color = guide_legend(nrow = numleg)) + # Place legend items in 2 rows
    coord_fixed(ratio = aspect_ratio) + # Fix the aspect ratio
    scale_color_brewer(palette = color_palette)
  
  # Adjust the y-axis scale if com_scale is TRUE
  if(com_scale) {
    boxplot <- boxplot + coord_cartesian(ylim = range(data[[y_col]], na.rm = TRUE))
    cplot <- cplot + coord_cartesian(ylim = c(0,25))
  }
  
  # Return the final plots and dimensions
  return(list(boxplot = boxplot, cplot = cplot, width = plot_width, height = plot_height))
}


generate_plot_series_new <- function(data, x_col = "gtime", y_col, x_tit, y_tit, group_col_x, group_col_y, group_color, error_col = NULL, num_samples, com_scale = TRUE, mutate_func = NULL) {
  # Ensure the specified columns exist in the data
  if (!(x_col %in% names(data)) | !(y_col %in% names(data)) | 
      !(group_col_x %in% names(data)) | !(group_col_y %in% names(data)) | !(group_color %in% names(data))) {
    stop("One or more specified columns do not exist in the data.")
  }
  
  # Convert group columns to factors
  data[[group_col_x]] <- as.factor(data[[group_col_x]])
  data[[group_col_y]] <- as.factor(data[[group_col_y]])
  data[[group_color]] <- as.factor(data[[group_color]])
  
  # Create an empty list to store plots
  plot_list <- list()
  cplot_list <- list()
  
  # Initialize variables for global y-axis limits
  global_y_min <- Inf
  global_y_max <- -Inf
  
  # Calculate number of rows and columns for facets
  n_rows <- length(unique(data[[group_col_y]]))
  n_cols <- length(unique(data[[group_col_x]]))
  
  panel_size <- 4 # Size of each panel in inches
  
  # Loop through each unique combination of group_col_x and group_col_y
  for (gy in sort(unique(data[[group_col_y]]))) {
    for (gx in sort(unique(data[[group_col_x]]))) {
      sub_data <- data %>% filter(!!sym(group_col_x) == gx & !!sym(group_col_y) == gy)
      
      plot <- ggplot() +
        theme_minimal() +
        labs(
          x = x_col, 
          y = y_col, 
          title = paste(group_col_x, "=", gx, "&\n", group_col_y, "=", gy)
        ) +
        theme(
          plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_text(size = 13),
          axis.text.y = element_text(size = 13),
          strip.text = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 12),
          legend.position = "none",
          panel.border = element_rect(color = "black", fill = NA, size = 1),
          panel.grid.major = element_line(color = "grey70"),
          panel.grid.minor = element_line(color = "grey70")
        )
      
      cplot <- plot
      
      for (gc in sort(unique(sub_data[[group_color]]))) {
        rep_count <- 0
        subset_data <- sub_data %>% filter(!!sym(group_color) == gc)
        all_sim_data <- list()
        
        for (i in 1:nrow(subset_data)) {
          sim_folder <- subset_data$simulation_folder[i]
          file_path <- list.files(path = paste0("./output/", sim_folder, "/output_sim/"), pattern = "_evolution.csv", full.names = TRUE)[1]
          if (file.exists(file_path)) {
            sim_data <- read_csv(file_path, col_types = cols())
            if (nrow(sim_data) == 1997) {
              rep_count <- rep_count + 1
              if (!is.null(mutate_func)) {
                sim_data <- mutate_func(sim_data)
              }
              sim_data <- add_string_columns(sim_data)
              sim_data[[group_color]] <- as.factor(sim_data[[group_color]])
              all_sim_data[[length(all_sim_data) + 1]] <- sim_data
              if (rep_count == num_samples) {
                break
              }
            }
          }
        }
        
        if (length(all_sim_data) > 0) {
          x_vals <- all_sim_data[[1]][[x_col]]
          y_matrix <- sapply(all_sim_data, function(df) df[[y_col]])
          
          agg_data <- data.frame(
            x_col = x_vals/10000,
            mean_y = rowMeans(y_matrix, na.rm = TRUE),
            sd_y = apply(y_matrix, 1, sd, na.rm = TRUE),
            count = ncol(y_matrix)
          )
          
          current_y_min <- min(agg_data$mean_y - agg_data$sd_y, na.rm = TRUE)
          current_y_max <- max(agg_data$mean_y + agg_data$sd_y, na.rm = TRUE)
          global_y_min <- min(global_y_min, current_y_min)
          global_y_max <- max(global_y_max, current_y_max)
          
          plot <- plot + 
            geom_line(data = agg_data, aes_string(x = "x_col", y = "mean_y", color = paste0("'", as.character(gc), "'"))) +
            geom_ribbon(data = agg_data, aes_string(x = "x_col", ymin = "mean_y - sd_y", ymax = "mean_y + sd_y", fill = paste0("'", as.character(gc), "'")), alpha = 0.3) +
            scale_fill_manual(values = scales::hue_pal()(length(unique(sub_data[[group_color]]))), guide = "none") +
            scale_color_manual(name = group_color, values = scales::hue_pal()(length(unique(sub_data[[group_color]]))))
          
          cplot <- cplot +
            geom_line(data = agg_data, aes_string(x = "x_col", y = "count", color = paste0("'", as.character(gc), "'"))) +
            scale_fill_manual(values = scales::hue_pal()(length(unique(sub_data[[group_color]]))), guide = "none") +
            scale_color_manual(name = group_color, values = scales::hue_pal()(length(unique(sub_data[[group_color]]))))
        }
      }
      
      plot_list[[paste(gy, gx, sep = "_")]] <- plot
      cplot_list[[paste(gy, gx, sep = "_")]] <- cplot
    }
  }
  
  if (com_scale) {
    plot_list <- lapply(plot_list, function(p) {
      p + ylim(global_y_min, global_y_max)
    })
  }
  plot_list <- lapply(plot_list, function(p) {
    p + xlim(0, 10)
  })
  cplot_list <- lapply(cplot_list, function(p) {
    p + ylim(0, 25)
  })
  
  legend_plot <- ggplot(data, aes_string(x = x_col, y = y_col, color = group_color)) +
    geom_line() +
    scale_color_manual(name = group_color, values = scales::hue_pal()(length(unique(data[[group_color]])))) +
    theme_void() + 
    theme(
      legend.text = element_text(size = 12),
      legend.title = element_text(size = 12),
      legend.position = "bottom") +
    guides(color = guide_legend(nrow = numleg))
  
  legend <- extract_legend(legend_plot)
  
  combined_plot <- plot_grid(
    plot_grid(
      plotlist = plot_list,
      ncol = n_cols,
      nrow = n_rows,
      align = 'hv',
      axis = 'tblr'
    )
  )
  
  combined_cplot <- plot_grid(
    plot_grid(
      plotlist = cplot_list,
      ncol = n_cols,
      nrow = n_rows,
      align = 'hv',
      axis = 'tblr'
    )
  )
  
  combined_plot_with_labels <- ggdraw() +
    draw_plot(combined_plot) +
    draw_label(x_tit, 
               x = 0.5, y = -0.05, hjust = 0.5, vjust = 0.5,
               size = 15) +
    draw_label(y_tit, 
               x = -0.02, y = 0.5, hjust = 0.5, vjust = 0.5,
               size = 15, angle = 90)  +
    theme(plot.margin = margin(1, 1, 1, 1, "cm"))
  
  final_combined_plot <- plot_grid(
    combined_plot_with_labels,
    legend,
    ncol = 1,
    rel_heights = c(1, 0.1)
  )
  
  combined_cplot_with_labels <- ggdraw() +
    draw_plot(combined_cplot) +
    draw_label(x_tit, 
               x = 0.5, y = -0.05, hjust = 0.5, vjust = 0.5,
               size = 15) +
    draw_label("Counts / Replicates", 
               x = -0.02, y = 0.5, hjust = 0.5, vjust = 0.5,
               size = 15, angle = 90)  +
    theme(plot.margin = margin(1, 1, 1, 1, "cm"))
  
  final_combined_cplot <- plot_grid(
    combined_cplot_with_labels,
    legend,
    ncol = 1,
    rel_heights = c(1, 0.1)
  )
  base_width <- 0.5
  base_height <- 1
  plot_width <- panel_size * n_cols + base_width
  plot_height <- panel_size * n_rows + base_height
  
  return(list(series_plot = final_combined_plot, count_plot = final_combined_cplot, width = plot_width, height = plot_height))
}
