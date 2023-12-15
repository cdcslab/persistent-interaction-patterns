library(arrow)
library(dplyr)

filename <- "data/Results/figure_4/Facebook/facebook_controversy_comments.parquet"
output_filename <- "data/Results/figure_4/Facebook/facebook_news_controversy_comments_to_label_for_sentiment_analysis.parquet"

df_comments <- read_parquet(filename)

set.seed(42)

n_conversations_to_consider <- 45830
post_ids <- df_comments %>% 
  distinct(post_id)

random_post_ids <- post_ids %>% 
  sample_n(n_conversations_to_consider)  

df_comments_associated_to_random_post_ids <- df_comments %>% 
  inner_join(random_post_ids, by = "post_id")

df_comments_associated_to_random_post_ids$from_id <- as.character(df_comments_associated_to_random_post_ids$from_id)

write_parquet(df_comments_associated_to_random_post_ids,
              output_filename)
