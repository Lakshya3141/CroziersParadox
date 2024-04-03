# Use this code to compare conditions across multiple replicates
# from cluster results
library(ggplot2)
library(tidyverse)
library(ggpubr)
library(gridExtra)
library(patchwork)
library(rlang)

folder_name <- "output_images"     # for outputting images
if (!dir.exists(folder_name)) {
  dir.create(folder_name)
  cat("Folder", folder_name, "created successfully.\n")
} else {
  cat("Folder", folder_name, "already exists.\n")
}

#### Important variables for graphing ####
bigBosstitle <- "LowMean"       # Prefix to image file name
name_folder <- "output_sim"      # dummy folder

# Fraction of deadIndividuals taken (0.05 default)
frac_dot <- 0.1            
# Number of reaction norms to be plotted from end of sim
num_reactnorms <- 25 
# Boolean, if true takes ALL the reaction norms available
take_all = FALSE
# Last n timeunits window from which histogram of
# %time foraging will be made LC: May have to change this
last_time <- 30000
# while making deadInd graph, take individuals with atleast
# these many task choices
min_taskChoice <- 10
num_replicates <- 3  #num replicates in your exploration

#### Housekeeping defintions for images ####
# Define title size and label size variables
title_size <- 18
label_size <- 13

# Adjust theme settings for all plots
theme_settings <- theme_minimal() +
  theme(
    legend.position = "top",
    plot.title = element_text(size = title_size, hjust = 0.5),
    axis.text = element_text(size = label_size, face = "plain", color = "black"),
    axis.title = element_text(size = title_size),
    axis.line = element_line(color = "black", linewidth = 0.6),
    panel.border = element_rect(colour = "darkgray", fill = NA, linetype = 0.5)
  )

#### Reading mapping data and sort conditions ####
# Step 1: Classifying data  
mapping <- read.csv("mapping_noDat.csv")
mapping_all <- read.csv("mapping_dual.csv")
conditions_to_compare <- unique(mapping$condition)
# Use grep to compare all low mean condition
# or add custom vector
conditions_to_compare <- sort(conditions_to_compare[grep("lM", conditions_to_compare)])
conditions_to_compare <- c(conditions_to_compare[-1], conditions_to_compare[1])

#### Evolution data graphs ####
print("READING EVOLUTION DATA")
combined_data <- data.frame()
for (dum in seq(1:dim(mapping)[1])) {
  folder <- mapping$X[dum]
  condition <- mapping$condition[mapping$X == folder]
  print(condition)
  # Check if condition is not NA
  if (mapping$evolution[dum] && (condition %in% conditions_to_compare)) {
    # Generate file name pattern
    file_pattern <- "_evolution.csv"
    
    # List files in the folder
    files <- list.files(path = paste0("./", folder , "/", name_folder), pattern = file_pattern, full.names = TRUE)
    
    # Check if files are found
    if (length(files) > 0) {
      # Read the first file (assuming only one file matches the pattern)
      data <- read.csv(files[1])
      if (dim(data)[1] > 0) {
        data$rep <- mapping$rp[mapping$X == folder]
        data$cond <- condition
        
        # Combine with previous data or create a new dataset
        if (exists("combined_data")) {
          combined_data <- rbind(combined_data, data)
        } else {
          combined_data <- data
        }
      } else {
        mapping$evolution[dum] = 2
      }
    }
  }
}

combined_data$prob_avg <- 1/(1+exp(combined_data$dispersal_avg))
combined_data$prob_ul <- 1/(1+exp(combined_data$dispersal_avg + combined_data$dispersal_std))
combined_data$prob_ll <- 1/(1+exp(combined_data$dispersal_avg - combined_data$dispersal_std))

##### Dispersal plot #####
print("-> Starting dispersal plots")
valid_conditions <- c()
# Create a list to store plots for each condition
plots_dispersal <- list()
plots_relatedness <- list()
# Loop through each condition
for (condition in conditions_to_compare) {
  # Subset the combined_data for the specific condition
  if (condition %in% unique(mapping$condition)) {
    append(valid_conditions, condition)
    subset_data <- combined_data[combined_data$cond == condition, ]
    
    # Create a plot for the current condition
    plot <- ggplot(subset_data, aes(x = gtime, y = prob_avg, color = factor(rep))) +
      geom_line(linewidth = 1.0) +
      geom_ribbon(aes(ymin = prob_ll, ymax = prob_ul, fill = factor(rep)), 
                  alpha = 0.3, color = NA, show.legend = FALSE) +
      labs(title = condition, x = "Time", y = "Disp prob") +
      ylim(0, 1) +
      theme_settings +
      guides(color = guide_legend(title = "Rep"),
             fill = guide_legend(override.aes = list(color = NULL)))  # Remove fill from the legend
    
    p_rel <- ggplot(subset_data, aes(x = gtime, y = relatedness, color = factor(rep))) +
      geom_line(linewidth = 1.0) +
      labs(title = condition, x = "Time", y = "Relatedness") +
      theme_settings + 
      ylim(0, 1) +
      guides(color = guide_legend(title = "Rep"),
             fill = guide_legend(override.aes = list(color = NULL)))  # Remove fill from the legend
    
    # Add the plot to the list
    plots_dispersal[[condition]] <- plot
    plots_relatedness[[condition]] <- p_rel
  }
}


##### Additional evolution graphs #####
print("-> Starting additional population plots")
# Additional variables to consider
additional_variables <- c("num_female", "num_male", "fem_avg", "femLarv_avg")

# Corresponding titles for each variable
variable_titles <- c("Total Females", "Total Males", "Female Average", "Female Larval Average")

# Create a list to store plots for each additional variable
plots_additional <- list()
# Loop through each additional variable
for (i in seq_along(additional_variables)) {
  variable <- additional_variables[i]
  title <- variable_titles[i]
  
  # Create a list to store plots for each condition
  plots_variable <- list()
  
  # Loop through each condition
  for (condition in conditions_to_compare) {
    # Subset the combined_data for the specific condition
    if (condition %in% unique(mapping$condition)) {
      append(valid_conditions, condition)
      subset_data <- combined_data[combined_data$cond == condition, ]
      
      ## Create plot for the current condition and variable ##
      # Adjust aes() and geom_line() accordingly based on the variable
      plot <- ggplot(subset_data,  aes(x = gtime, y = !!sym(variable), color = factor(rep))) +
        geom_line(linewidth = 1.0) +
        labs(title = paste(condition, "-", title), x = "Time", y = title) +
        theme_settings +
        guides(color = guide_legend(title = "Rep"),
               fill = guide_legend(override.aes = list(color = NULL)))  # Remove fill from the legend
      
      # Add the plot to the list
      plots_variable[[condition]] <- plot
    }
  }
  
  # Add the list of plots for the variable to the overall list
  plots_additional[[variable]] <- plots_variable
}

##### Beta val graphs #####
print("-> Starting BetaVals graphs")
plots_betas <- list()
for (i in 0:4) {
  combined_data[[paste0("betall",i)]] <- combined_data[[paste0("beta",i,"_avg")]] - combined_data[[paste0("beta",i,"_std")]]
  combined_data[[paste0("betaul",i)]] <- combined_data[[paste0("beta",i,"_avg")]] + combined_data[[paste0("beta",i,"_std")]]
}

for (i in 0:4) {
  variable <- paste0("beta",i,"_avg")
  varstd <- paste0("beta",i,"_std")
  title <- paste0("Beta Val ",i)
  # Create a list to store plots for each condition
  plots_variable <- list()
  # Loop through each condition
  for (condition in conditions_to_compare) {
    # Subset the combined_data for the specific condition
    if (condition %in% unique(mapping$condition)) {
      append(valid_conditions, condition)
      subset_data <- combined_data[combined_data$cond == condition, ]
      ## Create plot for the current condition and variable ##
      # Adjust aes() and geom_line() accordingly based on the variable
      plot <- ggplot(subset_data, aes(x = gtime, y = !!sym(variable), color = factor(rep))) +
        geom_ribbon(aes(ymin = !!sym(paste0("betall",i)), ymax = !!sym(paste0("betaul",i)), fill = factor(rep)), 
                    alpha = 0.3, color = NA, show.legend = FALSE) +
        geom_line(linewidth = 1.0) +
        labs(title = paste(condition, "-", title), x = "Time", y = title) +
        theme_settings +
        guides(color = guide_legend(title = "Rep"),
               fill = guide_legend(override.aes = list(color = NULL)))  # Remove fill from the legend
      
      # Add the plot to the list
      plots_variable[[condition]] <- plot
    }
  }
  
  # Add the list of plots for the variable to the overall list
  plots_betas[[variable]] <- plots_variable
}

#### dead Individual data graphs ####
print("READING DEAD Individual DATA")
combined_data <- data.frame()
for (dum in seq(1:dim(mapping)[1])) {
  folder <- mapping$X[dum]
  condition <- mapping$condition[mapping$X == folder]
  
  # Check if condition is not NA
  if (mapping$deadInd[dum] && (condition %in% conditions_to_compare)) {
    # Generate file name pattern
    file_pattern <- "_deadIndividuals.csv"
    
    # List files in the folder
    files <- list.files(path = paste0("./", folder, "/" , name_folder), pattern = file_pattern, full.names = TRUE)
    
    # Check if files are found
    if (length(files) > 0) {
        # Read the first file (assuming only one file matches the pattern)
        data <- read.csv(files[1])
        
        if(dim(data)[1] > 0) {
        data <- subset(data, num_choices > 40)
        data$rep <- mapping$rp[mapping$X == folder]
        data$cond <- condition
        
        # Combine with previous data or create a new dataset
        if (exists("combined_data")) {
          combined_data <- rbind(combined_data, data)
        } else {
          combined_data <- data
        }
      }
    }
  }
}

combined_data$pertask_foraging = combined_data$num_foraging/combined_data$num_choices * 100
combined_data$pertime_foraging = combined_data$pertime_foraging*100

##### Dot plots #####
valid_conditions <- c()
# Create a list to store plots for each condition
plots_taskChoice <- list()
plots_perForaging <- list()
plots_histPertimeforaging <- list()
plots_histPertaskforaging <- list()
colors_hist <- scales::hue_pal()(3)
# Loop through each condition
for (condition in conditions_to_compare) {
  # Subset the combined_data for the specific condition
  if (condition %in% unique(mapping$condition)) {
    append(valid_conditions, condition)
    subset_data <- combined_data[combined_data$cond == condition, ]
    hist_pertime_foraging <- ggplot() + theme_void()  # Initialize an empty plot
    hist_pertask_foraging <- ggplot() + theme_void()
    dpt_pertask <- ggplot() + theme_void()
    dpt_pertime <- ggplot() + theme_void()
    
    if (nrow(subset_data) > 1) {
      # Take 10% of samples
      subset_data <- subset_data %>% 
        sample_frac(frac_dot, replace = FALSE)
      
      # Create a plot for the current condition
      dpt_pertime <- ggplot(subset_data, aes(x = gtime, y = pertime_foraging, color = factor(rep))) +
        geom_point(size = 0.7) +
        labs(x = "time", y = "%Time For.") +
        theme_settings +
        theme(legend.position = "top") +
        ylim(0, 100) +
        guides(color = guide_legend(title = "Rep"),
               fill = guide_legend(override.aes = list(color = NULL)))  # Remove fill from the legend
      
      dpt_pertask <- ggplot(subset_data, aes(x = gtime, y = pertask_foraging, color = factor(rep))) +
        geom_point(size = 0.7) +
        labs(x = "time", y = "% task For.") +
        theme_settings +
        theme(legend.position = "top") +
        ylim(0, 100) +
        guides(color = guide_legend(title = "Rep"),
               fill = guide_legend(override.aes = list(color = NULL)))  # Remove fill from the legend
      
      # Create a histogram plot for the last 100,000 units of each replicate
      
      # Loop through each replicate
      for (rep_val in unique(subset_data$rep)) {
        rep_data <- subset_data[subset_data$rep == rep_val, ]
        last_100k_data <- rep_data[rep_data$gtime >= (max(rep_data$gtime) - last_time), ]
        
        hist_pertime_foraging <- hist_pertime_foraging +
          geom_histogram(data = last_100k_data, aes(x = pertime_foraging),
                         position = "identity", alpha = 0.7,
                         color = colors_hist[rep_val]) +
          labs(x = "Percentage Time Foraging", y = "Frequency") +
          theme_settings +
          xlim(0, 100) +
          theme(legend.position = "top") +
          guides(color = guide_legend(title = "Rep")) 
        
        hist_pertask_foraging <- hist_pertask_foraging +
          geom_histogram(data = last_100k_data, 
                         aes(x = pertask_foraging),
                         position = "identity", alpha = 0.7,
                         color = colors_hist[rep_val]) +
          labs(x = "Percentage Task Foraging", y = "Frequency") +
          theme_settings +
          xlim(0, 100) +
          theme(legend.position = "top") +
          guides(color = guide_legend(title = "Rep")) 
      }
    }
    # Add the plots to the respective lists
    plots_taskChoice[[condition]] <- dpt_pertask
    plots_perForaging[[condition]] <- dpt_pertime
    plots_histPertimeforaging[[condition]] <- hist_pertime_foraging
    plots_histPertaskforaging[[condition]] <- hist_pertask_foraging
  }
}

#### Last of US data processing ####
print("READING LAST OF US DATA")
combined_data <- data.frame()
noLOUfound <- FALSE
dum_count <- 0 # dummy variable to check 
for (dum in seq(1:dim(mapping)[1])) {
  folder <- mapping$X[dum]
  condition <- mapping$condition[mapping$X == folder]
  
  # Check if condition is not NA
  if (mapping$lou[dum] && (condition %in% conditions_to_compare)) {
    dum_count <- dum_count + 1
    # Generate file name pattern
    file_pattern <- "_LastOfUs.csv"
    # List files in the folder
    files <- list.files(path = paste0("./", folder, "/" , name_folder), pattern = file_pattern, full.names = TRUE)
    # Check if files are found
    if (length(files) > 0) {
      # Read the first file (assuming only one file matches the pattern)
      data <- read.csv(files[1])
      data$rep <- mapping$rp[mapping$X == folder]
      data$cond <- condition
      # Combine with previous data or create a new dataset
      if (exists("combined_data")) {
        combined_data <- rbind(combined_data, data)
      } else {
        combined_data <- data
      }
    }
  }
}

##### Reaction norms, lifespan AND numtaskchoices plots ####
# Number of replicates
if(dum_count != 0) {
  # Subset dead individuals (t_death != -1)
  dead_individuals <- combined_data[combined_data$t_death != -1, ]
  
  alive_individuals <- combined_data[combined_data$t_death == -1, ]
  # Subset alive individuals (keep the row with the largest gtime)
  alive_individuals <- alive_individuals[!duplicated(alive_individuals$ind_id, fromLast = TRUE), ]
  alive_individuals <- alive_individuals[!(alive_individuals$ind_id %in% unique(dead_individuals$ind_id)), ]
  # Combine the subsets if needed
  all_individuals <- rbind(dead_individuals, alive_individuals)
  valid_conditions <- c()
  
  all_individuals$lifespan <- all_individuals$gtime   - all_individuals$t_birth
  
  if (sum(alive_individuals$t_birth == 0) > 0) {
    print(paste0(sum(alive_individuals$t_birth == 0)," Individuals from start survived"))
  } else {
    print("NO Individuals from the start survived")
  }
  num_nests_lou <- 25
  
  # Loop through each condition
  # Loop through each condition
  valid_conditions <- c()
  dum_color <- c("blue", "red", "green")
  colors_vector <- c("#FF0000", "#0000FF", "#00FF00", "#000000", "#FFC0CB")
  # Create a vector of unique colors for replicates
  # replicate_colors <- viridis::viridis_pal()(length(unique(subset_data$rep)))
  
  # Create an empty list to store plots
  subset_data <- data.frame()
  plots_react <- list()
  plots_lifespans <- list()
  plots_numtasks <- list()
  
  for (condition in conditions_to_compare) {
    # Subset the combined_data for the specific condition
    if (condition %in% unique(mapping$condition)) {
      valid_conditions <- c(valid_conditions, condition)
      subset_data <- all_individuals[all_individuals$cond == condition, ]
      
      # Create a list to store plots for each replicate
      plots_replicates <- list()
      plots_lifereps <- list()
      plots_tasksreps <- list()
      
      for (replic in unique(subset_data$rep)) {
        print(paste(condition, " : ", replic))
        folder <- mapping$X[mapping$condition == condition & mapping$rp == replic]
        basis_pattern <- "_basis.csv"
        basis_files <- list.files(path = paste0("./", folder, "/", name_folder), pattern = basis_pattern, full.names = TRUE)
        # Check if files are found
        if (length(basis_files) > 0) {
          # Read the first file (assuming only one file matches the pattern)
          basis <- data.frame(read.csv(basis_files[1], header = FALSE))
          basis <- basis[,-6]
        }
        
        rep_subset <- subset_data[subset_data$rep == replic, ]
        betas <- rep_subset %>% dplyr::select(beta0, beta1, beta2, beta3, beta4) # select gene values 1-5, which are the gene values for the larval reaction norm
        
        time <- Sys.time() # record system time
        set.seed(time) # use time to seed the rng
        
        number_larvae <- length(unique(rep_subset$ind_id))
        if (number_larvae > num_reactnorms) {
          number_larvae <- num_reactnorms
        }
        subset_betas <- betas[sample(nrow(betas), number_larvae, replace = FALSE), ] # sample random 100 larvae
        mat_results <- matrix(NA, ncol = 2, nrow = nrow(basis) * number_larvae)
        
        # number_larvae <- 10
        # evaluate spline
        upper_loop_limit <- nrow(basis) * number_larvae
        for (i in c(1:upper_loop_limit)) {
          # multiply each of the rows of the basis matrix with the betas (gene values) as a column vector
          # this occurs first by the 100 different nutrition levels that have been precalculated
          # and then by the different larvae
          mat_results[i,1] <- as.matrix(basis[i - ((i - 1) %/% nrow(basis) * nrow(basis)), ]) %*% t(as.matrix(subset_betas[(i - 1 + nrow(basis)) %/% nrow(basis), ]))
          # record an id for the larvae
          mat_results[i,2] <- (i - 1 + nrow(basis)) %/% nrow(basis)
        }
        larval_level <- rep(basis$V2, number_larvae) # predetermined steps of x (nutrition level) to the data frame. this can be read from X0 of the basis matrix
        data_plotting <- cbind(larval_level, mat_results) # combine these nutrition levels with the spline evaluation
        data_plotting <- as.data.frame(data_plotting) # make a data frame
        data_plotting$logistic_vals <- 1/(1+exp(data_plotting$V2))
        color_value <- colors_vector[replic]
        data_plotting$V3 <- as.factor(data_plotting$V3)
        data_plotting$larval_level <- data_plotting$larval_level*500.0
        p <- ggplot(data_plotting, aes(x=larval_level, y=logistic_vals, group=V3)) +
          stat_summary(aes(x=larval_level, y=logistic_vals, group=V3), fun=mean, geom="line", linewidth=1.5, alpha=0.8, col = "grey") +
          scale_y_continuous(name="Foraging probability", limits = c(0.0, 1.0), breaks = seq(0.0, 1.0, 0.2)) +
          scale_x_continuous(name="Larval levels", limits = c(0.0, 500.0), breaks = seq(0.0,500.0,50.0)) +
          theme_settings +
          labs(title = paste0(condition, " : ", replic))
        
        p_lifespan <- ggplot(rep_subset, aes(x = lifespan)) +
          geom_histogram(fill = "lightblue", color = "black") +
          labs(title = paste0(condition, " : ", replic), x = "Lifespan") +
          theme_settings +
          theme(legend.position = "none") +
          geom_vline(xintercept = mean(rep_subset$lifespan, na.rm = TRUE), col = "red", lwd = 2) +
          annotate("text", x = mean(rep_subset$lifespan, na.rm = TRUE), y = 10,
                   label = paste("Average Lifespan:", round(mean(rep_subset$lifespan, na.rm = TRUE), 2)), col = "red")
        
        p_tasks <- ggplot(rep_subset, aes(x = num_choices)) +
          geom_histogram(fill = "lightblue", color = "black") +
          theme_settings +
          labs(title = paste0(condition, " : ", replic), x = "Number of choices") +
          theme(legend.position = "none") +
          geom_vline(xintercept = mean(rep_subset$num_choices, na.rm = TRUE), col = "red", lwd = 2) +
          annotate("text", x = mean(rep_subset$num_choices, na.rm = TRUE), y = 10,
                   label = paste("Average num_choices:", round(mean(rep_subset$num_choices, na.rm = TRUE), 2)), col = "red")
        
        # Add the plot to the list for replicates
        plots_replicates[[as.character(replic)]] <- p
        plots_lifereps[[as.character(replic)]] <- p_lifespan
        plots_tasksreps[[as.character(replic)]] <- p_tasks
      }
      
      # Add the list of plots for replicates to the overall list
      plots_react[[condition]] <- plots_replicates
      plots_lifespans[[condition]] <- plots_lifereps
      plots_numtasks[[condition]] <- plots_tasksreps 
    }
  }
  
  ##### nestwise growth graphs #####
  print("-> Starting nestwise population plot")
  plots_NestFem <- list()
  plots_NestLarv <- list()
  for (condition in conditions_to_compare) {
    # Subset the combined_data for the specific condition
    if (condition %in% unique(mapping$condition)) {
      valid_conditions <- c(valid_conditions, condition)
      subset_data <- all_individuals[all_individuals$cond == condition, ]
      # Create a list to store plots for each replicate
      plots_femreps <- list()
      plots_larvreps <- list()
      
      for (replic in unique(subset_data$rep)) {
        print(paste(condition, " : ", replic))
        folder <- mapping$X[mapping$condition == condition && mapping$rp == replic]
        rep_subset <- subset_data[subset_data$rep == replic, ]
        # Find the total number of unique nest IDs
        unique_nest_ids <- unique(rep_subset$nest_id)
        if (length(unique_nest_ids) > 25) {
          sampled_nests <- 25
        } else {
          sampled_nests <- length(unique_nest_ids)
        }
        # take 25 individuals sampled or however many
        sampled_nest_ids <- sample(unique_nest_ids, sampled_nests)
        
        # Create a color palette with sampled_nests distinct colors
        color_palette <- scales::hue_pal()(sampled_nests)
        
        # Initialize an empty plot
        p_nestfem <- ggplot() +
          labs(title = paste0(condition, " : ", replic), x = "time", y = "#Adult Females") +
          theme_settings +
          theme(legend.position = "none")
        
        p_nestlarv <- ggplot() +
          labs(title = paste0(condition, " : ", replic), x = "time", y = "#Female larvae") +
          theme_settings +
          theme(legend.position = "none")
        
        # Loop through the sampled nest IDs
        for (i in seq_along(sampled_nest_ids)) {
          nest_id <- sampled_nest_ids[i]
          color <- color_palette[i]
          
          # Subset data for the current nest ID
          subset_nest_data <- rep_subset[rep_subset$nest_id == nest_id, ]
          
          # Plot num_adults vs gtime for the current nest with a unique color
          p_nestfem <- p_nestfem + geom_line(data = subset_nest_data, aes(x = gtime, y = num_adults, group = factor(nest_id), color = factor(nest_id)), linetype = "solid") 
          p_nestlarv <- p_nestlarv + geom_line(data = subset_nest_data, aes(x = gtime, y = num_femlarva, group = factor(nest_id), color = factor(nest_id)), linetype = "solid")
        }
        # Add the plot to the list for replicates
        plots_femreps[[as.character(replic)]] <- p_nestfem
        plots_larvreps[[as.character(replic)]] <- p_nestlarv
      }
      
      # Add the list of plots for replicates to the overall list
      plots_NestFem[[condition]] <- plots_femreps
      plots_NestLarv[[condition]] <- plots_larvreps
    }
  }
}

#### Combining AND SAVING plots ####
##### Dispersal + foraging + relatedness #####
plot_titles <- c("Dispersal Plot", "% Foraging")

final_plot_dispersal <- wrap_plots(plots_dispersal, ncol = length(conditions_to_compare),
                                   guides = 'keep') +
  plot_annotation(title = "Dispersal Plots")

final_plot_perForaging <- wrap_plots(plots_perForaging, ncol = length(conditions_to_compare),
                                     guides = 'keep') +
  plot_annotation(title = "Time foraging Plot")

final_plot_pertime <- wrap_plots(plots_taskChoice, ncol = length(conditions_to_compare),
                                 guides = 'keep') +
  plot_annotation(title = "Task Choice Plot")

final_plot_histPertimeforaging <- wrap_plots(plots_histPertimeforaging, ncol = length(conditions_to_compare),
                                             guides = 'keep') +
  plot_annotation(title = "Hist Pertime Foraging Plot")

final_plot_histPertaskforaging <- wrap_plots(plots_histPertaskforaging, ncol = length(conditions_to_compare),
                                             guides = 'keep') +
  plot_annotation(title = "Hist Pertask Foraging Plot")

final_plot_rel <- wrap_plots(plots_relatedness, ncol = length(conditions_to_compare),
                          guides = 'keep') +
  plot_annotation(title = "Relatedness")

# Combine all final plots
final_combined_plot <- wrap_plots(
  final_plot_dispersal + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_perForaging + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_pertime + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_histPertimeforaging + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_histPertaskforaging + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_rel + plot_layout(ncol = length(conditions_to_compare)),
  ncol = 1
)

# Display the final combined plot

ggsave(paste0(folder_name, "/" ,bigBosstitle,"_DispForage.png"), final_combined_plot, height = 30, width = length(conditions_to_compare)*5, units = "in", dpi = 300, limitsize = FALSE)
print("Saved DispForage Graphs")

##### Additional graphs #####

plot_titles <- c("Total female population", "Total male population", "Average Nest size", "Average femLarva")

# Create a list to store the final plots for each category

final_plot_1 <- wrap_plots(plots_additional$num_female, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[1])

final_plot_2 <- wrap_plots(plots_additional$num_male, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[2])

final_plot_3 <- wrap_plots(plots_additional$fem_avg, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[3])

final_plot_4 <- wrap_plots(plots_additional$femLarv_avg, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[4])



# Combine all final plots
final_combined_plot <- wrap_plots(
  final_plot_1 + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_2 + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_3 + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_4 + plot_layout(ncol = length(conditions_to_compare)),
  ncol = 1
)

# Display the final combined plot

ggsave(paste0(folder_name, "/" ,bigBosstitle,"_Additional.png"), final_combined_plot, height = 20, width = length(conditions_to_compare)*5, units = "in", dpi = 300, limitsize = FALSE)
print("Saved Additional Graphs")

##### Beta val graphs #####

plot_titles <- c("Beta Val 0", "Beta Val 1", "Beta Val 2", "Beta Val 3", "Beta Val 4")

# Create a list to store the final plots for each category

final_plot_1 <- wrap_plots(plots_betas$beta0_avg, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[1])

final_plot_2 <- wrap_plots(plots_betas$beta1_avg, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[2])

final_plot_3 <- wrap_plots(plots_betas$beta2_avg, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[3])

final_plot_4 <- wrap_plots(plots_betas$beta3_avg, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[4])

final_plot_5 <- wrap_plots(plots_betas$beta4_avg, ncol = length(conditions_to_compare),
                           guides = 'keep') +
  plot_annotation(title = plot_titles[5])



# Combine all final plots
final_combined_plot <- wrap_plots(
  final_plot_1 + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_2 + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_3 + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_4 + plot_layout(ncol = length(conditions_to_compare)),
  final_plot_5 + plot_layout(ncol = length(conditions_to_compare)),
  ncol = 1
)

# Display the final combined plot

ggsave(paste0(folder_name, "/" ,bigBosstitle,"_BetaVals.png"), final_combined_plot, height = 20, width = length(conditions_to_compare)*5, units = "in", dpi = 300, limitsize = FALSE)
print("Saved Beta Vals Graphs")

##### Reaction norms #####

# Number of rows and columns in the grid
num_rows <- num_replicates
num_cols <- length(conditions_to_compare)
if (dum_count != 0) {
  # Create an empty list to store plots
  plots_list <- vector("list", length = num_rows * num_cols)
  
  # Create a predefined grid
  grid <- matrix(plots_list, nrow = num_rows, ncol = num_cols)
  rownames(grid) <- seq(1:num_replicates)
  colnames(grid) <- conditions_to_compare
  mapping$condition[is.na(mapping$condition)] <- "nodata"
  
  # Double for loop to add plots to the grid
  for (cond in conditions_to_compare) {
    for (rep in 1:num_replicates) {
      current_plot <- NULL
      if (any(mapping$lou[mapping$rp == rep & mapping$condition == cond] == 1)) {
        # Create your individual plot (replace this with your own plot creation code)
        current_plot <- plots_react[[cond]][[as.character(rep)]]
      } else {
        current_plot <- ggplot() + 
          theme_void()
      }
      # Add the plot to the grid
      grid[rep, cond] <- list(current_plot)
    }
  }
  
  # Arrange the grid using grid.arrange
  final_grid_plot <- grid.arrange(grobs = t(grid), ncol = num_cols)
  # Add a title to the final_grid_plot
  ggsave(paste0(folder_name, "/" ,bigBosstitle,"_ReactNorms.png"), final_grid_plot, height = num_replicates*5, width = length(conditions_to_compare)*5, units = "in", dpi = 300, limitsize = FALSE)
  print("Saved Reaction norm Graphs")
}

##### Lifespan graphs #####
if (dum_count != 0) {
  # Create an empty list to store plots
  plots_list <- vector("list", length = num_rows * num_cols)
  
  # Create a predefined grid
  grid <- matrix(plots_list, nrow = num_rows, ncol = num_cols)
  rownames(grid) <- seq(1:num_replicates)
  colnames(grid) <- conditions_to_compare
  mapping$condition[is.na(mapping$condition)] <- "nodata"
  
  # Double for loop to add plots to the grid
  for (cond in conditions_to_compare) {
    for (rep in 1:num_replicates) {
      current_plot <- NULL
      if (any(mapping$lou[mapping$rp == rep & mapping$condition == cond] == 1)) {
        current_plot <- plots_lifespans[[cond]][[as.character(rep)]]
      } else {
        current_plot <- ggplot() + 
          theme_void()
      }
      # Add the plot to the grid
      grid[rep, cond] <- list(current_plot)
    }
  }
  # Arrange the grid using grid.arrange
  final_grid_plot <- grid.arrange(grobs = t(grid), ncol = num_cols)
  # Add a title to the final_grid_plot
  ggsave(paste0(folder_name, "/" ,bigBosstitle,"_Lifespans.png"), final_grid_plot, height = num_replicates*5, width = length(conditions_to_compare)*5, units = "in", dpi = 300, limitsize = FALSE)
  print("Saved Lifespan Graphs")
}

##### numChoices graphs #####
if(dum_count != 0){
  # Create an empty list to store plots
  plots_list <- vector("list", length = num_rows * num_cols)
  
  # Create a predefined grid
  grid <- matrix(plots_list, nrow = num_rows, ncol = num_cols)
  rownames(grid) <- seq(1:num_replicates)
  colnames(grid) <- conditions_to_compare
  
  # Double for loop to add plots to the grid
  for (cond in conditions_to_compare) {
    for (rep in 1:num_replicates) {
      current_plot <- NULL
      if (any(mapping$lou[mapping$rp == rep & mapping$condition == cond] == 1)) {
        current_plot <- plots_numtasks[[cond]][[as.character(rep)]]
      } else {
        current_plot <- ggplot() + 
          theme_void()
      }
      # Add the plot to the grid
      grid[rep, cond] <- list(current_plot)
    }
  }
  
  # Arrange the grid using grid.arrange
  final_grid_plot <- grid.arrange(grobs = t(grid), ncol = num_cols)
  # Add a title to the final_grid_plot
  ggsave(paste0(folder_name, "/" ,bigBosstitle,"_numChoices.png"), final_grid_plot, height = num_replicates*5, width = length(conditions_to_compare)*5, units = "in", dpi = 300, limitsize = FALSE)
  print("Saved numchoices graphs")
}
if (dum_count == 0) {
  print("No Last fo Us DATA!!!")
}

##### Nestwise graphs #####
if(dum_count != 0){
  # Create an empty list to store plots
  plots_list <- vector("list", length = num_rows * num_cols)
  plots_listlarv <- vector("list", length = num_rows * num_cols)
  
  # Create a predefined grid
  grid <- matrix(plots_list, nrow = num_rows, ncol = num_cols)
  rownames(grid) <- seq(1:num_replicates)
  colnames(grid) <- conditions_to_compare
  
  grid_larv <- matrix(plots_listlarv, nrow = num_rows, ncol = num_cols)
  rownames(grid_larv) <- seq(1:num_replicates)
  colnames(grid_larv) <- conditions_to_compare
  
  # Double for loop to add plots to the grid
  for (cond in conditions_to_compare) {
    for (rep in 1:num_replicates) {
      current_plot <- NULL
      current_plotlarv <- NULL
      if (any(mapping$lou[mapping$rp == rep & mapping$condition == cond] == 1)) {
        current_plot <- plots_NestFem[[cond]][[as.character(rep)]]
        current_plotlarv <- plots_NestLarv[[cond]][[as.character(rep)]]
      } else {
        current_plot <- ggplot() +
          theme_minimal()
        current_plotlarv <- ggplot() +
          theme_minimal()
      }
      # Add the plot to the grid
      grid[rep, cond] <- list(current_plot)
      grid_larv[rep, cond] <- list(current_plotlarv)
    }
  }
  
  # Arrange the grid using grid.arrange
  final_grid_plot <- grid.arrange(grobs = t(grid), ncol = num_cols)
  final_gridlarv_plot <- grid.arrange(grobs = t(grid_larv), ncol = num_cols)
  # Add a title to the final_grid_plot
  ggsave(paste0(folder_name, "/" ,bigBosstitle,"_NestFemales.png"), final_grid_plot, height = num_replicates*5, width = length(conditions_to_compare)*5, units = "in", dpi = 300, limitsize = FALSE)
  ggsave(paste0(folder_name, "/" ,bigBosstitle,"_NestFemLarvae.png"), final_gridlarv_plot, height = num_replicates*5, width = length(conditions_to_compare)*5, units = "in", dpi = 300, limitsize = FALSE)
  print("Saved Nestwise graphs")
}
if (dum_count == 0) {
  print("No Last fo Us DATA!!!")
}