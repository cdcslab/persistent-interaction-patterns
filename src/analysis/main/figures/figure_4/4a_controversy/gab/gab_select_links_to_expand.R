
library(dplyr)

path <- "/media/cdcs/DATA2/NEW_toxicity_in_online_conversations/data/Labeled/Gab/gab_post_and_comments_labeled_with_converted_json.parquet"

df <- read_parquet(path)
df_to_expand <- df %>% 
  filter(str_detect(attachment,
                    "'type': 'url'"))

df_to_expand <- df_to_expand %>% 
  filter(str_detect(attachment, "'source': 'bit.ly'") == T |
           str_detect(attachment, "'source': 'tinyurl.com'") == T | 
           str_detect(attachment, "'source': 'goo.gl'") == T | 
           str_detect(attachment, "'source': 't.co'") == T)


df_to_expand <- df_to_expand %>% 
  select(comment_id = id,
         attachment)

path <- "/media/cdcs/DATA2/NEW_toxicity_in_online_conversations/data/Labeled/Gab/gab_links_to_expand.parquet"

write_parquet(df_to_expand,
              path)
