library(dplyr)
library(tibble)
library(arrow)
library(stringr)
library(jsonlite)
library(urltools)
library(reticulate)
rm(list = ls())
gc()

"
- Per Facebook News ho la pagina page_info dove ho il matching pagina e il suo link, i quali li matcho tramite l'url di mbfc
- Su twitter news è più facile perché Ale 4C aveva scaricato le timeline e quindi, poiché ho un numero di news outlet limitato, 
il matching lo possiamo fare pure a mano
- Su Gab e Twitter Vaccines per inferire il leaning sono stati classificati i link. Si parla quindi di classificazione dei post e non più delle pagine
"
# Variables ####
data_folder <- "data/Labeled/Gab"

gab_labeled_data_filename <- file.path(data_folder,
                                       "gab_labeled_data_unified.parquet")

output_filename <- file.path(data_folder,
                             "gab_labeled_data_unified_with_link.parquet")

# Load data ####
df_gab <- read_parquet(gab_labeled_data_filename)

# Extract rows with link ####
df_gab_with_link <- df_gab %>% 
  filter(str_detect(attachment, "'type': 'url'")) %>% 
  distinct(comment_id, .keep_all = T)

message("Writing ", output_filename)
write_parquet(df_gab_with_link,
              output_filename)

rm(df_gab_with_link,
   df_gab)
gc()

# Qui chiamo il python /src/transformation/figure_4/gab_convert_attachment_json_to_object.py per ottenere le source

input_filename <- file.path(data_folder,
                            "gab_post_and_comments_labeled_with_converted_json.parquet")

df_gab_with_leaning <- read_parquet(input_filename)
df_gab_with_leaning <- df_gab_with_leaning %>% 
  mutate(post_id = as.character(post_id),
         user_id = as.character(as.numeric(user))) %>% 
  select(
  post_id,
  user_id,
  comment_id,
  created_at,
  toxicity_score,
  like_count,
  attachment,
  attachment_source,
  is_reply
)

output_filename <- file.path(data_folder,
                             "gab_labeled_data_unified_with_link.parquet")

message("Output: ", output_filename)

write_parquet(df_gab_with_leaning,
              output_filename)
