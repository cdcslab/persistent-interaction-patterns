rm(list = ls())
gc()

library(data.table)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
source("src/utils/unify_dataset_columns.R")

write.csv(df, "data/Labeled/Facebook/News/facebook_snews.csv")
# social = c("gab","reddit","voat","telegram","twitter","usenet","youtube","facebook","facebook_news")
social = c("facebook_news")

for (i in social) {
  # Read the whole dataset
  
  if (i == "facebook") {
    df <-
      read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>%
      setDT()
    
  } else if (i == "facebook_news") {
    df <- fread("data/Labeled/Facebook/News/facebook_snews.csv") %>%
      setDT() %>%
      mutate(topic = "News", social = "Facebook")
    
  } else {
    df <- read_parquet(
      paste0(
        "data/Labeled/",
        str_to_title(i),
        "/",
        i,
        "_labeled_data_unified.parquet"
      )
    ) %>% setDT()
    
  }
  
  message("Read: ", i)
  
  # Unify column names
  
  df = unify_dataset_columns(df, i)
  print(nrow(df[is.na(date)]))
  df = df[!is.na(date)]
  
  if (i == "gab") {
    df$topic = "feed"
    
  }
  
  # Compute number of comments of each thread
  
  tmp = df[, .(thread_length = .N),
           by = .(topic, root_submission)]
  
  keep_thread = tmp[(thread_length >= 6 & thread_length <= 20), ]
  
  keep_df = merge(df, keep_thread)
  
  # Save the dataset
  
  write_parquet(keep_df,
                paste0("data/data_short_threads/", i, "_short_threads.parquet"))
  
  rm(tmp, df, keep_df)
  gc()
  
  message("Done with ", i)
  
}
