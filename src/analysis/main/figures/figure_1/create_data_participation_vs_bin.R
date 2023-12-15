rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(lubridate)
source("src/utils/binning_functions.R")
source("src/utils/participation_and_regression_functions.R")
source("src/utils/compute_CI.R")
source("src/utils/unify_dataset_columns.R")

# Choose the social
all_data <- setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with
n_bin <- 21
output_folder <- "data/Results/figure_1/"

for (social in social_to_work_with) {
  df <- read_parquet(
    paste0(
      "data/Processed/BinFiltering/",
      social,
      "_comments_with_bin_ge_07.parquet"
    )
  ) %>% setDT()
  
  message("Read: ", social)
  
  # Unify column names
  df <- unify_dataset_columns(df, social)
  df <- df[!is.na(date)]
  
  # Order the comments by date,time and topic
  # Then apply linear binning
  
  df <-
    df[, .(topic,
           root_submission,
           date,
           comment_id,
           user,
           toxicity_score)]
  df <- df[order(topic, root_submission, date, ), ]
  
  df[, lin_bin := sapply(.SD, linear_bin, n_bin),
     by = .(root_submission, topic), .SDcols = "comment_id"]
  
  # Compute participation for each topic and thread, inside
  # each linear bin
  
  df_participation <- df[, .(participation_value =
                               sapply(.SD, participation)),
                         by = .(topic, root_submission, lin_bin),
                         .SDcols = "user"]
  
  # Plot the participation vs (linear) bin
  
  data_for_plot <-
    df_participation[, .(
      mean_p = mean(participation_value),
      CI_participation = lapply(.SD, compute_CI)
    ),
    by = .(topic, lin_bin), .SDcols = "participation_value"]
  
  tmp <- unlist(data_for_plot$CI_participation)
  
  data_for_plot = data_for_plot %>%
    mutate(
      CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
      CI_sup = tmp[seq(2, length(tmp), by = 2)],
      CI_participation = NULL,
      social = ifelse(social == "facebook_news", "Facebook", str_to_title(social))
    )
  
  # Gather the data together
  
  all_data <- rbind(all_data, data_for_plot)
  rm(data_for_plot, tmp, df, df_participation)
  gc()
  message("Done with ", social)
  
}

all_data$topic <- str_to_title(all_data$topic)
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
all_data[social == "Youtube", "social"] = "YouTube"

if (identical(social_to_work_with, social_unique_names)) {
  # In this case save directly the file
  message("Writing results..")
  write_parquet(
    all_data,
    file.path(
      output_folder,
      "data_for_plot_participation_vs_bin.parquet"
    )
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social)
  use <- ifelse(social == "youtube", "YouTube", str_to_title(social))
  
  all_data_old <-
    read_parquet(file.path(
      output_folder,
      "data_for_plot_participation_vs_bin.parquet"
    )) %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  all_data <- rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(
    all_data,
    file.path(
      output_folder,
      "data_for_plot_participation_vs_bin.parquet"
    )
  )
  
  message("Updated: ", social_to_work_with)
  
}

message("Done")

