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

# Start with a vector of social

all_data <- setDT(NULL)
# social <- c("gab", "reddit", "voat", "telegram", "twitter", "usenet", "youtube", "facebook")
social = c("voat")

for (i in social) {
  # Read all the comments
  
  if (i == "facebook") {
    df <-
      read_parquet("data/Labeled/Facebook/facebook_labeled_data_unified_except_news.parquet") %>%
      setDT()
  } else {
    df <- read_parquet(
      paste0(
        "data/Labeled/",
        str_to_title(i),
        "/",
        i,
        "_labeled_data_unified.parquet"
      )
    ) %>%
      setDT()
  }
  
  message("Read: ", i)
  
  # Unify column names
  
  df <- unify_dataset_columns(df, i)
  
  if (i == "gab") {
    df$topic <- "feed"
  }
  
  # Define toxic comments
  # In this case we consider toxic a comment having a score greater than 0.5
  
  df[is.na(toxicity_score), "toxicity_score"] <- 0
  df$is_toxic <- ifelse(df$toxicity_score > 0.5, 1, 0)
  
  # Compute the length of each thread
  
  df <- df[, .(thread_length = .N,
               toxicity_percentage = sum(is_toxic) / .N), by = .(root_submission, topic)]
  
  # Just to be clear
  
  df <-
    df[, .(root_submission, thread_length, toxicity_percentage, topic)]
  df <- df[order(thread_length, topic)]
  
  # Binning for the thread length
  
  df[, discretized_bin_label := sapply(.SD, log_bin, 21),
     by = .(topic), .SDcols = "thread_length"]
  
  # Modify the binning -> the last bin must have 50 elements
  
  resize_df <- setDT(NULL)
  
  for (j in unique(df$topic)) {
    aux <- resize_last_bin(df[topic == j])
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
    ifelse(i == "facebook_news", "Facebook", str_to_title(i))
  all_data <- rbind(all_data, data_for_plot)
  rm(tmp, df)
  gc()
  message("Done with ", i)
}

all_data$topic = str_to_title(all_data$topic)
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
    "Youtube"
  )
)
all_data[social == "Youtube", "social"] <- "YouTube"

if (identical(
  social,
  c(
    "voat"
  )
)) {
  # In this case save directly the file
  message("Writing a new file!")
  write_parquet(
    all_data,
    "data/Results/extended_data_figure_7/data_for_plot_toxicity_threads_by_bin_with_05.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social)
  
  use = str_to_title(social)
  
  all_data_old = read_parquet(
    "data/Results/extended_data_figure_7/data_for_plot_toxicity_threads_by_bin_with_05.parquet"
  ) %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  # Update it
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(
    all_data,
    "data/Results/extended_data_figure_7/data_for_plot_toxicity_threads_by_bin_with_05.parquet"
  )
  
}