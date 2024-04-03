options(scipen = 999)

create_config <- function(config_file_name = "config.ini",
                          dLarvaMatureSize = 1.0,
                          
                          dForagingTime = 4.0,
                          dBroodingTime = 4.0,
                          dForagingTimeSD = 1.0,
                          dBroodingTimeSD = 1.0,
                          dTransitionForagingBrooding = 0.0,
                          dTransitionBroodingForaging = 0.0,
                          dSurvTransitionForagingBrooding = 0.99,
                          dSurvTransitionBroodingForaging = 0.99,
                          dDeathTime = 2.0,
                          dMaleLambda = 0.01,
                          dLarvaeLambda = 0.01,
                          
                          dMutRate = 0.03,
                          dMutBias = 0.0,
                          dMutEffect = 0.04,
                          
                          dSurvForage = 0.99,
                          dSurvBrood = 0.99,
                          dForagingMean = 0.5,
                          dForagingSD = 0.5,
                          const_sex_ratio = 0.5,
                          params_to_record = "dForagingSD,dForagingMean") {
  
  newini <- list()
  newini[["params"]] <-
    list("dLarvaMatureSize" = dLarvaMatureSize,
         
         "dForagingTime" = dForagingTime,
         "dBroodingTime" = dBroodingTime,
         "dForagingTimeSD" = dForagingTimeSD,
         "dBroodingTimeSD" = dBroodingTimeSD,
         "dTransitionForagingBrooding" = dTransitionForagingBrooding,
         "dTransitionBroodingForaging" = dTransitionBroodingForaging,
         "dSurvTransitionForagingBrooding" = dSurvTransitionForagingBrooding,
         "dSurvTransitionBroodingForaging" = dSurvTransitionBroodingForaging,
         "dDeathTime" = dDeathTime,
         "dMaleLambda" = dMaleLambda,
         "dLarvaeLambda" = dLarvaeLambda,
         
         "dMutRate" = dMutRate,
         "dMutBias" = dMutBias,
         "dMutEffect" = dMutEffect,
         
         "dSurvForage" = dSurvForage,
         "dSurvBrood" = dSurvBrood,
         "dForagingMean" = dForagingMean,
         "dForagingSD" = dForagingSD,
         "const_sex_ratio" = const_sex_ratio,
         "params_to_record" = params_to_record)
  
  ini::write.ini(newini, config_file_name)
}

create_config(config_file_name = "config.ini")
