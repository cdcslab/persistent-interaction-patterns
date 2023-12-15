

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(trend)
library(xtable)
source("src/utils/binning_functions.R")
source("src/utils/apply_mk_and_regression.R")
source("src/utils/unify_dataset_columns.R")

all_data = setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with

N = 200 # Number of samplings

for (social_media_name in social_to_work_with) {
  # Read the whole dataset
  
  if (social_media_name == "facebook") {
    df <-
      read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>%
      setDT()
    
  } else if (social_media_name == "facebook_news") {
    df <- fread("facebook_snews.csv") %>% setDT()
    
  } else {
    df <-
      read_parquet(
        paste0(
          "data/Labeled/",
          str_to_title(social_media_name),
          "/",
          social_media_name,
          "_labeled_data_unified.parquet"
        )
      ) %>%
      setDT()
    
  }
  
  df[is.na(toxicity_score), "toxicity_score"] = 0
  
  message("Read: ", social_media_name)
  
  # Unify column names
  
  df = unify_dataset_columns(df, social_media_name)
  
  if (social_media_name == "gab") {
    df$topic = "feed"
    
  }
  
  ##########################################
  # Compute the log-binning (once for all) #
  ##########################################
  
  # Thread length
  
  df[, thread_length := .N, by = .(root_submission, topic)]
  
  # Bin thread length
  
  df[, discretized_bin_label := sapply(.SD, log_bin, 21),
     by = .(topic), .SDcols = "thread_length"]
  
  # Modify the binning -> the last bin must have 50 elements
  
  resize_df = setDT(NULL)
  
  for (j in unique(df$topic)) {
    aux = resize_last_bin(df[topic == j], n_bin = 21)
    resize_df = rbind(resize_df, aux)
    
  }
  
  # Compute original trend
  
  resize_df$is_toxic = ifelse(resize_df$toxicity_score > 0.6, 1, 0)
  
  tmp = resize_df[, .(toxicity_percentage = sum(is_toxic) / .N),
                  by = .(topic, root_submission, resize_discretized_bin_label)]
  
  real_trend = tmp[, .(mean_t = mean(toxicity_percentage)),
                   by = .(topic, resize_discretized_bin_label)]
  
  ##############################
  # Apply MK-test & regression #
  ##############################
  
  results_real = apply_mk_and_regression(real_trend)
  
  #######################
  # Apply randomization #
  #######################
  
  count = 1
  result_rand = setDT(NULL)
  
  while (count <= N) {
    resize_df$is_toxic = sample(resize_df$is_toxic)
    
    tmp = resize_df[, .(toxicity_percentage = sum(is_toxic) / .N),
                    by = .(topic, root_submission, resize_discretized_bin_label)]
    
    random_trend = tmp[, .(mean_t = mean(toxicity_percentage)),
                       by = .(topic, resize_discretized_bin_label)]
    
    tmp = apply_mk_and_regression(random_trend)
    
    result_rand = rbind(result_rand, tmp)
    
    message("Done: ", count)
    count = count + 1
    
  }
  
  data_for_table = result_rand[, .(
    mean_slopes = mean(slope_regression),
    sd_slopes = sd(slope_regression),
    perc_increasing = sum(trend == "increasing") /
      .N,
    perc_ambigous = sum(trend == "ambigous") /
      .N
  ),
  by = .(topic)]
  
  data_for_table = merge(results_real, data_for_table)
  data_for_table = data_for_table[, .(
    topic,
    trend,
    p_mk,
    slope_regression,
    p_regression,
    mean_slopes,
    sd_slopes,
    perc_increasing,
    perc_ambigous
  )]
  
  rm(result_rand,
     results_real,
     random_trend,
     resize_df,
     tmp,
     aux,
     real_trend)
  
  # Trend with 16 and 26 bins
  
  ######################
  # Compute 16 binning #
  ######################
  
  # Bin thread length
  
  df[, discretized_bin_label := sapply(.SD, log_bin, 16),
     by = .(topic), .SDcols = "thread_length"]
  
  # Modify the binning -> the last bin must have 50 elements
  
  resize_df = setDT(NULL)
  
  for (j in unique(df$topic)) {
    aux = resize_last_bin(df[topic == j], n_bin = 16)
    resize_df = rbind(resize_df, aux)
    
  }
  
  # Compute original trend
  
  resize_df$is_toxic = ifelse(resize_df$toxicity_score > 0.6, 1, 0)
  
  tmp = resize_df[, .(toxicity_percentage = sum(is_toxic) / .N),
                  by = .(topic, root_submission, resize_discretized_bin_label)]
  
  real_trend = tmp[, .(mean_t = mean(toxicity_percentage)),
                   by = .(topic, resize_discretized_bin_label)]
  
  results_16 = apply_mk_and_regression(real_trend) %>%
    rename("trend_16" = "trend")
  
  data_for_table = merge(data_for_table, select(results_16, c("topic", "trend_16")))
  
  ######################
  # Compute 26 binning #
  ######################
  
  # Bin thread length
  
  df[, discretized_bin_label := sapply(.SD, log_bin, 26),
     by = .(topic), .SDcols = "thread_length"]
  
  # Modify the binning -> the last bin must have 50 elements
  
  resize_df = setDT(NULL)
  
  for (j in unique(df$topic)) {
    aux = resize_last_bin(df[topic == j], n_bin = 26)
    resize_df = rbind(resize_df, aux)
    
  }
  
  # Compute original trend
  
  resize_df$is_toxic = ifelse(resize_df$toxicity_score > 0.6, 1, 0)
  
  tmp = resize_df[, .(toxicity_percentage = sum(is_toxic) / .N),
                  by = .(topic, root_submission, resize_discretized_bin_label)]
  
  real_trend = tmp[, .(mean_t = mean(toxicity_percentage)),
                   by = .(topic, resize_discretized_bin_label)]
  
  results_26 = apply_mk_and_regression(real_trend) %>%
    rename("trend_26" = "trend")
  
  data_for_table = merge(data_for_table, select(results_26, c("topic", "trend_26")))
  
  # Aggregate with other data
  
  data_for_table$social = ifelse(
    social_media_name == "facebook_news",
    "Facebook",
    str_to_title(social_media_name)
  )
  all_data = rbind(all_data, data_for_table)
  rm(tmp, df)
  gc()
  
  message("Done with ", social_media_name)
  
}

all_data$social_topic = paste(all_data$social, str_to_title(all_data$topic))

# Write results

if (identical(
  social_to_work_with,
  social_unique_names
)) {
  # In this case save directly the file
  
  message("Writing a new file!")
  write_parquet(all_data,
                "data/Results/extended_table_1/data_for_extended_data_table_1.parquet")
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social_to_work_with)
  
  use = str_to_title(social_to_work_with)
  all_data_old = read_parquet("data/Results/extended_table_1/data_for_extended_data_table_1.parquet") %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(all_data,
                "data/Results/extended_table_1/data_for_extended_data_table_1.parquet")
  
}
