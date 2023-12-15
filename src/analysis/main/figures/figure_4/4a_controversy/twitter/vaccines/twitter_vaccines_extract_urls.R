library(dplyr)
library(tibble)
library(arrow)
library(stringr)
library(jsonlite)
library(urltools)

rm(list = ls())
gc()

# Functions

setwd("/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/")

# Variables ####
data_folder <- "/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Labeled/Twitter/"

output_folder <-
  "/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Results/figure_4/Twitter"

twitter_labeled_data_filename <-
  file.path(data_folder, "twitter_vaccines_labeled_data_unified.parquet")

output_filename <-
  file.path(data_folder, "twitter_vaccines_labeled_with_urls_expanded.parquet")

# Read data ####
df_comments <- read_parquet(twitter_labeled_data_filename)
df_comments <- df_comments %>% 
  select(comment_id,
         entities)
gc()

# Transform data ####
df_comments_to_expand <- df_comments %>% 
  filter(str_detect(entities, "url") | str_detect(entities, "expanded_url")) %>% 
  filter(str_detect(entities, "bit.ly") == T |
           str_detect(entities, "tinyurl.com") == T | 
           str_detect(entities, "goo.gl") == T | 
           str_detect(entities, "t.co") == T) %>% 
  select(comment_id, entities)


# Write results ####
write_parquet(df_comments_to_expand,
              output_filename)
