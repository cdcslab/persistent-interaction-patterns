library(dplyr)
library(tibble)
library(arrow)
library(stringr)
library(jsonlite)
library(urltools)


"
twitter:
1. Extract users who posted at least 15 elements with a leaning
2. Prendiamo questi post e calcoliamo la deviazione standard del leaning degli utenti che hanno commentato,
il numero di commenti con e senza leaning e il numero di commenti totale
3. Calcoliamo la percentuale di commenti con leaning
4. Filtriamo tenendo i post con un tot di commenti con leaning, con un tot di utenti con leaning e con una certa percentuale di leaning
5. Di questi post calcolo la percentuale di commenti tossici
6. Binniamo (linearmente) sul numero di commenti
7. Per ogni bin calcolo la correlazione tra deviazione del leaning e percentuale di commenti tossici
"
rm(list = ls())
gc()

# Functions

setwd("")
# Functions ####
get_mapping <- function(x, dictionary)
{
  return(dictionary[x])
}
# Variables ####
data_folder <- "data/Labeled/Twitter/news/"

news_outlet_filename <- file.path("data",
                                  "MBFC_NG_unified_and_preprocessed.parquet")

output_folder <-
  "data/Results/figure_4/Twitter"

twitter_labeled_data_filename <-
  file.path(data_folder, "twitter_news_labeled_data_unified.parquet")

twitter_news_post_folder <-
  "data/Labeled/Twitter/news/posts"

twitter_comment_id_with_page_filename <-
  file.path(data_folder,
            "twitter_news_comment_ids_with_page_name.parquet")

# Load data ####

# Load overall comments ####
message("Reading ", twitter_labeled_data_filename)
df_comments <- read_parquet(twitter_labeled_data_filename)

df_comments <- df_comments %>%
  distinct(comment_id, .keep_all = T) %>%
  rename(user_id = author_id)

# Sanitize data
df_comments$post_id <- as.character(as.numeric(df_comments$post_id))

df_comments$user_id <-
  as.character(as.numeric(df_comments$user_id))

df_comments$toxicity_score <-
  ifelse(is.na(df_comments$toxicity_score) ,
         0,
         df_comments$toxicity_score)

df_comments$is_toxic <-
  ifelse(df_comments$toxicity_score > 0.6,
         T,
         F)

# Load twitter news posts ####

message("Loading comments with news outlet")
df_comments_with_news_outlet <- tibble()

if (file.exists(twitter_comment_id_with_page_filename) == F)
{
  news_outlet_folders <- list.dirs(twitter_news_post_folder)[-1]
  
  df_posts <- tibble()
  for (folder in news_outlet_folders)
  {
    message("Reading ", folder)
    news_outlet_posts <- list.files(folder, full.names = T)
    
    df_comments_by_news_outlet <- tibble()
    for(file in news_outlet_posts)
    {
      news_outlet_name <- str_split(file, "data/Labeled/Twitter/news/posts/")[[1]][2]
      news_outlet_name <- str_split(news_outlet_name, "/")[[1]][1]
      

      df_comment <- readr::read_csv(
        file,
        col_types = c(
          "id" = "character",
          "author_id" = "character",
          "conversation_id" = "character"
        )
      )
      
      df_comment <- df_comment %>%
        distinct(id, .keep_all = T) %>%
        select(comment_id = id) %>% 
        mutate(news_outlet = news_outlet_name)
      
      df_comments_by_news_outlet <- rbind(df_comments_by_news_outlet,
                                            df_comment)
    }
    
    df_comments_with_news_outlet <- rbind(df_comments_with_news_outlet,
                                          df_comments_by_news_outlet)
    
    df_comments_with_news_outlet <- df_comments_with_news_outlet %>% 
      distinct(comment_id, .keep_all = T)
    
    message("Writing ", twitter_comment_id_with_page_filename)
    write_parquet(df_comments_with_news_outlet,
                  twitter_comment_id_with_page_filename)
  }
  

} else {
  message("File already exists")
  df_comments_with_news_outlet <- read_parquet(twitter_comment_id_with_page_filename)
}

message("Done")

# Expanding comments news outlet info ####
df_comments_with_news_outlet <- df_comments %>% 
   inner_join(df_comments_with_news_outlet, by = "comment_id")

# Assign a leaning to posts from categorized news outlet ####
# Read news outlet data
df_news_outlet_leaning <- read_parquet(news_outlet_filename) 

df_news_outlet_leaning <- df_news_outlet_leaning %>% 
  mutate(domain = sub("\\..*$", "", str_to_lower(url)))

df_comments_leaning_for_domains <- df_comments_with_news_outlet %>% 
  inner_join(df_news_outlet_leaning, by = c("news_outlet" = "domain")) %>% 
  select(-Twitter)

df_comments_leaning_with_news_outlet <- df_comments_leaning_for_domains %>% 
  distinct(comment_id, .keep_all = T)

rm(df_comments_leaning_for_domains)

gc()

# # Create the df_comments of users which posted a content from a categorized news outlet at least 15 times ####
df_users <- df_comments_leaning_with_news_outlet %>%
  filter(is.na(leaning) == F) %>%
  group_by(user_id) %>%
  summarise(n_elements = n(),
            user_leaning = mean(leaning, na.rm = T)) %>%
  filter(n_elements >= 15)

output_filename <- file.path(output_folder,
                             "twitter_news_users_for_controversy.parquet")
write_parquet(df_users,
              output_filename)

# Extend elements with information about the commentators leaning
df_comments_leaning_with_news_outlet <- df_comments %>%
  left_join(df_users, by = "user_id") %>%
  select(-n_elements)

df_posts_eligible_for_controversy <- df_comments %>%
  group_by(post_id) %>%
  summarise(n_elements = n()) %>%
  filter(n_elements >= 20) %>%
  select(post_id)

# Here we label the comments with sentiment analysis, obtaining a file called twitter_news_controversy_comments_labeled.parquet
df_controversy_comments_labeled_filename <- file.path(output_folder, 
                                                      "twitter_news_controversy_comments_labeled.parquet")
df_controversy_comments_labeled <- read_parquet(df_controversy_comments_labeled_filename) 

df_comments_leaning_with_news_outlet <- df_comments_leaning_with_news_outlet %>% 
  left_join(df_controversy_comments_labeled, by = "comment_id")

# Compute controversy information
df_post_controversy_stats <- df_comments_leaning_with_news_outlet %>%
  inner_join(df_posts_eligible_for_controversy, by = "post_id") %>%
  group_by(post_id) %>%
  summarise(
    number_of_comments = n_distinct(comment_id),
    number_of_toxic_comments = sum(is_toxic, na.rm = T),
    sd_leaning = sd(user_leaning, na.rm = T),
    number_of_total_users = n_distinct(user_id),
    sd_sentiment_score = sd(sentiment_score, na.rm = T),
    number_comments_from_users_with_leaning = sum(is.na(user_leaning) == F),
    number_commenting_authors_with_leaning = n_distinct(user_id[is.na(user_leaning) == F])
  ) %>%
  mutate(
    percentage_of_toxic_comments =
      number_of_toxic_comments / number_of_comments,
    percentage_of_comments_from_users_with_leaning =
      number_comments_from_users_with_leaning / number_of_comments
  ) %>%
  filter(
    number_comments_from_users_with_leaning >= 20 &
      number_commenting_authors_with_leaning >= 10 &
      percentage_of_comments_from_users_with_leaning >= 0.10
  )

output_filename <- file.path(output_folder,
                             "twitter_news_controversy_stats.parquet")

write_parquet(df_post_controversy_stats,
              output_filename)

# Saving info Info for ED3 ####
ed_3_info <- df_comments_leaning_with_news_outlet %>%
  inner_join(df_post_controversy_stats, by = "post_id") %>%
  mutate(threads = n_distinct(post_id),
         users = n_distinct(user_id[is.na(user_leaning) == F])) %>% 
  distinct(threads,
           users)

average_percentage_of_labeled_users <-
  mean(
    df_post_controversy_stats$number_commenting_authors_with_leaning /
      df_post_controversy_stats$number_of_total_users
  )

output_filename <- file.path(output_folder,
                             "twitter_news_ed3_info_without_correlations.parquet")

write_parquet(ed_3_info,
              output_filename)
