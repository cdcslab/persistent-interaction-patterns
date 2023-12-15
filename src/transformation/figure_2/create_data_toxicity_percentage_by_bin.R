rm(list = ls())
gc()

library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(data.table)
source("src/utils/binning_functions.R")
source("src/utils/compute_CI.R")
source("src/utils/unify_dataset_columns.R")
source("src/utils/participation_and_regression_functions.R")

# Start with a vector of social

all_data <- setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with
output_folder <- "data/Results/figure_2/"
output_filename <-
  file.path(output_folder,
            "data_for_plot_toxicity_threads_by_bin.parquet")
n_bin = 21

for (social_media_name in social_to_work_with) {
  # Read all the comments
  if (social_media_name == "facebook") {
    df <-
      read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>%
      setDT()
    
  } else {
    df <- read_parquet(
      paste0(
        "data/Labeled/",
        str_to_title(social_media_name),
        "/",
        social_media_name,
        "_labeled_data_unified.parquet"
      )
    ) %>% setDT()
    
  }
  
  message("Read: ", social_media_name)
  
  # Unify column name
  df <- unify_dataset_columns(df, social_media_name)
  
  # Define toxic comments
  # In this case we consider toxic a comment having a score greater than 0.6
  df[is.na(toxicity_score), "toxicity_score"] <- 0
  df$is_toxic <- ifelse(df$toxicity_score > 0.6, 1, 0)
  
  # Compute the length of each thread
  df <- df[, .(thread_length = .N,
               toxicity_percentage = sum(is_toxic) / .N),
           by = .(root_submission, topic)]
  
  # Just to be clear
  df <-
    df[, .(root_submission, thread_length, toxicity_percentage, topic)]
  df <- df[order(thread_length, topic)]
  
  # Binning for the thread length
  df[, discretized_bin_label := sapply(.SD, log_bin, n_bin = n_bin),
     by = .(topic), .SDcols = "thread_length"]
  
  # Modify the binning -> the last bin must have 50 elements
  resize_df <- setDT(NULL)
  
  for (j in unique(df$topic)) {
    aux <- resize_last_bin(df[topic == j], n_bin = n_bin)
    resize_df <- rbind(resize_df, aux)
  }
  
  rm(aux)
  
  data_for_plot <- resize_df[, .(
    mean_t = mean(toxicity_percentage),
    CI_toxicity = lapply(.SD, compute_CI)
  ),
  by = .(topic, resize_discretized_bin_label),
  .SDcols = "toxicity_percentage"]
  
  tmp <- unlist(data_for_plot$CI_toxicity)
  
  data_for_plot <- data_for_plot %>%
    mutate(CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
           CI_sup = tmp[seq(2, length(tmp), by = 2)],
           CI_toxicity = NULL)
  
  # Gather data together
  data_for_plot$social <-
    ifelse(social_media_name == "facebook_news", "Facebook", str_to_title(social_media_name))
  all_data <- rbind(all_data, data_for_plot)
  rm(tmp, df)
  gc()
  message("Done with ", social_media_name)
}

all_data$topic = str_to_title(all_data$topic)
all_data[topic == "Climatechange", "topic"] = "Climate Change"
all_data[social == "Youtube", "social"] <- "YouTube"
all_data$social <- factor(
  all_data$social,
  levels = c(
    "Usenet",
    "Facebook",
    "Gab",
    "Reddit",
    "Telegram",
    "Twitter",
    "Voat",
    "YouTube"
  )
)

if (identical(social_to_work_with,
              social_unique_names)) {
  # In this case save directly the file
  write_parquet(all_data,
                output_filename)
  
} else {
  # Change the result of a subset of the datasets #
  message("Updating: ", social_to_work_with)
  use = str_to_title(social_to_work_with)
  
  all_data_old = read_parquet(output_filename) %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(all_data,
                output_filename)
  
}
