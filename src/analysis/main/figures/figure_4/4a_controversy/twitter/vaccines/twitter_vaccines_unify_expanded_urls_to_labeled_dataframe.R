library(dplyr)
library(arrow)

urls_filename <- "/media/cdcs/DATA1/toxicity_in_online_conversation/dataset/urls.csv"
vaccines_filename <- "/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Labeled/Twitter/twitter_vaccines_labeled_data_unified.parquet"

df_urls <- readr::read_csv(urls_filename)
df_vaccines <- read_parquet(vaccines_filename)

df_urls$id <- as.character(df_urls$id)
df_urls$conversation_id <- as.character(df_urls$conversation_id)
df_urls$author_id <- as.character(df_urls$author_id)

df_vaccines <- df_vaccines %>% 
  left_join(df_urls, by = c("comment_id" = "id"))

df_vaccines <- df_vaccines %>% 
  select(-author_id.y) %>% 
  rename(author_id = author_id.x)

write_parquet(df_vaccines,
              vaccines_filename)
