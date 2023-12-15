rm(list = ls())
gc()

# Install packages
package_names <-
  c("dplyr",
    "ggplot2",
    "lubridate",
    "arrow")

for (package in package_names)
{
  if (!requireNamespace(package, quietly = F)) {
    install.packages(package)
  }
}

library(ggplot2)
library(dplyr)
library(lubridate)
library(arrow)
library(RPostgreSQL)
source("./src/utils/database_utils.R")

# Functions ####

# Variables ####

output_folder <- "data/Results/extended_data_figure_1/"
output_filename <- file.path(output_folder,
                             "data_for_plot_thread_size_distribution_fb_news.parquet")

# Read Data ####
database_connection <- connect_to_database()
df_comments <- dbGetQuery(database_connection,
                          "SELECT
    post_id,
    COUNT(*) AS n_comments
    FROM labeled_comments
    GROUP BY post_id;")

df_comments$topic <- "News"

# Perform Aggregation ####
df_number_of_posts_by_number_of_comments <- df_comments %>% 
  group_by(n_comments, topic) %>% 
  summarise(n_posts = n_distinct(post_id)) %>% 
  mutate(social = "Facebook",
         topic = "News")

# Write Output ####
message("Write result")
write_parquet(df_number_of_posts_by_number_of_comments,
              output_filename)
message("Done")