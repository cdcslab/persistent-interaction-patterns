library(dplyr)
library(xtable)
library(arrow)

rm(list = ls())
gc()

# Variables
input_folder <- "data/Results/figure_4/"
ed3_folder <- "data/Results/extended_table_3"

socials <- c("Gab", "Twitter", "Facebook")

# Create dataset
df_result <- tibble()
for (social in socials)
{
  df_social <- tibble()
  social_controversy_folder <- file.path(input_folder,
                                         social)
  
  correlation_files <- list.files(social_controversy_folder,
                                  "overall_correlations.parquet",
                                  full.names = T)
  
  for (cf in correlation_files)
  {
    message("Working with: ", cf)
    df_correlation <- read_parquet(cf)
    
    df_social <- plyr::rbind.fill(df_social,
                                  df_correlation)
  }
  
  ed3_files <- list.files(ed3_folder,
                          tolower(social),
                          full.names = T)
  
  df_ed3 <- tibble()
  for (ed3file in ed3_files)
  {
    message("Reading ", ed3file)
    df_social_topic_ed3 <- read_parquet(ed3file)
    
    df_ed3 <- plyr::rbind.fill(df_ed3,
                               df_social_topic_ed3)
  }
  
  if (dim(df_ed3)[1] > 0)
  {
    df_social <- cbind(df_social,
                       df_ed3)
  }
  
  
  df_result <- plyr::rbind.fill(df_result,
                                df_social)
}

df_result <- df_result %>%
  distinct(social, topic, .keep_all = T)

df_result$name <- paste(df_result$social,
                        df_result$topic)

df_result <- df_result %>%
  select(
    name,
    threads,
    users,
    average_percentage_of_labeled_users,
    pearson,
    spearman,
    kendall
  )

df_result <- df_result %>%
  arrange(name)
print(xtable(df_result))
