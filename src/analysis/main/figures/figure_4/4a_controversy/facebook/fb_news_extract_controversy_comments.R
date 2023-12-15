rm(list = ls())
gc()

# Install packages
package_names <-
  c("dplyr",
    "arrow",
    "datetime",
    "tibble",
    "logr",
    "readr",
    "RPostgreSQL")

for (package in package_names)
{
  if (!requireNamespace(package, quietly = F)) {
    install.packages(package)
  }
}

library(dplyr)
library(arrow)
library(datetime)
library(tibble)
library(logr)
library(readr)

# Variables ####
from <- "2009-09-09"
to <- "2016-08-18"
controversy_filename <- "data/Results/figure_4/Facebook/facebook_news_controversy_stats.parquet"
output_filename <- "data/Results/figure_4/Facebook/facebook_controversy_comments.parquet"

# Read data ####
df_controversy_stats <- read_parquet(controversy_filename)
df_controversy_stats <- df_controversy_stats %>% 
  select(post_id)

# Unify comments ####
message('Working with News topic')

folder_path <-
  "data/Labeled/Facebook/News"

table_name <- "labeled_comments"
stage_table_name <- paste("stage", table_name, sep = "_")

comments_folder <-
  file.path(folder_path, "CommentsCSV")
comment_files <- list.files(comments_folder,
                            full.names = T)

message("Working with Facebook news")

# Create table if not exists ####

# Insert comments into table
index <- 1
df_controversy_comments <- tibble()

for (comment_file in comment_files)
{
  message("Reading ", comment_file)
  df_tmp_comment <- read_csv(comment_file)
  
  df_tmp_comment <- df_tmp_comment %>%
    select(from_id,
           comment_id,
           post_id,
           toxicity_score,
           message) %>%
    rename(text = message) %>%
    mutate(
      across(c(comment_id, post_id), as.character),
      across(c(toxicity_score), as.numeric),
      toxicity_score = ifelse(is.na(toxicity_score), 0, toxicity_score)
    ) %>%
    filter(comment_id != post_id) %>%
    distinct(comment_id, .keep_all = T)
  
  df_controversy_comments_tmp <- df_controversy_stats %>% 
    inner_join(df_tmp_comment, by = "post_id")
  
if(dim(df_controversy_comments_tmp)[1] == 0)
  {
    next
  }
  
  df_controversy_comments <- rbind(df_controversy_comments,
                                   df_controversy_comments_tmp)
  
  df_controversy_comments <- df_controversy_comments %>% 
    distinct(comment_id, .keep_all = T)
  
  message("Total controversy comments found: ", dim(df_controversy_comments)[1], "\n")
  
  index = index + 1
}

df_controversy_comments <- df_controversy_comments %>% 
  distinct(comment_id, .keep_all = T)

message("Writing results at: ", output_filename)
write_parquet(df_controversy_comments, output_filename)
