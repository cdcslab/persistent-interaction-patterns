library(arrow)
library(dplyr)
library(stringi)
library(tools)
library(xtable)
library(stringr)
library(readr)

rm(list = ls())
gc()

# Variables ####
folder <- "data/Processed/BinFiltering"
list_files = list.files(folder, 
                        full.names = T)

output_folder <- "data/Results/extended_table_2"
output_csv_filename <- file.path(output_folder,
                             "ed_table2.csv")
output_tex_filename <- file.path(output_folder,
                                   "ed_table2.tex")
df_stats <- tibble()

# Create table ####
i <- 1

for(file in list_files[i : length(list_files)])
{
  message("Working with ", file, "\n")
  
  df <- read_parquet(file)
  
  if("root_submission" %in% colnames(df)){
    df <- df %>% 
      rename(post_id = root_submission)
  } else if("thread_id" %in% colnames(df)){
    df <- df %>% 
      rename(post_id = thread_id)
  } 
  if(str_detect(file, "facebook_news") == T){
    df$topic <-  "News"
    df$social <- "Facebook"
  }
  if("subreddit_code" %in% colnames(df)){
    df$social <- "Reddit"
  }
   
  social_name <- unique(df$social)
  df <- df %>% 
    filter(resize_discretized_bin_label >= 0.7) %>% 
    group_by(topic) %>% 
    summarise(threads = n_distinct(post_id),
              min_size = min(thread_length),
              max_size = max(thread_length)) %>% 
    mutate(dataset_name = paste(toTitleCase(social_name), toTitleCase(topic), sep = " - ")) %>% 
    select(dataset_name,
           threads,
           min_size,
           max_size)
  
  df_stats <- rbind(df, 
                    df_stats)
  
  i <- i + 1
}

# Write results ####
df_stats <- df_stats %>% 
  arrange(dataset_name)
message("Writing resulting CSV at: ", output_csv_filename)
write.csv(df_stats,
          output_csv_filename)

message("Writing resulting TeX at: ", output_tex_filename)
print(xtable(df_stats),
      file = output_tex_filename)

print(xtable(df_stats))
