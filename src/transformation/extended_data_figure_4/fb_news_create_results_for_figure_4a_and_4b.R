rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(logr)
library(stringr)
library(RPostgreSQL)
source("./src/utils/binning_functions.R")
source("src/utils/compute_CI.R")
source("./src/utils/database_utils.R")
source("./src/utils/empirical_cumulative_distribution.R")
source("./src/utils/resize_last_bin_lifetime.R")


# Connect to database ####
database <- connect_to_database()

# Variables ####

output_folder <-
  "data/Results/extended_data_figure_4"
df_result <- tibble()
n_bin <- 21

# Create data for figure 4a ####
query_4a <- "SELECT
  from_id,
  SUM(CASE WHEN toxicity_score > 0.6 THEN 1.0 ELSE 0 END)::FLOAT / COUNT(*) AS toxicity_percentage,
  FLOOR(DATE_PART('day', MAX(created_at) - MIN(created_at))) AS lifetime
FROM
  labeled_comments
GROUP BY
  from_id;"

df_result_4a <-
  dbGetQuery(query_4a, conn = database)

# Apply log-binning
df_result_4a <- df_result_4a %>% setDT()
df_result_4a <- df_result_4a[order(lifetime),]
df_result_4a$lifetime <- as.numeric(df_result_4a$lifetime) + 1

df_result_4a[, discretized_bin_label := sapply(.SD, log_bin, n_bin),  .SDcols = "lifetime"]

# Resize last bin (if necessary)
df_result_4a <-
  resize_last_bin_lifetime(df_result_4a, n_bin, bin_threshold = 100)

# Average over all the threads
# Obtain only [lin_bin,mean_participation,mean_toxicity]

df_result_4a <- df_result_4a[, .(
  mean_toxicity = mean(toxicity_percentage),
  CI_toxicity = lapply(.SD,
                       compute_CI)
),
by = .(resize_discretized_bin_label),
.SDcols = "toxicity_percentage"]

tmp = unlist(df_result_4a$CI_toxicity)

df_result_4a = df_result_4a %>%
  mutate(CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
         CI_sup = tmp[seq(2, length(tmp), by = 2)],
         CI_toxicity = NULL)

output_filename <- file.path(output_folder,
                             "facebook_news_data_for_figure_4a.parquet")

message("Writing ", output_filename)
write_parquet(df_result_4a,
              output_filename)


# Create data for figure 4b ####
query_4b <- "SELECT
  post_id,
  SUM(CASE WHEN toxicity_score > 0.6 THEN 1.0 ELSE 0 END)::FLOAT / COUNT(*) AS toxicity_percentage,
  FLOOR(DATE_PART('day', MAX(created_at) - MIN(created_at))) AS lifetime
FROM
  labeled_comments
GROUP BY
  post_id;"

df_result_4b <-
  dbGetQuery(query_4b, conn = database)

# Apply log-binning
df_result_4b <- df_result_4b %>% setDT()
df_result_4b = df_result_4b[order(lifetime),]
df_result_4b$lifetime = as.numeric(df_result_4b$lifetime) + 1

df_result_4b[, discretized_bin_label := sapply(.SD, log_bin, n_bin),  .SDcols = "lifetime"]

# Resize last bin (if necessary)
df_result_4b = resize_last_bin_lifetime(df_result_4b, n_bin, bin_threshold = 100)

# Average over all the threads
# Obtain only [lin_bin,mean_participation,mean_toxicity]

df_result_4b = df_result_4b[, .(
  mean_toxicity = mean(toxicity_percentage),
  CI_toxicity = lapply(.SD,
                       compute_CI)
),
by = .(resize_discretized_bin_label),
.SDcols = "toxicity_percentage"]

tmp = unlist(df_result_4b$CI_toxicity)

df_result_4b = df_result_4b %>%
  mutate(CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
         CI_sup = tmp[seq(2, length(tmp), by = 2)],
         CI_toxicity = NULL)

output_filename <- file.path(output_folder,
                             "facebook_news_data_for_figure_4b.parquet")

message("Writing ", output_filename)
write_parquet(df_result_4b,
              output_filename)
