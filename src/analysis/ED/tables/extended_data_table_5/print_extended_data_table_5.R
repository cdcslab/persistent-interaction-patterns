library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(trend)
library(xtable)

all_data = read_parquet("data/Results/extended_data_table_5.parquet") %>%
           select(-c("social","topic"))
all_data = all_data[,c("social_topic","time_range","n_comments","n_threads","n_users",
                       "toxicity_perspective","toxicity_detoxify","toxicity_imsypp")]

print(xtable(all_data), include.rownames = F)
