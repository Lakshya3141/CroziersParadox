source("Rplotting_functions.R")

# Read the data
simulation_data <- read_simulation_data("./combined_simulation_results.csv")
simulation_data <- add_string_columns(simulation_data)
simulation_data <- simulation_data[simulation_data$glasttime > 200*1000-1000, ]
simulation_data <- subsample_replicates(simulation_data, 15)

# Specify filters as a list
filter <- list(
  iKillChoice = c(0, 1),
  iConstStockChoice = c(2),
  iRepChoice = c(0),
  dTickTime = c(1, 2, 3, 4),
  dConstantPopStock = c(50),
  dMutationStrengthCues = c(5),
  dFracKilled = c(0.4),
  dMetabolicCost = c(40),
  dExpParam = c(0.1),
  iModelChoice = c(0, 1, 2, 3)
)

# Filter the data
name_file = "starvation"
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

filter2 <- list(modelnew = c("0_1", "1_1", "2_1", "3_0"))
filtered_data <- filter_simulation_data(filtered_data, filter2)

# Model 3: Cue diversity with recognition model and profile cost
model_cue_diversity_tgen <- lm(bcnest_avg ~ sMi * dTickTime, data = filtered_data)
model_cue_abundance_tgen <- lm(cueabun_avg ~ sMi * dTickTime, data = filtered_data)

summary(model_cue_diversity_tgen)
summary(model_cue_abundance_tgen)

# Save summaries of the models to CSV files
write.csv(summary(model_cue_diversity_tgen)$coefficients, 
          file = paste0("./additional/", name_file, "/model_cue_diversity_tgen_summary.csv"), 
          row.names = TRUE)

write.csv(summary(model_cue_abundance_tgen)$coefficients, 
          file = paste0("./additional/", name_file, "/model_cue_abundance_tgen_summary.csv"), 
          row.names = TRUE)

# Perform pairwise comparisons for Cue Diversity model
pairwise_cue_diversity <- emmeans(model_cue_diversity_tgen, pairwise ~ sMi | dTickTime)
write.csv(pairwise_cue_diversity$contrasts, 
          file = paste0("./additional/", name_file, "/pairwise_cue_diversity_results.csv"), 
          row.names = TRUE)

# Perform pairwise comparisons for Cue Abundance model
pairwise_cue_abundance <- emmeans(model_cue_abundance_tgen, pairwise ~ sMi | dTickTime)
write.csv(pairwise_cue_abundance$contrasts, 
          file = paste0("./additional/", name_file, "/pairwise_cue_abundance_results.csv"), 
          row.names = TRUE)