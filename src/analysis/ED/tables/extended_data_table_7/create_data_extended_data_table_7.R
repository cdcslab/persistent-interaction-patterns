rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(trend)
library(xtable)
source("./src/utils/unify_validation_dataset.R")

list_dataset = list.files("data/validation_dataset_without_root/")
all_data = setDT(NULL)

for (i in list_dataset) {
        
    # Read the whole dataset
        
    df <- read_parquet(paste0("data/validation_dataset_without_root/",i)) %>% setDT()
    message("Read: ", i)

    # Unify column names

    df = unify_validation_dataset(df,i) %>%
         mutate(date = as.Date(date)) 
    k = unique(df$social)

    # Compute percentage of toxic comments for each classificator

    df[is.na(toxicity_score),"toxicity_score"] = 0
    df$is_toxic_perspective = ifelse(df$toxicity_score > 0.6,1,0)
    
    df[is.na(detoxify_scoreM), "detoxify_scoreM"] = 0
    df$is_toxic_detoxify <- ifelse(df$detoxify_scoreM > 0.6, 1, 0)

    df[is.na(imsypp_label), "imsypp_label"] = "acceptable"
    df$is_toxic_imsypp <- ifelse(df$imsypp_label != "acceptable", 1, 0)

    # Number of comments, threads, users, time range

    data_for_table = df[,.(time_range = paste(min(date),max(date),sep = " "), n_comments = .N,
                 n_threads = length(unique(root_submission)),
                 n_users = length(unique(user)),
                 toxicity_perspective = sum(is_toxic_perspective)/.N,
                 toxicity_detoxify = sum(is_toxic_detoxify)/.N,
                 toxicity_imsypp = sum(is_toxic_imsypp)/.N), by = .(topic)] %>%
                 mutate(time_range = gsub("-","/",time_range))

    data_for_table$social = str_to_title(k)
    all_data = rbind(all_data, data_for_table)
    rm(df)
    gc()
        
    message("Done with ", i)
        
}   

all_data$social_topic = paste(all_data$social, str_to_title(all_data$topic))
all_data$time_range = gsub(" ","-",all_data$time_range)
write_parquet(all_data, "data/Results/extended_data_table_5.parquet")
