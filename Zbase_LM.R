source("Rplotting_functions.R")

# Read the data
simulation_data <- read_simulation_data("./combined_simulation_results.csv")
simulation_data <- add_string_columns(simulation_data)
simulation_data <- simulation_data[simulation_data$glasttime > 200*1000-1000, ]
simulation_data <- subsample_replicates(simulation_data, 15)

# Specify filters as a list
filter_sanity <- list(
  iKillChoice = c(0, 1),
  iConstStockChoice = c(2),
  iRepChoice = c(0),
  dTickTime = c(2),
  dConstantPopStock = c(50),
  dMutationStrengthCues = c(5),
  dFracKilled = c(0.4),
  dMetabolicCost = c(40),
  dExpParam = c(0.1),
  iModelChoice = c(0, 1, 2, 3)
)

# Filter the data
name_file = "base"
if (!dir.exists(paste0("./additional/",name_file))) {
  dir.create(paste0("./additional/",name_file))
}
filtered_data <- filter_simulation_data(simulation_data, filter_sanity)
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

filter2 <- list(modelnew = c("0_1", "1_1", "2_1" ,"3_0"))
filtered_data <- filter_simulation_data(filtered_data, filter2)

# Model 1: Cue diversity with only recognition model as explanatory variable
model_cue_diversity_recognition_only <- lm(bcnest_avg ~ sMi, data = filtered_data)

# Model 2: Cue abundance with only recognition model as explanatory variable
model_cue_abundance_recognition_only <- lm(cueabun_avg ~ sMi, data = filtered_data)

# Model 3: Success stealing with only recognition model as explanatory variable
model_suc_steal_recognition_only <- lm(sucstealfrac ~ sMi, data = filtered_data)


# Summaries for models with only recognition model as explanatory variable
summary(model_cue_diversity_recognition_only)
summary(model_cue_abundance_recognition_only)
summary(model_suc_steal_recognition_only)

# Perform pairwise comparisons for Cue Diversity
pairwise_cue_diversity <- emmeans(model_cue_diversity_recognition_only, pairwise ~ sMi)
pairwise_cue_diversity_results <- summary(pairwise_cue_diversity$contrasts, infer = TRUE)

# Perform pairwise comparisons for Cue Abundance
pairwise_cue_abundance <- emmeans(model_cue_abundance_recognition_only, pairwise ~ sMi)
pairwise_cue_abundance_results <- summary(pairwise_cue_abundance$contrasts, infer = TRUE)

# Perform pairwise comparisons for Suc Steal;
pairwise_suc_steal <- emmeans(model_suc_steal_recognition_only, pairwise ~ sMi)
pairwise_suc_steal_results <- summary(pairwise_suc_steal$contrasts, infer = TRUE)

# Export pairwise comparisons for Cue Diversity to CSV
write.csv(pairwise_cue_diversity_results, file = paste0("./additional/",name_file,"/pairwise_cue_diversity_results.csv"), row.names = FALSE)
write.csv(pairwise_cue_abundance_results, file = paste0("./additional/",name_file,"/pairwise_cue_abundance_results.csv"), row.names = FALSE)
write.csv(pairwise_suc_steal_results, file = paste0("./additional/",name_file,"/pairwise_suc_steal_results.csv"), row.names = FALSE)
