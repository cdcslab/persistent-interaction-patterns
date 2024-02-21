rm(list = ls())
gc()


library(tibble)
library(dplyr)
library(readr)
library(ndjson)
library(log4r)
library(arrow)
library(datetime)
library(xtable)
# Variables ####

labeled_folder <-
  "data/Results/figure_4"

output_folder <- "data/Results/extended_table_5"
output_filename <- file.path(output_folder,
                             "ed_table_5.csv")
# Load data ####
social_folders <- list.dirs(labeled_folder,
                            recursive = F,
                            full.names = T)

df_stats <- tibble()
for (folder in social_folders)
{
  correlation_files <- list.files(folder,
                                  pattern = "_overall_correlations.parquet",
                                  full.names = T)
  user_files <- list.files(folder,
                           pattern = "_users_for_controversy.parquet",
                           full.names = T)
  
  for (filename in correlation_files)
  {
    i <- 1
    message("Working with ", filename)
    df_social <- read_parquet(filename)
    df_users <- read_parquet(user_files[i])
    
    n_users <- df_users %>% 
      distinct(user_id) %>% 
      count() %>% 
      pull()
    
    df_social_stats = tibble(
      dataset = paste(df_social$social, df_social$topic),
      number_of_profiled_users = n_users,
      average_profiled_users_percentage = NA,
      pearson = df_social$pearson,
      spearman = df_social$spearman,
      kendall = df_social$kendall
    )
    
    df_stats <- rbind(df_stats,
                      df_social_stats)
    
    i <- i + 1
  }
}

print(xtable(df_stats), include.rownames = F)

message("Writing: ", output_filename)
write.csv(df_stats,
          output_filename)
