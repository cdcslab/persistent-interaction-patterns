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
                             "facebook_news_data_for_plot_user_lifetime_distribution.parquet")

# Read Data ####
database_connection <- connect_to_database()
df_lifetime <- dbGetQuery(
  database_connection,
  "SELECT
  from_id,
  FLOOR(DATE_PART('day', MAX(created_at) - MIN(created_at))) AS lifetime
  FROM
  labeled_comments
  GROUP BY
  from_id;"
  
)

# Perform Aggregation ####
df_lifetime <- df_lifetime %>% 
  filter(is.na(lifetime) == F)

df_number_of_comments_by_lifetime <- df_lifetime %>%
  group_by(lifetime) %>%
  summarise(count = n()) %>%
  mutate(social = "Facebook",
         topic = "News")

# Write Output ####
message("Write result")
write_parquet(df_number_of_comments_by_lifetime,
              output_filename)
message("Dones")