rm(list = ls())
gc()

library(tibble)
library(dplyr)
library(readr)
library(ndjson)
library(log4r)
library(arrow)
library(datetime)
library(stringr)
library(xtable)
source("./src/utils/database_utils.R")


# Functions ####
normalize_dataset_columns <- function(df_social){
  if("user" %in% colnames(df_social)) # Gab
  {
    df_social <- df_social %>% 
      rename(user_id = user)
  } 
  if("comment_code" %in% colnames(df_social)){ 
    df_social <- df_social %>% 
      rename(comment_id = id)
  }
  if("author_id" %in% colnames(df_social)){
    df_social <- df_social %>% 
      rename(user_id = author_id)
  }
  if("user_name" %in% colnames(df_social)){
    df_social <- df_social %>% 
      rename(user_id = user_name)
  }
  if("thread_id" %in% colnames(df_social)){
    df_social <- df_social %>% 
      rename(post_id = thread_id)
  }
  if("root_submission" %in% colnames(df_social)){
    df_social <- df_social %>% 
      rename(post_id = root_submission)
  }

  if("date" %in% colnames(df_social) & !"created_at" %in% colnames(df_social))
  {
    df_social <- df_social %>% 
      rename(created_at = date)
  }
  return(df_social)
}

# Variables ####

labeled_folder <-
  "data/Labeled"

output_folder <- "data/Results/table_1"
output_filename <- file.path(output_folder,
                             "table1.csv")

# Load data ####
socials <- list.dirs(labeled_folder,
                     recursive = F,
                     full.names = F)

df_stats <- tibble()
i <- 1
 
for (social in socials[i: length(socials)])
{
  folder <- file.path(labeled_folder, social)
  if (str_detect(tolower(folder), "facebook") == T)
  {
    filename <- file.path(folder,
                          "facebook_labeled_data_unified_except_news.parquet")
  } else{
    filename <- file.path(folder,
      paste(tolower(social), "labeled_data_unified.parquet", sep = "_"))
  }

  
  message("Working with ", filename)
  df_social <- read_parquet(filename)
  df_social$toxicity_score <-
    ifelse(is.na(df_social$toxicity_score),
           0,
           df_social$toxicity_score)
  df_social$is_toxic <- ifelse(df_social$toxicity_score > 0.6, T, F)
  
  df_social <- normalize_dataset_columns(df_social)
  
  df_social_stats <- df_social %>%
    group_by(topic) %>%
    summarize(
      n_comments = n_distinct(comment_id),
      n_thread = n_distinct(post_id),
      n_users = n_distinct(user_id),
      toxicity_percentage = sum(is_toxic) / n(),
      min_date = min(created_at),
      max_date = max(created_at)
    ) %>%
    mutate(social = social,
           topic = topic)
  
  df_stats <- rbind(df_stats,
                    df_social_stats)
  i <- i + 1
  
  message("Social: ", social, "\n",
          "Min Date:", df_social_stats$min_date, "\n",
          "Max Date:", df_social_stats$max_date, "\n")
  rm(df_social, df_social_stats)
  gc()
}

# Extract stats from facebook news
# 
# database <- connect_to_database()
# 
# query <- "SELECT
#     'Facebook' AS social,
#     'News' AS topic,
#     COUNT(DISTINCT comment_id) AS n_comments,
#     COUNT(DISTINCT post_id) AS n_thread,
#     COUNT(DISTINCT from_id) AS n_users,
#     SUM(CASE WHEN toxicity_score > 0.6 THEN 1.0 ELSE 0 END) / COUNT(*) AS toxicity_percentage,
#     MIN(created_at) AS min_date,
#     MAX(created_at) AS max_date
# FROM
#     labeled_comments
# GROUP BY topic;"
# 
# df_social_stats <- dbGetQuery(database, query)
# 
# df_stats <- rbind(df_stats,
#                   df_social_stats)

print(xtable(df_stats, digits=3), include.rownames = F)

message("Writing: ", output_filename)
write.csv(df_stats,
          output_filename)
