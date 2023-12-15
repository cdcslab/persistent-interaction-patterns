rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
source("src/utils/binning_functions.R")
source("src/utils/compute_CI.R")
source("src/utils/unify_dataset_columns.R")
source("src/utils/participation_and_regression_functions.R")
source("src/utils/resize_last_bin_lifetime.R")

all_data = setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with
n_bin = 21

for (social_media_name in social_to_work_with) {
  
  # Read the whole dataset
  
  if (social_media_name == "facebook") {

     df <- read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>% 
              setDT() 

  } else {

    df <- read_parquet(paste0("data/Labeled/",str_to_title(social_media_name),"/",social_media_name,
                            "_labeled_data_unified.parquet")) %>% 
              setDT() 

  } 

  message("Read: ",social_media_name)

  # Unify column names

  df = unify_dataset_columns(df,social_media_name)

  if (social_media_name == "twitter") {

    df = select(df, -c("text","like_count","url"))
    gc()

  }

  if (social_media_name == "gab") {

    df$topic = "feed"

  } 
  
  # Set toxicity from NA to 0 and define toxic comments
  
  df[is.na(toxicity_score),"toxicity_score"] = 0
  df$is_toxic = ifelse(df$toxicity_score > 0.6,1,0)
  
  # Compute lifetime of users and their toxicity

  if (social_media_name %in% c("telegram","facebook","gab")) {

     df$date = as.POSIXct(df$date, format = "%Y-%m-%dT%H:%M:%S")

  } else if (social_media_name == "usenet") {

    df$date = ymd_hms(df$date)

  } else if (social_media_name == "youtube") {

    df$date = as.POSIXct(df$date, format="%Y-%m-%dT%H:%M:%SZ")

  }
  
  df_lifetime = df[,.(lifetime = floor(difftime(max(date),min(date), 
                                        units = "days")),
              toxicity_percentage = sum(is_toxic)/.N), 
           by = .(topic,root_submission)]
  
  # Delete NA elements

  df_lifetime = df_lifetime[!is.na(lifetime),]
  
  # Apply log-binning 
  
  df_lifetime = df_lifetime[order(topic,lifetime),]
  df_lifetime$lifetime = as.numeric(df_lifetime$lifetime) + 1
  
  df_lifetime[, discretized_bin_label := sapply(.SD, log_bin, n_bin), 
      by = .(topic), .SDcols = "lifetime"]
  
  # Resize last bin (if necessary)
  # Do it for each topic
  
  data_for_plot = NULL
  
  for (j in unique(df_lifetime$topic)) {
    
    aux = resize_last_bin_lifetime(df_lifetime[topic == j],n_bin)
    data_for_plot = rbind(data_for_plot,aux)
    
  }
  
  rm(aux)
  
  # Average over all the threads
  # Obtain only [lin_bin,mean_participation,mean_toxicity]
  
  data_for_plot = data_for_plot[,.(mean_toxicity = mean(toxicity_percentage),
                                   CI_toxicity = lapply(.SD,
                                                        compute_CI)),
                                by = .(topic,resize_discretized_bin_label), 
                                .SDcols = "toxicity_percentage"]
  
  tmp = unlist(data_for_plot$CI_toxicity)
  
  data_for_plot = data_for_plot %>%
    mutate(CI_inf = tmp[seq(1,length(tmp)-1,by = 2)],
           CI_sup = tmp[seq(2,length(tmp),by = 2)],
           CI_toxicity = NULL)
  
  # Aggregate with other data
  
  data_for_plot$social = ifelse(social_media_name == "facebook_news","Facebook",str_to_title(social_media_name))
  all_data = rbind(all_data, data_for_plot)
  rm(tmp,df,df_lifetime)
  gc()
  
  message("Done with ", social_media_name)
  
}

all_data$social = str_to_title(all_data$social)
all_data$social = factor(all_data$social, 
                    levels = c("Usenet","Facebook","Gab","Reddit","Telegram","Twitter","Voat","Youtube"))

if (identical(social_to_work_with,
              social_unique_names)) {

  # In this case save directly the file

  write_parquet(all_data, "data/Results/extended_data_figure_4/data_for_plot_toxicity_vs_lifetime_thread.parquet") 

} else {

  # Change the result of a subset of the datasets #
  # Read the previous file

  message("Updating: ", social_to_work_with)
  
  use = str_to_title(social_to_work_with)
  all_data_old = read_parquet("data/Results/extended_data_figure_4/data_for_plot_toxicity_vs_lifetime_thread.parquet") %>%
                          filter(!(social %in% use))
  print(unique(all_data_old$social))

  # Update it

  all_data = rbind(all_data_old,all_data)
  print(unique(all_data$social))
  write_parquet(all_data, "data/Results/extended_data_figure_4/data_for_plot_toxicity_vs_lifetime_thread.parquet")

}
