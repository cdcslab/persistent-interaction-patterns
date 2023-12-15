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
source("./src/utils/compute_CI.R")

# Connect to database ####
database <- connect_to_database()

# Variables ####
toxicity_values <- seq(0, 1, length.out = 22)
toxicity_left_bound <- 0
toxicity_right_bound <- 0

output_filename <-
  "data/Results/figure_4/Facebook/facebook_news_average_likes_by_toxicity_bin.parquet"
df_result <- tibble()

# Get average likes by toxicity bin ####
for (i in 1:(length(toxicity_values) - 1))
{
  toxicity_left_bound <- toxicity_values[i]
  toxicity_right_bound <- toxicity_values[i + 1]
  
  
  if (i < length(toxicity_values) - 1) {
    message("Working with bin [",
            toxicity_left_bound,
            ",",
            toxicity_right_bound,
            ")")
    select_like_comments_query <- paste(
      "
SELECT likes_count
FROM labeled_comments
WHERE toxicity_score >=",
      toxicity_left_bound,
      "AND toxicity_score <",
      toxicity_right_bound,
      ";"
    )
  } else {
    message("Working with bin [",
            toxicity_left_bound,
            ",",
            toxicity_right_bound,
            "]")
    select_like_comments_query <- paste(
      "
SELECT likes_count
FROM labeled_comments
WHERE toxicity_score >=",
      toxicity_left_bound,
      "AND toxicity_score <=",
      toxicity_right_bound,
      ";"
    )
  }
  
  message(select_like_comments_query)
  df_bin_result <-
    dbGetQuery(select_like_comments_query, conn = database)
  df_bin_result$bin <- 0.05 * (i - 1)
  
  df_result <- rbind(df_result, df_bin_result)
}

df_result <- df_result %>% setDT()
data_for_plot <- df_result[, .(mean_likes = mean(likes_count, na.rm = T),
                               CI_likes = lapply(.SD, compute_CI)),
                           by = .(bin),
                           .SDcols = "likes_count"]

tmp <- unlist(data_for_plot$CI_likes)

data_for_plot <- data_for_plot %>%
  mutate(CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
         CI_sup = tmp[seq(2, length(tmp), by = 2)],
         CI_likes = NULL)


message("Writing results at ", output_filename)
write_parquet(data_for_plot,
              output_filename)
