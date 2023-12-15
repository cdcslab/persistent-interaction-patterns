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
# Functions


query <- "SELECT from_id, COUNT(from_id) AS n_likes, AVG(page_leaning) as average_leaning
  FROM user_likes
  GROUP BY(from_id) 
  HAVING COUNT(from_id) >=3;"

facebook_folder_path <- "data/"
output_folder_path <- file.path(facebook_folder_path, 
                                "Processed")
# Close all previous R SQL connections
lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {
  dbDisconnect(conn = x)
})

database <- connect_to_database()

df <- dbGetQuery(database, query)

output_filename <- file.path(output_folder_path,
                             "fb_news_user_with_at_least_three_likes.parquet")

write_parquet(df,
              output_filename)

# Add these users on a database table

query <- "CREATE TABLE IF NOT EXISTS users_with_atleast_three_likes_and_comments(user_id TEXT PRIMARY KEY, n_likes INT, average_leaning REAL);"
dbExecute(database,
          query)
dbWriteTable(
  database,
  "users_with_atleast_three_likes_and_comments",
  value = df %>% 
    select(user_id = from_id,
           n_likes,
           average_leaning) %>% 
    distinct(user_id, .keep_all = T),
  append = TRUE,
  row.names = FALSE
)
