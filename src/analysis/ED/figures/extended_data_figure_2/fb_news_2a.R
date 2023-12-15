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
source("./src/utils/database_utils.R")
source("./src/utils/empirical_cumulative_distribution.R")

# Connect to database ####
database <- connect_to_database()

# Variables ####

output_folder <-
  "data/Results/extended_data_figure_3/"
df_result <- tibble()

query_2a <- "
    SELECT
        LC.from_id,
        SUM(CASE WHEN LC.toxicity_score > 0.6 THEN 1.0 ELSE 0 END) / COUNT(*) as fraction_toxic_comments
    FROM
        labeled_comments LC
    INNER JOIN (
        SELECT from_id
        FROM labeled_comments
        GROUP BY from_id
        HAVING COUNT(*) > 10
    ) AS A ON LC.from_id = A.from_id
    GROUP BY LC.from_id;
"

message("Get data for 2a")
df_result_2a <-
  dbGetQuery(query_2a, conn = database)

df_result_2a <- empirical_cumulative_distribution(df_result_2a$fraction_toxic_comments)

output_filename <- file.path(output_folder,
                             "facebook_news_ccdf_extended_figure_2a.parquet")

message("Writing ", output_filename)
write_parquet(df_result_2a,
              output_filename)
