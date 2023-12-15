rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
source("src/utils/binning_functions.R")
source("src/utils/participation_and_regression_functions.R")
source("src/utils/compute_CI.R")
source("src/utils/unify_dataset_columns.R")

# Choose the social

all_data = setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with

n_bin = 21

for (social_media_name in social_to_work_with) {
  df = read_parquet(
    paste0(
      "data/Processed/BinFiltering/",
      social_media_name,
      "_comments_with_bin_ge_07.parquet"
    )
  ) %>% setDT()
  
  message("Working with ", social_media_name)
  
  # Unify column names
  
  df = unify_dataset_columns(df, social_media_name)
  
  df = df[!is.na(date)]
  # Set toxicity from NA to 0 and define toxic comments
  
  df[is.na(toxicity_score), "toxicity_score"] = 0
  df$is_toxic = ifelse(df$toxicity_score > 0.6, 1, 0)
  
  # Order the comments by date,time and topic
  # Then apply linear binning
  
  df = df[, .(topic,
              root_submission,
              date,
              comment_id,
              user,
              toxicity_score,
              is_toxic)]
  df = df[order(topic, root_submission, date, ), ]
  
  df[, lin_bin := sapply(.SD, linear_bin, n_bin),
     by = .(root_submission, topic), .SDcols = "comment_id"]
  
  # Compute toxicity for each topic and thread, inside
  # each linear bin
  
  df_toxicity = df[, .(toxicity_value = sum(is_toxic) / .N),
                   by = .(topic, root_submission, lin_bin)]
  
  # Plot the participation vs (linear) bin
  
  data_for_plot = df_toxicity[, .(
    mean_toxicity =
      mean(toxicity_value),
    CI_participation =
      lapply(.SD, compute_CI)
  ),
  by = .(topic, lin_bin),
  .SDcols = "toxicity_value"]
  
  tmp = unlist(data_for_plot$CI_participation)
  
  data_for_plot = data_for_plot %>%
    mutate(
      CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
      CI_sup = tmp[seq(2, length(tmp), by = 2)],
      CI_participation = NULL,
      social = ifelse(
        social_media_name == "facebook_news",
        "Facebook",
        str_to_title(social_media_name)
      )
    )
  
  # Gather the data together
  
  all_data = rbind(all_data, data_for_plot)
  
  rm(data_for_plot, tmp, df, df_toxicity)
  gc()
  
  message("Done with ", social_media_name)
  
}

rm(n_bin, social_media_name)

if (identical(social_to_work_with, social_unique_names)) {
  # In this case save directly the file
  message("Writing a new file!")
  write_parquet(
    all_data,
    "data/Results/extended_data_figure_3/data_for_plot_toxicity_vs_bin.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social_to_work_with)
  use = str_to_title(social_to_work_with)
  
  all_data_old = read_parquet("data/Results/extended_data_figure_3/data_for_plot_toxicity_vs_bin.parquet") %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(
    all_data,
    "data/Results/extended_data_figure_3/data_for_plot_toxicity_vs_bin.parquet"
  )
}

