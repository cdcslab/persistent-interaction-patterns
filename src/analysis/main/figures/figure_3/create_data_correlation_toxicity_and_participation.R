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


all_data = setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with
n_bin = 21

for (social_media_name in social_to_work_with) {
  # Load already thresholded data, i.e. only threads belonging
  # to [0.7,1]
  
  df = read_parquet(
    paste0(
      "data/Processed/BinFiltering/",
      social_media_name,
      "_comments_with_bin_ge_07.parquet"
    )
  ) %>% setDT()
  
  message("Read: ", social_media_name)
  
  # Unify column names
  
  df = unify_dataset_columns(df, social_media_name)
  print(nrow(df[is.na(date)]))
  df = df[!is.na(date)]
  
  # Set toxicity from NA to 0 and define toxic comments
  
  df[is.na(toxicity_score), "toxicity_score"] = 0
  df$is_toxic_comment = ifelse(df$toxicity_score > 0.6, 1, 0)
  
  # Apply linear binning
  
  df = df[, .(topic,
              root_submission,
              date,
              comment_id,
              user,
              toxicity_score,
              is_toxic_comment)]
  df = df[order(topic, root_submission, date), ]
  
  df[, lin_bin := sapply(.SD, linear_bin, n_bin),
     by = .(root_submission, topic), .SDcols = "comment_id"]
  
  # Compute participation and toxicity in each topic, thread
  # and linear bin
  
  tmp = df[, .(
    participation_value = sapply(.SD, participation),
    toxicity_bin = sum(is_toxic_comment) / .N
  ),
  by = .(topic, root_submission, lin_bin),
  .SDcols = "user"]
  
  # Average over all the threads
  # Obtain only [lin_bin,mean_participation,mean_toxicity]
  
  tmp = tmp[, .(
    mean_participation = mean(participation_value),
    mean_toxicity = mean(toxicity_bin)
  ),
  by = .(topic, lin_bin)]
  
  # Aggregate with other data
  
  tmp$social = ifelse(
    social_media_name == "facebook_news",
    "Facebook",
    str_to_title(social_media_name)
  )
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", social_media_name)
  
}

rm(social_media_name, n_bin)

all_data$social = str_to_title(all_data$social)
all_data[topic == "Climatechange", "topic"] = "Climate Change"
all_data[social == "Youtube", "social"] = "YouTube"

if (identical(social_to_work_with,
              social_unique_names)) {
  # In this case save directly the file
  message("Writing a new file!")
  write_parquet(
    all_data,
    "data/Results/figure_3/all_data_for_correlation_and_participation.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  message("Updating: ", social_to_work_with)
  
  use = str_to_title(social_to_work_with)
  all_data_old = read_parquet("data/Results/figure_3/all_data_for_correlation_and_participation.parquet") %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  # Update it
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(
    all_data,
    "data/Results/figure_3/all_data_for_correlation_and_participation.parquet"
  )
  
}

###############################
# Plot distribution of slopes #
###############################

# Obtain the slopes of each regression over the topic and bin

tmp1 = all_data[, .(participation_slopes =
                      sapply(.SD, regression_coefficient)),
                by = .(social, topic),
                .SDcols = c("mean_participation")]

tmp2 = all_data[, .(toxicity_slopes =
                      sapply(.SD, regression_coefficient)),
                by = .(social, topic),
                .SDcols = c("mean_toxicity")]

data_for_plot_slopes = merge(tmp1, tmp2)
rm(tmp1, tmp2)

write_parquet(data_for_plot_slopes,
              "data/Results/figure_3/data_for_plot_slopes.parquet")

#############################
# Data correlation lollipop #
#############################

data_for_plot_lollipop = all_data[, .(correlation = cor(mean_participation,
                                                        mean_toxicity)),
                                  by = .(social, topic)]

data_for_plot_lollipop$topic_and_social = paste(data_for_plot_lollipop$social,
                                                data_for_plot_lollipop$topic)

write_parquet(
  data_for_plot_lollipop,
  "data/Results/figure_3/data_for_plot_correlation_participation_toxicity.parquet"
)
