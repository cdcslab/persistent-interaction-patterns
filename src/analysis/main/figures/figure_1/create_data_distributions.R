rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)

source("src/utils/unify_dataset_columns.R")

all_data <- setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with
output_filename <- "data/Results/figure_1/data_for_plot_user_comments_distribution.parquet"

for (social_name in social_to_work_with) {
  message("Social: ", social_name)
  
  if (social_name == "facebook") {
    # Read the whole dataset
    df <-
      read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>%
      setDT()
    
  } else {
    df <- read_parquet(
      paste0(
        "data/Labeled/",
        str_to_title(social_name),
        "/",
        social_name,
        "_labeled_data_unified.parquet"
      )
    ) %>%
      setDT()
  }
  
  # Unify column names
  df = unify_dataset_columns(df, social_name)
  
  if (social_name == "gab") {
    df$topic = "feed"
  }
  
  # Compute number of comments of each user
  tmp = df[, .(n_comments = .N),
           by = .(topic, user)]
  
  # Count each number
  tmp = tmp[, .(count = .N), by = .(topic, n_comments)]
  
  # Aggregate with other data
  tmp$social = ifelse(social_name == "facebook_news", "Facebook", str_to_title(social_name))
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", social_name)
}

all_data$topic <- str_to_title(all_data$topic)
all_data$social <- factor(
  all_data$social,
  levels = c(
    "Voat"
  )
)

if (identical(social_to_work_with, social_unique_names)) {
  # In this case save directly the file
  message("Writing ", output_filename)
  write_parquet(
    all_data,
    output_filename
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social_to_work_with)
  
  use = str_to_title(social_to_work_with)
  all_data_old = read_parquet(output_filename) %>%
    filter(!(social_to_work_with %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(
    all_data,
    output_filename
  )
  
  message("Just updated: ", social_to_work_with)
}

