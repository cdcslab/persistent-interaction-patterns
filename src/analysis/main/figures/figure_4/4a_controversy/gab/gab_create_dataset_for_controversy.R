library(dplyr)
library(tibble)
library(arrow)
library(stringr)
library(jsonlite)
library(urltools)

"
Gab:
1. Extract user_ids who posted at least 3 elements with a leaning
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

# Variables ####

data_folder <- "data/Labeled/Gab/"

news_outlet_filename <-
  file.path("data",
            "MBFC_NG_unified_and_preprocessed.parquet")

gab_labeled_data_filename <-
  file.path(data_folder, "gab_labeled_data_unified.parquet")

gab_comments_with_link_filename <-
  file.path(data_folder, "gab_labeled_data_unified_with_link.parquet")

gab_expanded_links_filename <-
  file.path(data_folder, "gab_links_expanded.csv")

output_folder <-
  "data/Results/figure_4/Gab"


df_controversy_comments_labeled_filename <-
  file.path(
    output_folder,
    "controversy_comments_sentiment_labeled",
    "gab_controversy_comments_labeled.parquet"
  )


# Load Gab comments ####
df_outlet_leaning <- read_parquet(news_outlet_filename)


message("Loading ", gab_labeled_data_filename)
df_gab <- read_parquet(gab_labeled_data_filename)
message("Done")

# Prepare data ####
message("Preparing data")

df_gab <- df_gab %>%
  mutate(
    toxicity_score =   ifelse(is.na(df_gab$toxicity_score) ,
                              0,
                              df_gab$toxicity_score),
    is_toxic =   ifelse(df_gab$toxicity_score > 0.6,
                        T,
                        F),
    user = as.character(user)
  ) %>%
  rename(user_id = user)


message("Done")

# Load comments with link ####
message("Loading comments with link")
df_gab_with_link <-
  read_parquet(gab_comments_with_link_filename) %>%
  filter(is.na(attachment_source) == F)

df_gab_with_link$toxicity_score <-
  ifelse(is.na(df_gab_with_link$toxicity_score) ,
         0,
         df_gab_with_link$toxicity_score)

df_gab_with_link$is_toxic <-
  ifelse(df_gab_with_link$toxicity_score > 0.6,
         T,
         F)

message("Done")

message("Loading expanded URLs")
df_expanded_links <- readr::read_csv(
  gab_expanded_links_filename,
  col_names = c("comment_id",
                "expanded_url"),
  col_types = c("comment_id" = "character")
)
df_expanded_links <- df_expanded_links %>%
  distinct(comment_id, .keep_all = T)
message("Done")

message("Joining comment ids with shortened URLs")
df_gab_with_link <- df_gab_with_link %>%
  left_join(df_expanded_links, by = "comment_id")

df_gab_with_link$attachment_source <-
  ifelse(
    is.na(df_gab_with_link$expanded_url) == T,
    df_gab_with_link$attachment_source,
    df_gab_with_link$expanded_url
  )

# Extract domain.scheme ####
df_gab_with_link_cleaned <-
  df_gab_with_link %>%
  filter(comment_id != post_id) %>%
  mutate(attachment_source_modified = str_replace(str_to_lower(attachment_source), "https://", "")) %>%
  mutate(attachment_source_modified = str_replace(attachment_source_modified, "http://", "")) %>%
  mutate(attachment_source_modified = gsub("^www\\.", "", attachment_source_modified)) %>%
  mutate(attachment_source_modified = gsub("\\/.*$", "", attachment_source_modified)) %>% #Everything after /
  mutate(attachment_source_modified = gsub("\\:.*$", "", attachment_source_modified)) %>% #Everything after :
  mutate(attachment_source_modified = gsub("\\?.*$", "", attachment_source_modified)) %>% #Everything after ?
  mutate(attachment_source_modified = gsub("https\\:", "", attachment_source_modified)) %>%
  mutate(attachment_source_modified = gsub("https\\:", "", attachment_source_modified)) %>%
  distinct(comment_id, .keep_all = T) %>%
  select(
    comment_id,
    post_id,
    user_id,
    attachment_source,
    attachment_source_modified,
    toxicity_score,
    is_toxic
  )

df_outlet_leaning_with_unique_domains <- df_outlet_leaning %>%
  distinct(url, .keep_all = T) %>%
  select(url, leaning)

df_gab_leaning_for_domains <- df_gab_with_link_cleaned %>%
  inner_join(df_outlet_leaning_with_unique_domains,
             by = c("attachment_source_modified" = "url")) %>%
  distinct(comment_id, .keep_all = T)


# Create the df_gab of user_ids which posted a content from a categorized news outlet at least 3 times ####
df_user_ids <- df_gab_leaning_for_domains %>%
  filter(is.na(leaning) == F) %>%
  group_by(user_id) %>%
  summarise(n_elements = n(),
            user_leaning = mean(leaning, na.rm = T)) %>%
  filter(n_elements >= 3)

output_filename <- file.path(output_folder,
                             "gab_user_ids_for_controversy.parquet")
write_parquet(df_user_ids,
              output_filename)

# Extend elements with information about the commentators leaning
df_gab <- df_gab %>%
  left_join(df_user_ids, by = "user_id")

df_posts_eligible_for_controversy <- df_gab %>%
  select(-n_elements) %>%
  group_by(post_id) %>%
  summarise(n_elements = n()) %>%
  filter(n_elements >= 20) %>%
  select(post_id)

# Compute controversy information
df_controversy_comments <- df_gab %>%
  inner_join(df_posts_eligible_for_controversy, by = "post_id")

output_filename <- file.path(output_folder,
                             "gab_controversy_comments.parquet")
write_parquet(df_controversy_comments,
              output_filename)

# Here we label the comments with sentiment analysis, obtaining a file called twitter_news_controversy_comments_labeled.parquet
df_controversy_comments_labeled <-
  read_parquet(df_controversy_comments_labeled_filename)

df_gab <- df_gab %>%
  left_join(df_controversy_comments_labeled, by = "comment_id")

df_post_controversy_stats <- df_gab %>%
  inner_join(df_posts_eligible_for_controversy, by = "post_id") %>%
  group_by(post_id) %>%
  summarise(
    number_of_comments = n_distinct(comment_id),
    number_of_toxic_comments = sum(is_toxic, na.rm = T),
    sd_leaning = sd(user_leaning, na.rm = T),
    number_of_total_users = n_distinct(user_id),
    sd_sentiment_score = sd(sentiment_score_normalized, na.rm = T),
    number_comments_from_user_ids_with_leaning = sum(is.na(user_leaning) == F),
    number_commenting_authors_with_leaning = n_distinct(user_id[is.na(user_leaning) == F])
  ) %>%
  mutate(
    percentage_of_toxic_comments =
      number_of_toxic_comments / number_of_comments,
    percentage_of_comments_from_user_ids_with_leaning =
      number_comments_from_user_ids_with_leaning / number_of_comments
  ) %>%
  filter(
    number_comments_from_user_ids_with_leaning >= 20 &
      number_commenting_authors_with_leaning >= 10 &
      percentage_of_comments_from_user_ids_with_leaning >= 0.10
  )

output_filename <- file.path(output_folder,
                             "gab_controversy_stats.parquet")

write_parquet(df_post_controversy_stats,
              output_filename)

# Saving info Info for ED3 ####
ed_3_info <- df_gab %>%
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

ed_3_info$average_percentage_of_labeled_users <-
  average_percentage_of_labeled_users
output_filename <- file.path(output_folder,
                             "gab_ed3_info_without_correlations.parquet")

write_parquet(ed_3_info,
              output_filename)
