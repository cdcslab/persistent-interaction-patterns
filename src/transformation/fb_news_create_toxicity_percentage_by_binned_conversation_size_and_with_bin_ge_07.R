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
output_folder <- "data/Results/figure_2"
output_filename <- file.path(output_folder,
                             "facebook_news_toxicity_percentage_binned.parquet")


social <- "facebook"
n_bin = 21

database <- connect_to_database()

# Get data ####
query <-
  "SELECT
  post_id AS root_submission,
  SUM(CASE WHEN toxicity_score > 0.6 THEN 1.0 ELSE 0 END) / COUNT(*) AS toxicity_percentage,
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
df[,
   discretized_bin_label := sapply(.SD, log_bin, n_bin = n_bin),
   by = .(topic),
   .SDcols = "thread_length"]

# Resize last bin ####
resize_df <- setDT(NULL)
message("Resize last bin")
resize_df <- resize_last_bin(df,
                             n_bin = n_bin,
                             bin_threshold = 100)

# Compute CI
df_binned <- resize_df[, .(mean_t = mean(toxicity_percentage),
                           CI_toxicity = lapply(.SD, compute_CI)),
                       by = .(topic, resize_discretized_bin_label),
                       .SDcols = "toxicity_percentage"]

df_binned$social <- "Facebook"

df_binned_after_threshold <-
  resize_df[resize_discretized_bin_label >= 0.7]

query <- "SELECT COUNT(1) FROM post_ids_in_bin_after_threshold"

count <- dbGetQuery(database, query)

post_ids_in_bin_after_threshold <- df_binned_after_threshold %>%
  select(post_id = root_submission,
         resize_discretized_bin_label) %>%
  distinct(post_id, .keep_all = T)

if (count$count == 0) {
  query <- "
CREATE TABLE IF NOT EXISTS post_ids_in_bin_after_threshold
(post_id TEXT PRIMARY KEY UNIQUE,
resize_discretized_bin_label REAL);
DELETE FROM post_ids_in_bin_after_threshold;"
  
  dbExecute(database,
            query)
  
  message("Writing to database")
  dbWriteTable(
    database,
    "post_ids_in_bin_after_threshold",
    value = post_ids_in_bin_after_threshold,
    append = T,
    row.names = F
  )
}

query <-
  "SELECT LC.post_id AS post_id,
  LC.comment_id AS comment_id,
  LC.from_id AS user_id,
  LC.created_at AS created_at,
  LC.toxicity_score AS toxicity_score,
  LC.likes_count AS likes_count,
  P.resize_discretized_bin_label AS resize_discretized_bin_label
FROM labeled_comments LC
INNER JOIN post_ids_in_bin_after_threshold P
ON P.post_id = LC.post_id"

df_data_with_bin_after_threshold <- dbGetQuery(database, query)

df_data_with_bin_after_threshold <-
  df_data_with_bin_after_threshold %>%
  inner_join(df_binned_after_threshold,
             by = c("post_id" = "root_submission"))

df_data_with_bin_after_threshold <-
  df_data_with_bin_after_threshold %>%
  select(-resize_discretized_bin_label.x) %>%
  rename(resize_discretized_bin_label = resize_discretized_bin_label.y)

# Save result ####
message("Save result")
write_parquet(df_binned,
              output_filename)

# Toxicity percentage binned
output_filename <- file.path(
  "data/Processed/BinFiltering/",
  paste("facebook_news_comments_with_bin_ge_07.parquet", sep = ".")
)
write_parquet(df_data_with_bin_after_threshold, output_filename)

message("Comments with discretized bin >= 0.7 can be found in",
        output_filename,
        "file")

# Disconnect ####
dbDisconnect(database)
