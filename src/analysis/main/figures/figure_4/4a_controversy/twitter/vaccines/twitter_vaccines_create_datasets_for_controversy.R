library(dplyr)
library(tibble)
library(arrow)
library(stringr)
library(jsonlite)
library(urltools)


"
twitter:
1. Extract users who posted at least 3 elements with a leaning
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
# Functions ####
get_mapping <- function(x, dictionary)
{
  return(dictionary[x])
}
# Variables ####
data_folder <-
  "data/Labeled/Twitter/"

vaccines_outlet_filename <-
  file.path("data",
            "MBFC_NG_unified_and_preprocessed.parquet")


vaccines_comments_with_twitter_handle <-
  file.path(
    "data/Labeled/Twitter/",
    "twitter_vaccines_comments_with_twitter_handles.parquet"
  )

output_folder <-
  "data/Results/figure_4/Twitter"

twitter_labeled_data_filename <-
  file.path("data/Labeled/Twitter/",
            "twitter_vaccines_labeled.parquet")

twitter_labeled_data_with_expanded_urls_filename <- file.path("data/Labeled/Twitter",
                                                              "twitter_vaccines_labeled_with_urls_expanded.parquet") 

# Load data ####

# Load news outlet leaning #
df_outlet_leaning <- read_parquet(vaccines_outlet_filename)

# Load overall comments #
message("Reading ", twitter_labeled_data_filename)
df_comments <- read_parquet(twitter_labeled_data_filename)

df_comments <- df_comments %>%
  rename(user_id = author_id,
         comment_id = id,
         post_id = conversation_id) %>% 
  distinct(comment_id, .keep_all = T)
  

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
  
# Extract domain from comments
df_comments_with_link <- df_comments %>%
  filter(is.na(expanded_url) == F) %>%
  mutate(expanded_url_modified = str_replace(str_to_lower(expanded_url), "https://", "")) %>%
  mutate(expanded_url_modified = str_replace(expanded_url_modified, "http://", "")) %>%
  mutate(expanded_url_modified = gsub("^www\\.", "", expanded_url_modified)) %>%
  mutate(expanded_url_modified = sub("\\/.*$", "", expanded_url_modified)) %>%
  distinct(comment_id, .keep_all = T)

# # Assign a leaning to posts from categorized vaccines outlet ####
df_outlet_leaning_with_unique_domains <- df_outlet_leaning %>%
  distinct(url, .keep_all = T)

df_comments_leaning_for_domains <- df_comments_with_link %>%
  inner_join(df_outlet_leaning_with_unique_domains,
             by = c("expanded_url_modified" = "url")) %>%
  select(-Twitter) %>%
  distinct(comment_id, .keep_all = T)

gc()

message("Computing user leaning")

# Create the df_comments of users which posted a content from a categorized vaccines outlet at least 3 times ####
df_users <- df_comments_leaning_for_domains %>%
  filter(is.na(leaning) == F) %>%
  group_by(user_id) %>%
  summarise(n_elements = n(),
            user_leaning = mean(leaning, na.rm = T)) %>%
  filter(n_elements >= 3)

output_filename <- file.path(output_folder,
                             "twitter_vaccines_users_for_controversy.parquet")
write_parquet(df_users,
              output_filename)

# Extend elements with information about the commentators leaning
df_comments_leaning_with_vaccines_outlet <-
  df_comments %>%
  left_join(df_users, by = "user_id") %>%
  select(-n_elements)

message("Extracting posts eligible for controversy")
df_posts_eligible_for_controversy <-
  df_comments %>%
  group_by(post_id) %>%
  summarise(n_elements = n()) %>%
  filter(n_elements >= 20) %>%
  select(post_id)

# Here we label the comments with sentiment analysis, obtaining a file called twitter_news_controversy_comments_labeled.parquet
df_controversy_comments_labeled_filename <- file.path(output_folder, 
                                                      "twitter_vaccines_controversy_comments_labeled.parquet")
df_controversy_comments_labeled <- read_parquet(df_controversy_comments_labeled_filename) 

df_comments_leaning_with_vaccines_outlet <- df_comments_leaning_with_vaccines_outlet %>% 
  left_join(df_controversy_comments_labeled, by = "comment_id")

# Compute controversy information
df_post_controversy_stats <-
  df_comments_leaning_with_vaccines_outlet %>%
  inner_join(df_posts_eligible_for_controversy, by = "post_id") %>%
  group_by(post_id) %>%
  summarise(
    number_of_comments = n_distinct(comment_id),
    number_of_toxic_comments = sum(is_toxic, na.rm = T),
    number_of_total_users = n_distinct(user_id),
    sd_sentiment_score = sd(sentiment_score, na.rm = T),
    sd_leaning = sd(user_leaning, na.rm = T),
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
                             "twitter_vaccines_controversy_stats.parquet")
message("Saving result at ", output_filename)
write_parquet(df_post_controversy_stats,
              output_filename)
message("Done")

# Saving info Info for ED3 ####
ed_3_info <- df_comments_leaning_with_vaccines_outlet %>%
  inner_join(df_post_controversy_stats, by = "post_id") %>%
  mutate(threads = n_distinct(post_id),
         users = n_distinct(user_id[is.na(user_leaning) == F])) %>% 
  distinct(threads,
           users)

average_percentage_of_labeled_users <- mean(df_post_controversy_stats$number_commenting_authors_with_leaning /
                                              df_post_controversy_stats$number_of_total_users)

ed_3_info$average_percentage_of_labeled_users <- average_percentage_of_labeled_users
output_filename <- file.path(output_folder,
                             "twitter_vaccines_ed3_info_without_correlations.parquet")

write_parquet(ed_3_info,
              output_filename)
