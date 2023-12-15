rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(lubridate)
source("src/utils/unify_dataset_columns.R")

all_data = setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with

for (social_media_name in social_to_work_with) {
  # Read the whole dataset
  
  if (social_media_name == "facebook") {
    df <-
      read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>%
      setDT()
    
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
  
  message("Read: ", social_media_name)
  
  # Unify column names
  
  df = unify_dataset_columns(df, social_media_name)
  
  # Compute lifetime of users
  if (social_media_name %in% c("telegram", "facebook", "gab")) {
    df$date = as.POSIXct(df$date, format = "%Y-%m-%dT%H:%M:%S")
    
  } else if (social_media_name == "usenet") {
    df$date = ymd_hms(df$date)
    
  } else if (social_media_name == "youtube") {
    df$date = as.POSIXct(df$date, format = "%Y-%m-%dT%H:%M:%SZ")
    
  }
  
  tmp = df[, .(lifetime = floor(difftime(max(date), min(date), units = "days"))),
           by = .(topic, root_submission)]
  
  tmp$lifetime <- as.numeric(tmp$lifetime)
  
  # Count each number
  
  tmp = tmp[, .(count = .N),
            by = .(topic, lifetime)]
  
  # Aggregate with other data
  
  tmp$social = ifelse(
    social_media_name == "facebook_news",
    "Facebook",
    str_to_title(social_media_name)
  )
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", social_media_name)
  
}

rm(social_media_name)

all_data$topic = str_to_title(all_data$topic)

if (identical(social_to_work_with,
              social_unique_names)) {
  # In this case save directly the file
  
  write_parquet(
    all_data,
    "data/Results/extended_data_figure_1/data_for_plot_thread_lifetime_distribution.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social_to_work_with)
  use = str_to_title(social_to_work_with)
  
  all_data_old = read_parquet(
    "data/Results/extended_data_figure_1/data_for_plot_thread_lifetime_distribution.parquet"
  ) %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(
    all_data,
    "data/Results/extended_data_figure_1/data_for_plot_thread_lifetime_distribution.parquet"
  )
  
}
