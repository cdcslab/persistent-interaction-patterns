library(httr)
library(stringr)
library(data.table)
library(dplyr)
library(arrow)
library(stringr)

rm(list = ls())
gc()

expand_url <- function(shortened_url) {
  Sys.sleep(0.1)
  tryCatch(
    {
      response <- GET(shortened_url)
      if (http_type(response) == "redirect") {
        return(url_absolute(response$url))
      } else {
        return(shortened_url)
      }
    },
    error = function(e) {
      # Handle the error as needed
      cat("Error expanding URL:", shortened_url, "\n")
      # You can return a default value or NA if an error occurs
      return(NA)
    }
  )
}


# Variables ####
data_folder <- "/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Labeled/Twitter/"

twitter_vaccines_labeled_with_urls_expanded_filename <-
  file.path(data_folder, "twitter_vaccines_labeled_with_urls_expanded.parquet")

df <- read_parquet(twitter_vaccines_labeled_with_urls_expanded_filename)

df <- df %>% 
  filter(is.na(expanded_url) == F)

df_to_expand <- df %>% 
  filter(str_detect(expanded_url,
                    "https://bit.ly/"))

df_to_expand$expanded_url <- sapply(df_to_expand$expanded_url, expand_url)

df <- df %>% 
  left_join(df_to_expand, by = "comment_id")

twitter_vaccines_labeled_with_urls_expanded_filename <-
  file.path(data_folder, "twitter_vaccines_labeled_with_urls_expanded.parquet")

message("Writing",
        twitter_vaccines_labeled_with_urls_expanded_filename)

write_parquet(df,
              twitter_vaccines_labeled_with_urls_expanded_filename)

message("Done")

