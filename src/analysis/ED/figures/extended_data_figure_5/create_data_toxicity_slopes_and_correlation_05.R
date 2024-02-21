rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
source("src/utils/binning_functions.R")
source("src/utils/unify_dataset_columns.R")
source("src/utils/participation_and_regression_functions.R")

all_data = setDT(NULL)
# social = c("youtube","voat","usenet","twitter","telegram","reddit","gab","facebook","facebook_news")
social = "voat"
n_bin = 21

for (i in social) {
  # Load already thresholded data, i.e. only threads belonging
  # to [0.7,1]
  
  df = read_parquet(paste0(
    "data/Processed/BinFiltering/",
    i,
    "_comments_with_bin_ge_07.parquet"
  )) %>% setDT()
  
  message("Read ", i)
  
  # Unify column names
  
  df = unify_dataset_columns(df, i)
  print(nrow(df[is.na(date)]))
  df = df[!is.na(date)]
  
  if (i == "gab") {
    df$topic = "feed"
    
  } else if (i == "facebook_news") {
    df$topic = "News"
    
  }
  
  # Set toxicity from NA to 0 and define toxic comments
  
  df[is.na(toxicity_score), "toxicity_score"] = 0
  df$is_toxic_comment = ifelse(df$toxicity_score > 0.5, 1, 0)
  
  # Apply linear binning
  
  df = df[, .(topic,
              root_submission,
              date,
              comment_id,
              user,
              toxicity_score,
              is_toxic_comment)]
  df = df[order(topic, root_submission, date, ), ]
  
  df[, lin_bin := sapply(.SD, linear_bin, n_bin),
     by = .(root_submission, topic), .SDcols = "comment_id"]
  
  # Compute participation and toxicity in each topic, thread
  # and linear bin
  
  tmp = df[, .(
    participation_value =
      sapply(.SD, participation),
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
  
  tmp$social = ifelse(i == "facebook_news", "Facebook", str_to_title(i))
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", i)
  
}

rm(i, n_bin)

###################################
# Data for distribution of slopes #
###################################

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

data_for_plot_slopes[social == "Youtube", "social"] = "YouTube"
data_for_plot_slopes$topic = str_to_title(data_for_plot_slopes$topic)
data_for_plot_slopes$social = factor(
  data_for_plot_slopes$social,
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

if (identical(
  social,
    c("voat"),
)) {
  # In this case save directly the file
  message("Writing a new file!")
  write_parquet(
    data_for_plot_slopes,
    "data/Results/extended_data_figure_7/data_for_plot_toxicity_slopes_05.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social)
  
  use = str_to_title(social)
  all_data_old = read_parquet(
    "data/Results/extended_data_figure_7/data_for_plot_toxicity_slopes_05.parquet"
  ) %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  data_for_plot_slopes = rbind(data_for_plot_slopes, all_data_old)
  print(unique(data_for_plot_slopes$social))
  write_parquet(
    data_for_plot_slopes,
    "data/Results/extended_data_figure_7/data_for_plot_toxicity_slopes_05.parquet"
  )
  
}

########################
# Data for correlation #
########################

data_for_plot_lollipop = all_data[, .(correlation = cor(mean_participation,
                                                        mean_toxicity)),
                                  by = .(social, topic)]

data_for_plot_lollipop[social == "Youtube", "social"] = "YouTube"
data_for_plot_lollipop$topic_and_social = paste(data_for_plot_lollipop$social,
                                                data_for_plot_lollipop$topic)

if (!identical(
  social,
  c(
    "gab",
    "reddit",
    "voat",
    "telegram",
    "twitter",
    "usenet",
    "youtube",
    "facebook"
  )
)) {
  # In this case save directly the file
  message("Writing a new file!")
  write_parquet(
    data_for_plot_lollipop,
    "data/Results/extended_data_figure_7/data_for_plot_correlations_05.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social)
  
  use = str_to_title(social)
  all_data_old = read_parquet("data/Results/extended_data_figure_7/data_for_plot_correlations_05.parquet") %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  data_for_plot_lollipop = rbind(all_data_old, data_for_plot_lollipop)
  print(unique(data_for_plot_lollipop$social))
  write_parquet(
    data_for_plot_lollipop,
    "data/Results/extended_data_figure_7/data_for_plot_correlations_05.parquet"
  )
  
}
