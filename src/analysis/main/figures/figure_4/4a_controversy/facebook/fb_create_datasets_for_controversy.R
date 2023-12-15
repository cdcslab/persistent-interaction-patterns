rm(list = ls())
gc()

# Install packages
package_names <-
  c("dplyr",
    "arrow",
    "datetime",
    "tibble",
    "logr",
    "readr",
    "RPostgreSQL")

for (package in package_names)
{
  if (!requireNamespace(package, quietly = F)) {
    install.packages(package)
  }
}

library(dplyr)
library(arrow)
library(datetime)
library(tibble)
library(logr)
library(readr)
library(RPostgreSQL)
source("./src/utils/database_utils.R")


# Variables ####

data_folder <- "data/"
output_folder <-
  "data/Results/figure_4/Facebook"

processed_folder <-
  "data/Processed/"

# Prepare dataset connections ####
# Close all previous R SQL connections
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {
  dbDisconnect(conn = x)
})

database <- connect_to_database()

comments_labeled_with_sentiment_filename <- file.path(
  output_folder,
  "facebook_news_controversy_comments_labeled_with_sentiment.parquet"
)
# Get data ####

#if no data:
# query <- "CREATE TABLE post_with_atleast_twenty_comments(post_id text PRIMARY KEY);"
#
# dbExecute(database, query)
#
# query <- "INSERT INTO post_with_atleast_twenty_comments(post_id)
# SELECT DISTINCT post_id
#    FROM labeled_comments
#    WHERE post_id IN
#      (SELECT post_id
#      FROM labeled_comments
#      GROUP BY(post_id)
#      HAVING COUNT(post_id) >=20) "
#
# dbExecute(database, query)

# df_controvery_comments_with_sentiment <- read_parquet(comments_labeled_with_sentiment_filename)
#
# query <- "CREATE TABLE IF NOT EXISTS controvery_comments_with_sentiment(
# comment_id text PRIMARY KEY,
# sentiment_score REAL);"
# dbExecute(database,
#           query)
# df_controvery_comments_with_sentiment <- df_controvery_comments_with_sentiment %>%
#   distinct(comment_id,
#            .keep_all = T) %>%
#   select(comment_id,
#          sentiment_score = sentiment_score_normalized)

# dbWriteTable(database,
#              "controvery_comments_with_sentiment",
#              df_controvery_comments_with_sentiment,
#              append = T,
#              row.names = F)

query <- "SELECT
  LC.post_id,
  COUNT(DISTINCT LC.comment_id) AS number_of_comments,
  SUM(CASE WHEN LC.toxicity_score > 0.6 THEN 1 ELSE 0 END) AS number_of_toxic_comments,
  STDDEV(U.average_leaning) AS sd_leaning,
  STDDEV(CS.sentiment_score) AS sd_sentiment_score,
  COUNT(DISTINCT LC.from_id) AS number_of_total_users,
  SUM(CASE WHEN U.average_leaning IS NOT NULL THEN 1 ELSE 0 END) AS number_comments_from_users_with_leaning,
  COUNT(DISTINCT CASE WHEN U.average_leaning IS NOT NULL THEN LC.from_id END) AS number_commenting_authors_with_leaning,
  SUM(CASE WHEN LC.toxicity_score > 0.6 THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT LC.comment_id) AS percentage_of_toxic_comments,
  SUM(CASE WHEN U.average_leaning IS NOT NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT LC.comment_id) AS percentage_of_comments_from_users_with_leaning
FROM labeled_comments LC
LEFT JOIN controvery_comments_with_sentiment AS CS
ON LC.comment_id = CS.comment_id
INNER JOIN post_with_atleast_twenty_comments AS P
ON LC.post_id = P.post_id
LEFT JOIN users_with_atleast_three_likes_and_comments U
ON LC.from_id = U.user_id
GROUP BY LC.post_id;"

df_comments_from_eligible_posts_with_commenters_leaning_info_if_existing <-
  dbGetQuery(database, query)

# Compute controversy information
df_post_controversy_stats <-
  df_comments_from_eligible_posts_with_commenters_leaning_info_if_existing %>%
  filter(
    number_comments_from_users_with_leaning >= 20 &
      number_commenting_authors_with_leaning >= 10 &
      percentage_of_comments_from_users_with_leaning >= 0.10
  )

output_filename <- file.path(output_folder,
                             "facebook_news_controversy_stats.parquet")

write_parquet(df_post_controversy_stats,
              output_filename)

query <- "DROP TABLE IF EXISTS controversy_posts;
CREATE TABLE IF NOT EXISTS controversy_posts(
post_id TEXT PRIMARY KEY);"

dbExecute(database,
          query)

dbWriteTable(database,
             "controversy_posts",
             df_post_controversy_stats %>% distinct(post_id),
             append = T,
             row.names = F)

# Saving info Info for ED3 ####
query <- "SELECT
  COUNT(DISTINCT LC.post_id) AS threads,
  COUNT(DISTINCT CASE WHEN U.average_leaning IS NOT NULL THEN LC.from_id END) AS users
  FROM labeled_comments LC
  INNER JOIN controversy_posts AS P
  ON LC.post_id = P.post_id
  LEFT JOIN users_with_atleast_three_likes_and_comments U
  ON LC.from_id = U.user_id;"

ed_3_info <- dbGetQuery(database, query)

average_percentage_of_labeled_users <-
  mean(
    df_post_controversy_stats$number_commenting_authors_with_leaning /
      df_post_controversy_stats$number_of_total_users
  )

ed_3_info$average_percentage_of_labeled_users <-
  average_percentage_of_labeled_users
output_filename <- file.path(output_folder,
                             "facebook_news_ed3_info_without_correlations.parquet")

write_parquet(ed_3_info,
              output_filename)
