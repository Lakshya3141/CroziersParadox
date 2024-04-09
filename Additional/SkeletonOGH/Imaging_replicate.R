# Use this code for creating images of a specific replicate
# saves images with replicate number as prefix
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
bigBosstitle <- "Checking"       # Prefix to image file name
num_folder <- 9 # Simulation folder number to be chosen
name_folder <- "output_sim"      # dummy folder

frac_dot <- 0.1            # Fraction of deadIndividuals taken (0.05 def)
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

#### Evolution data processing ####
print("READING EVOLUTION DATA")
# Generate file name pattern
file_pattern <- "_evolution.csv"
# List files in the folder
files <- list.files(path = paste0("./", num_folder ,"/" ,name_folder), pattern = file_pattern, full.names = TRUE)

# Check if files are found
if (length(files) > 0) {
  # Read the first file (assuming only one file matches the pattern)
  combined_data <- read.csv(files[1])
}

# Calculating dispersal probability and spread
combined_data$prob_avg <- 1/(1+exp(combined_data$dispersal_avg))
combined_data$prob_ul <- 1/(1+exp(combined_data$dispersal_avg + combined_data$dispersal_std))
combined_data$prob_ll <- 1/(1+exp(combined_data$dispersal_avg - combined_data$dispersal_std))

##### Dispersal plot #####
print("-> Starting dispersal plots")
# Create a plot for the current condition
p_disp <- ggplot(combined_data, aes(x = gtime, y = prob_avg)) +
  geom_line(linewidth = 1.0) +
  geom_ribbon(aes(ymin = prob_ll, ymax = prob_ul), 
              alpha = 0.3, color = NA, show.legend = FALSE) +
  labs(x = "Time", y = "Dispersal probability") +
  theme_settings +
  ylim(0, 1)

p_rel <- ggplot(combined_data, aes(x = gtime, y = relatedness)) +
  geom_line(linewidth = 1.0) +
  labs(x = "Time", y = "Relatedness") +
  theme_settings +
  ylim(0, 1)


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
  ## Create plot for the current condition and variable ##
  # Adjust aes() and geom_line() accordingly based on the variable
  plot <- ggplot(combined_data,  aes(x = gtime, y = !!sym(variable))) +
    geom_line(linewidth = 1.0) +
    labs(x = "Time", y = title) +
    guides(color = guide_legend(title = "Rep"),
           fill = guide_legend(override.aes = list(color = NULL)))  # Remove fill from the legend
  plot <- plot + theme_settings
# Add the list of plots for the variable to the overall list
plots_additional[[variable]] <- plot
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
  
  plot <- ggplot(combined_data, aes(x = gtime, y = !!sym(variable))) +
      geom_ribbon(aes(ymin = !!sym(paste0("betall",i)), ymax = !!sym(paste0("betaul",i))), 
                  alpha = 0.3, color = NA, show.legend = FALSE) +
      geom_line(linewidth = 1.0) +
      labs(x = "Time", y = title) +
      guides(color = guide_legend(title = "Rep"),
             fill = guide_legend(override.aes = list(color = NULL)))  # Remove fill from the legend
    
    # Add the plot to the list
    plots_betas[[as.character(i)]] <- plot + theme_settings
}

#### dead Individual data processing ####
print("READING DEAD Individual DATA")
file_pattern <- "_deadIndividuals.csv"

# List files in the folder
files <- list.files(path = paste0("./", num_folder ,"/" ,name_folder), pattern = file_pattern, full.names = TRUE)

# Check if files are found
if (length(files) > 0) {
    # Read the first file (assuming only one file matches the pattern)
    combined_data <- read.csv(files[1])
}

combined_data$pertask_foraging = combined_data$num_foraging/combined_data$num_choices * 100
combined_data$pertime_foraging = combined_data$pertime_foraging*100

# Take only individuals with more than n task choices
# and subsequently sample it
subset_data <- combined_data[combined_data$num_choices > min_taskChoice, ] 
subset_data <- subset_data %>% 
  sample_frac(frac_dot, replace = FALSE)

basis_pattern <- "_basis.csv"
basis_files <- list.files(path = paste0("./", num_folder ,"/" , name_folder), pattern = basis_pattern, full.names = TRUE)
# Check if files are found
if (length(basis_files) > 0) {
  # Read the first file (assuming only one file matches the pattern)
  basis <- data.frame(read.csv(basis_files[1], header = FALSE))
  basis <- basis[,-6]
}

##### Dot plots #####
print("-> Starting deadInd dot plot")
# Create a plot for the current condition
# LC: remember, might need to change pertime depending on
# if time is discrete or not
dpt_pertime <- ggplot(subset_data, aes(x = gtime, y = pertime_foraging)) +
  geom_point(size = 0.7) +
  labs(x = "Time", y = "Percentage Time Foraging") +
  ylim(0, 100) +
  theme_settings

dpt_pertask <- ggplot(subset_data, aes(x = gtime, y = pertask_foraging)) +
  geom_point(size = 0.7) +
  labs(x = "Time", y = "Percentage tasks Foraging") +
  ylim(0, 100) +
  theme_settings

##### Histogram #####
print("-> Starting deadInd histogram plot")
# Create a histogram plot for the last last_time units of each replicat

# Take only the ones in last_time units
last_data <- subset_data[subset_data$gtime >= (max(subset_data$gtime) - last_time), ]

hist_pertime_foraging <- ggplot(data = last_data, aes(x = pertime_foraging)) +
  geom_histogram(position = "identity", alpha = 0.7) +
  labs(x = "Percentage Time Foraging", y = "Frequency") +
  xlim(0, 100) +
  theme_settings

hist_pertask_foraging <- ggplot(data = last_data, aes(x = pertask_foraging)) +
  geom_histogram(position = "identity", alpha = 0.7) +
labs(x = "Percentage Task Foraging", y = "Frequency") +
xlim(0, 100) +
theme_settings


##### DeadInd LastTime reaction norms #####
print("-> Starting deadInd reaction Norm plot")
# Take all if need be, else take limited num_reactNorms #
betas <- last_data %>% dplyr::select(beta0, beta1, beta2, beta3, beta4) # select gene values 1-5, which are the gene values for the larval reaction norm
number_larvae <- dim(betas)[1]
if ((number_larvae > num_reactnorms) && !take_all) {
  number_larvae <- num_reactnorms
}
if (!take_all) {
  betas <- betas[sample(nrow(betas), number_larvae, replace = FALSE), ] # sample random 100 larvae
}

mat_results <- matrix(NA, ncol = 2, nrow = nrow(basis) * number_larvae)

print(paste("Num larvae in React =", number_larvae))

# evaluate spline
upper_loop_limit <- nrow(basis) * number_larvae
for (i in c(1:upper_loop_limit)) {
  # multiply each of the rows of the basis matrix with the betas (gene values) as a column vector
  # this occurs first by the 100 different nutrition levels that have been precalculated
  # and then by the different larvae
  mat_results[i,1] <- as.matrix(basis[i - ((i - 1) %/% nrow(basis) * nrow(basis)), ]) %*% t(as.matrix(betas[(i - 1 + nrow(basis)) %/% nrow(basis), ]))
  # record an id for the larvae
  mat_results[i,2] <- (i - 1 + nrow(basis)) %/% nrow(basis)
}
larval_level <- rep(basis$V2, number_larvae) # predetermined steps of x (nutrition level) to the data frame. this can be read from X0 of the basis matrix
data_plotting <- cbind(larval_level, mat_results) # combine these nutrition levels with the spline evaluation
data_plotting <- as.data.frame(data_plotting) # make a data frame
data_plotting$logistic_vals <- 1/(1+exp(data_plotting$V2))
data_plotting$V3 <- as.factor(data_plotting$V3)
data_plotting$larval_level <- data_plotting$larval_level*500.0
p_react_DeadInd <- ggplot(data_plotting, aes(x=larval_level, y=logistic_vals, group=V3)) +
  stat_summary(aes(x=larval_level, y=logistic_vals, group=V3), fun=mean, geom="line", linewidth=1.5, alpha=0.8, col = "grey") +
  scale_y_continuous(name="Foraging probability", limits = c(0.0, 1.0), breaks = seq(0.0, 1.0, 0.2)) +
  scale_x_continuous(name="Larval levels", limits = c(0.0, 500.0), breaks = seq(0.0,500.0,50.0)) +
  theme_settings

#### Last of US data processing ####
print("READING LAST OF US DATA")
combined_data <- data.frame()

file_pattern <- "_LastOfUs.csv"
# List files in the folder
files <- list.files(path = paste0("./", num_folder ,"/" , name_folder), pattern = file_pattern, full.names = TRUE)
# Check if files are found
if (length(files) > 0) {
  # Read the first file (assuming only one file matches the pattern)
  combined_data <- read.csv(files[1])
}


##### Reaction norms, lifespan AND numtaskchoices plots ####
print("-> Starting LOU lifespan, reaction norm and num tasks plot")
# Subset dead individuals (t_death != -1)
dead_individuals <- combined_data[combined_data$t_death != -1, ]

alive_individuals <- combined_data[combined_data$t_death == -1, ]
# Subset alive individuals (keep the row with the largest gtime)
alive_individuals <- alive_individuals[!duplicated(alive_individuals$ind_id, fromLast = TRUE), ]
alive_individuals <- alive_individuals[!(alive_individuals$ind_id %in% unique(dead_individuals$ind_id)), ]
# Combine the subsets if needed
all_individuals <- rbind(dead_individuals, alive_individuals)
  
all_individuals$lifespan <- all_individuals$gtime   - all_individuals$t_birth

num_nests_lou <- 25
nest_data <- all_individuals
betas <- nest_data %>% dplyr::select(beta0, beta1, beta2, beta3, beta4) # select gene values 1-5, which are the gene values for the larval reaction norm
time <- Sys.time() # record system time
set.seed(time) # use time to seed the rng

number_larvae <- dim(nest_data)[1]
if ((number_larvae > num_reactnorms) && !take_all) {
  number_larvae <- num_reactnorms
}

if (!take_all) {
  subset_betas <- betas[sample(nrow(betas), number_larvae, replace = FALSE), ] # sample random 100 larvae
} else {
  subset_betas <- betas
}
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
data_plotting$V3 <- as.factor(data_plotting$V3)
data_plotting$larval_level <- data_plotting$larval_level*500.0
p_nestReact <- ggplot(data_plotting, aes(x=larval_level, y=logistic_vals, group=V3)) +
  stat_summary(aes(x=larval_level, y=logistic_vals, group=V3), fun=mean, geom="line", linewidth=1.5, alpha=0.8, col = "grey") +
  scale_y_continuous(name="Foraging probability", limits = c(0.0, 1.0), breaks = seq(0.0, 1.0, 0.2)) +
  scale_x_continuous(name="Larval levels", limits = c(0.0, 500.0), breaks = seq(0.0,500.0,50.0)) +
  theme_settings

p_lifespan <- ggplot(nest_data, aes(x = lifespan)) +
  geom_histogram(fill = "lightblue", color = "black") +
  theme_settings +
  geom_vline(xintercept = mean(nest_data$lifespan, na.rm = TRUE), col = "red", lwd = 2) +
  annotate("text", x = mean(nest_data$lifespan, na.rm = TRUE), y = 2,
           label = paste("Average Lifespan:", round(mean(nest_data$lifespan, na.rm = TRUE), 2)), col = "red") 

p_tasks <- ggplot(nest_data, aes(x = num_choices)) +
  geom_histogram(fill = "lightblue", color = "black") +
  labs(x = "Number of choices") +
  theme_settings +
  geom_vline(xintercept = mean(nest_data$num_choices, na.rm = TRUE), col = "red", lwd = 2) +
  annotate("text", x = mean(nest_data$num_choices, na.rm = TRUE), y = 2,
           label = paste("Average tasks:", round(mean(nest_data$num_choices, na.rm = TRUE), 2)), col = "red")
  
       
##### nestwise growth graphs #####
print("-> Starting nestwise population plot")
# Find the total number of unique nest IDs
unique_nest_ids <- unique(all_individuals$nest_id)
if (length(unique_nest_ids) > 25 && !take_all) {
  sampled_nests <- 25
} else {
  sampled_nests <- length(unique_nest_ids)
}
# take 25 individuals sampled or however many
sampled_nest_ids <- sample(unique_nest_ids, sampled_nests, replace = FALSE)

# Create a color palette with sampled_nests distinct colors
color_palette <- scales::hue_pal()(sampled_nests)

# Initialize an empty plot
p_nestfem <- ggplot() +
  labs(x = "Time", y = "#Adult Females") +
  theme_settings

p_nestlarv <- ggplot() +
  labs(x = "Time", y = "#Female larvae") +
  theme_settings

# Loop through the sampled nest IDs
for (i in seq_along(sampled_nest_ids)) {
  nest_id <- sampled_nest_ids[i]
  color <- color_palette[i]
  
  # Subset data for the current nest ID
  subset_nest_data <- all_individuals[all_individuals$nest_id == nest_id, ]
  
  # Plot num_adults vs gtime for the current nest with a unique color
  p_nestfem <- p_nestfem + geom_line(data = subset_nest_data, aes(x = gtime, y = num_adults, group = factor(nest_id), color = factor(nest_id)), linetype = "solid") 
  p_nestlarv <- p_nestlarv + geom_line(data = subset_nest_data, aes(x = gtime, y = num_femlarva, group = factor(nest_id), color = factor(nest_id)), linetype = "solid")
}


#### Combining plots ####
print("COMBINING PLOTS")
# larger graphs 
mainy <- wrap_plots(p_disp, dpt_pertime, hist_pertime_foraging, p_react_DeadInd, p_rel, ncol = 1)

# additional graohs
Addit <- wrap_plots(plots_additional, ncol = 1)

# nestwise LOU
LOU <- wrap_plots(p_lifespan, p_nestReact, p_tasks, p_nestfem, p_nestlarv, ncol = 1)

# beta graphs
bet <- wrap_plots(plots_betas, ncol = 1)


print("SAVING PLOTS")
ggsave(paste0(folder_name,"/",num_folder,bigBosstitle,"_Main.png"), mainy, height = 20, width = 5, units = "in", dpi = 300, limitsize = FALSE)
ggsave(paste0(folder_name,"/",num_folder,bigBosstitle,"_BetaVals.png"), bet, height = 25, width = 5, units = "in", dpi = 300, limitsize = FALSE)
ggsave(paste0(folder_name,"/",num_folder,bigBosstitle,"_Additional.png"), Addit, height = 20, width = 5, units = "in", dpi = 300, limitsize = FALSE)
ggsave(paste0(folder_name,"/",num_folder,bigBosstitle,"_LastOfUs.png"), LOU, height = 25, width = 5, units = "in", dpi = 300, limitsize = FALSE)
