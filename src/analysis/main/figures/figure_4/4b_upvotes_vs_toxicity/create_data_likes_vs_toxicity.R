rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
source("src/utils/unify_dataset_columns.R")

all_data = setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with
n_bin = 21

for (social in social_to_work_with) {
  # Read the whole dataset
  
  if (social == "facebook") {
    df <-
      read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>%
      setDT()
    
  } else {
    df <- read_parquet(
      paste0(
        "data/Labeled/",
        str_to_title(social),
        "/",
        social,
        "_labeled_data_unified.parquet"
      )
    ) %>%
      setDT()
    
  }
  
  message("Read: ", social)
  
  # Unify column names
  
  df <- unify_dataset_columns(df, social)
  
  if (social == "gab") {
    df$topic <- "feed"
    
  }
  
  df = df[!is.na(like_count),]
  
  # Set toxicity from NA to 0 and define toxic comments
  
  df[is.na(toxicity_score), "toxicity_score"] = 0
  
  # Apply linear binning to toxicity scores
  
  discretized_bin_labels <- seq(0, 1, length.out = n_bin)
  df$toxicity_lin_bin <- cut(
    df$toxicity_score,
    breaks = n_bin,
    labels = discretized_bin_labels,
    right = T,
    ordered_result = TRUE,
    include.lowest = T
  )
  
  # Compute engagement in each bin of toxicity
  
  tmp = df[, .(engagement = mean(like_count)),
           by = .(topic, toxicity_lin_bin)]
  tmp[, normalized_engagement := engagement / max(engagement),
      by = .(topic)]
  
  tmp$social = str_to_title(social)
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", social)
  
}

rm(discretized_bin_labels)
all_data$topic = str_to_title(all_data$topic)
all_data[social == "Youtube", "social"] = "YouTube"

if (identical(social, social_unique_names)) {
  # In this case save directly the file
  
  message("Writing results..")
  write_parquet(all_data,
                "data/Results/figure_4/engagement_vs_toxicity.parquet")
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social)
  use = str_to_title(social)
  all_data_old = read_parquet("data/Results/figure_4/engagement_vs_toxicity.parquet") %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(all_data,
                "data/Results/figure_4/engagement_vs_toxicity.parquet")
}

