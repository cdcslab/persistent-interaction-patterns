rm(list = ls())
gc()

library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(data.table)
library(DBI)
library(RPostgreSQL)

source("src/utils/database_utils.R")
source("src/utils/binning_functions.R")
source("src/utils/compute_CI.R")
source("src/utils/unify_dataset_columns.R")
source("src/utils/participation_and_regression_functions.R")


# Variables ####
output_folder <- "data/Results/extended_data_figure_7"
output_filename <- file.path(output_folder,
                             "facebook_news_data_for_plot_correlations_05.parquet")
social <- "facebook"
n_bin = 21

database <- connect_to_database()

# Get data ####
query <-
  "SELECT
  post_id AS root_submission,
  SUM(CASE WHEN toxicity_score > 0.5 THEN 1.0 ELSE 0 END) / COUNT(*) AS toxicity_percentage,
  COUNT(*) AS thread_length
FROM labeled_comments
GROUP BY post_id;"

message("Performing query")
df <- dbGetQuery(database, query)
message("Done")

# Process result ####
df$topic <- "News"
df$social <- "Facebook"

df <- df %>% setDT()

message("Processing data")
# Rearrange columns and order rows ####
df <-
  df[, .(root_submission, thread_length, toxicity_percentage, topic)]
df <- df[order(thread_length, topic)]

# Log binning ####
df[, discretized_bin_label := sapply(.SD, log_bin, n_bin = n_bin),
   by = .(topic), .SDcols = "thread_length"]

# Resize last bin ####
resize_df <- setDT(NULL)
message("Resize last bin")
resize_df <- resize_last_bin(df,
                             n_bin = n_bin,
                             bin_threshold = 100)


# Compute CI
message("Compute CI")
data_for_plot <- resize_df[, .(mean_t = mean(toxicity_percentage),
                               CI_toxicity = lapply(.SD, compute_CI)),
                           by = .(topic, resize_discretized_bin_label),
                           .SDcols = "toxicity_percentage"]

tmp <- unlist(data_for_plot$CI_toxicity)

data_for_plot <- data_for_plot %>%
  mutate(CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
         CI_sup = tmp[seq(2, length(tmp), by = 2)],
         CI_toxicity = NULL)

data_for_plot$social <- "Facebook"
data_for_plot$topic <- "News"

# Save result ####
message("Save result")
write_parquet(data_for_plot,
              output_filename)

# Disconnect ####
dbDisconnect(database)
