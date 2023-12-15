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
source("./src/utils/binning_functions.R")
source("./src/utils/apply_mk_and_regression.R")
source("./src/utils/unify_dataset_columns.R")

all_data = setDT(NULL)
# social = c("gab","reddit","voat","telegram","twitter","usenet","youtube","facebook","facebook_news")
social = "gab"

for (i in social) {
  
  # Read the whole dataset
  
  if (i == "facebook") {

     df <- read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>% 
              setDT() 

  } else if (i == "facebook_news") {
     
     df <- fread("facebook_snews.csv") %>% setDT()
  
  } else {

    df <- read_parquet(paste0("data/Labeled/",str_to_title(i),"/",i,
                            "_labeled_data_unified.parquet")) %>% 
              setDT() 

  } 

  df[is.na(toxicity_score),"toxicity_score"] = 0
  
  message("Read: ", i)

  # Unify column names

  df = unify_dataset_columns(df,i)

  if (i == "gab") {

    df$topic = "feed"

  } 
  
  ##########################################
  # Compute the log-binning (once for all) #
  ##########################################
  
  # Thread length
  
  df[, thread_length := .N, by = .(root_submission,topic)]
  
  # Bin thread length
  
  df[, discretized_bin_label := sapply(.SD, log_bin, 21),
     by = .(topic), .SDcols = "thread_length"] 
  
  # Modify the binning -> the last bin must have 50 elements
  
  resize_df = setDT(NULL)
  
  for (j in unique(df$topic)) {
    
    aux = resize_last_bin(df[topic == j], n_bin = 21)
    resize_df = rbind(resize_df,aux)
    
  }
  
  # Compute original trend
  
  resize_df$is_toxic = ifelse(resize_df$toxicity_score > 0.5, 1, 0)
  
  tmp = resize_df[,.(toxicity_percentage = sum(is_toxic)/.N),
            by = .(topic, root_submission, resize_discretized_bin_label)]
  
  real_trend = tmp[,.(mean_t = mean(toxicity_percentage)),
                by = .(topic, resize_discretized_bin_label)]
  
  ##############################
  # Apply MK-test & regression #
  ##############################
  
  data_for_table = apply_mk_and_regression(real_trend)
  
  # Aggregate with other data
  
  data_for_table$social = ifelse(i == "facebook_news","Facebook",str_to_title(i))
  all_data = rbind(all_data, data_for_table)
  rm(tmp,df)
  gc()
  
  message("Done with ", i)
  
}

all_data$social_topic = paste(all_data$social, str_to_title(all_data$topic))

if (identical(social,c("gab","reddit","voat","telegram","twitter","usenet","youtube","facebook","facebook_news"))) {

  # In this case save directly the file

  message("Writing a new file!")
  write_parquet(all_data, "data/Results/data_for_extended_data_table_10.parquet") 

} else {

  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social)

  use = str_to_title(social)
  all_data_old = read_parquet("data/Results/data_for_extended_data_table_10.parquet") %>%
                      filter(!(social %in% use))
  print(unique(all_data_old$social))  

  # Update it

  all_data = rbind(all_data_old,all_data)
  print(unique(all_data$social))  
  write_parquet(all_data, "data/Results/data_for_extended_data_table_10.parquet")

}


