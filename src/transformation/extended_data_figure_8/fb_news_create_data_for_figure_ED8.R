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
source("src/transformation/compute_CI.R")
source("src/transformation/unify_dataset_columns.R")
source("src/transformation/participation_and_regression_functions.R")

# Variables ####
n_bin <- 21
output_folder <- "data/Results/extended_data_figure_8"
output_filename <- file.path(output_folder,
                             "fb_news_data_for_plot_short_conversation.parquet")

# Connect to database ####
database <- connect_to_database()

# Get data ####
query <-
  "WITH RankedComments AS (
  SELECT
    LC.comment_id,
    LC.post_id,
    LC.created_at,
    LC.toxicity_score,
    RANK() OVER (PARTITION BY LC.post_id ORDER BY LC.created_at) AS rnk_asc,
    RANK() OVER (PARTITION BY LC.post_id ORDER BY LC.created_at DESC) AS rnk_desc
  FROM labeled_comments LC
  INNER JOIN (
    SELECT post_id
    FROM labeled_comments
    GROUP BY post_id
    HAVING COUNT(*) >= 6 OR COUNT(*) <= 20
  ) AS P ON LC.post_id = P.post_id
)
SELECT *
FROM RankedComments
WHERE rnk_asc <= 3 OR rnk_desc <= 3
ORDER BY post_id, rnk_asc, rnk_desc;"

df_result <- dbGetQuery(database, query)

# Save result ####
message("Writing ", output_filename)
write_parquet(df_result,
              output_filename)

# Disconnect ####
dbDisconnect(database)