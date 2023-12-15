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

gc()
# Get average fraction of toxic comments by post_id ####

query_2b <- "
    SELECT
        LC.post_id,
        SUM(CASE WHEN LC.toxicity_score > 0.6 THEN 1.0 ELSE 0 END) / COUNT(*) as fraction_toxic_comments
    FROM
        labeled_comments LC
    INNER JOIN (
        SELECT post_id
        FROM labeled_comments
        GROUP BY post_id
        HAVING COUNT(*) > 10
    ) AS A ON LC.post_id = A.post_id
    GROUP BY LC.post_id;"

message("Get data for 2b")
df_result_2b <-
  dbGetQuery(query_2b, conn = database)

df_result_2b <- empirical_cumulative_distribution(df_result_2b$fraction_toxic_comments)

output_filename <- file.path(output_folder,
                             "facebook_news_ccdf_extended_figure_2b.parquet")
message("Writing ", output_filename)
write_parquet(df_result_2b,
              output_filename)