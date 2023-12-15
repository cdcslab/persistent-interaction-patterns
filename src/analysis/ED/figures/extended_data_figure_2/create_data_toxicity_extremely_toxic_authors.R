rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
source("src/utils/empirical_cumulative_distribution.R")
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
  
  if (social_media_name == "gab") {
    df$topic = "feed"
    
  }
  
  # Set toxicity from NA to 0 and define toxic comments
  
  df[is.na(toxicity_score), "toxicity_score"] = 0
  df$is_toxic = ifelse(df$toxicity_score > 0.6, 1, 0)
  
  # Count the number of comments of each user in each topic
  
  user_comments = df[, .(n_comments = .N),
                     by = .(topic, user)]
  
  # Select only user having at least 10 comments
  # for each topic separately
  
  user_comments = user_comments[n_comments > 10, ]
  df = merge(df, user_comments)
  
  # Compute the fraction of toxic comments of each user in
  # each topic and ecdf
  
  tmp = df[, .(toxicity_percentage = sum(is_toxic) / .N),
           by = .(topic, user)] %>% select(-c("user"))
  tmp = tmp[order(topic, toxicity_percentage)]
  tmp[, ccdf := empirical_cumulative_distribution_all(toxicity_percentage),
      by = topic]
  
  tmp$social = ifelse(
    social_media_name == "facebook_news",
    "Facebook",
    str_to_title(social_media_name)
  )
  all_data = rbind(all_data, tmp)
  rm(tmp, df, user_comments)
  gc()
  
  message("Done with ", social_media_name)
  
}

rm(social_media_name)

all_data$topic = str_to_title(all_data$topic)

if (identical(social_to_work_with,
              social_unique_names)) {
  # In this case save directly the file
  message("Writing a new file!")
  write_parquet(
    all_data,
    "data/Results/extended_data_figure_2/data_for_plot_toxicity_extremely_toxic_authors.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social_to_work_with)
  use = str_to_title(social_to_work_with)
  
  all_data_old = read_parquet(
    "data/Results/extended_data_figure_2/data_for_plot_toxicity_extremely_toxic_authors.parquet"
  ) %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  # Update it
  
  all_data_new = rbind(all_data_old, all_data)
  print(unique(all_data_new$social))
  write_parquet(
    all_data_new,
    "data/Results/extended_data_figure_2/data_for_plot_toxicity_extremely_toxic_authors.parquet"
  )
  
}
