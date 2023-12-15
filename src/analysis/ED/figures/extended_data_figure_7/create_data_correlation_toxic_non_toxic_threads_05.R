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


all_data = setDT(NULL)
# social = c("gab","reddit","voat","telegram","twitter","usenet","youtube","facebook","facebook_news")
social = c("voat", "usenet")
n_bin = 21

for (i in social) {
  # Read already thresholded data, i.e. only threads belonging
  # to [0.7,1]
  
  df = read_parquet(paste0(
    "data/Processed/BinFiltering/",
    i,
    "_comments_with_bin_ge_07.parquet"
  )) %>% setDT()
  
  message("Read: ", i)
  
  # Unify column names
  
  df = unify_dataset_columns(df, i)
  print(nrow(df[is.na(date)]))
  df = df[!is.na(date)]
  
  if (i == "gab") {
    df$topic = "feed"
    
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
  
  tmp = df[, .(participation_value =
                 sapply(.SD, participation)),
           by = .(topic, root_submission, lin_bin),
           .SDcols = "user"]
  
  # Now it's time to distinguish between toxic and non-toxic thread
  # Compute toxicity of each thread (i.e. fraction of toxic comments)
  
  toxicity_distribution = df[, .(toxicity = sum(is_toxic_comment) / .N),
                             by = .(topic, root_submission)]
  
  # Define toxic threads
  # is_toxic_thread say if the toxicity of a thread is greater than
  # the mean plus a standard deviation
  
  toxicity_distribution$is_toxic_thread =
    ifelse(
      toxicity_distribution$toxicity >
        mean(toxicity_distribution$toxicity) +
        sd(toxicity_distribution$toxicity),
      1,
      0
    )
  
  # Merge with the previous information
  
  tmp = merge(tmp, select(toxicity_distribution, -c("toxicity")))
  
  # Average over all the threads considering its toxicity status
  # Obtain only [lin_bin,is_toxic_thread,mean_participation,mean_toxicity]
  
  tmp = tmp[, .(mean_participation = mean(participation_value)),
            by = .(topic, lin_bin, is_toxic_thread)]
  
  tmp$social = ifelse(i == "facebook_news", "Facebook", str_to_title(i))
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", i)
  
}

# Adjust data to have two columns for toxic participation and non toxic
# participation

tmp1 = all_data[is_toxic_thread == 0, -c("is_toxic_thread")] %>%
  rename("participation_non_toxic" = "mean_participation")

tmp2 = all_data[is_toxic_thread == 1, -c("is_toxic_thread")] %>%
  rename("participation_toxic" = "mean_participation")

all_data = merge(tmp1, tmp2)
rm(tmp1, tmp2)

#########################################################################
# Plot correlation between participation in toxic and non toxic threads #
#########################################################################

data_for_plot_correlation = all_data[, .(correlation =
                                           cor(participation_non_toxic,
                                               participation_toxic)),
                                     by = .(social, topic)]

data_for_plot_correlation[social == "Youtube", "social"] = "YouTube"

data_for_plot_correlation$topic_and_social =
  paste(data_for_plot_correlation$social,
        data_for_plot_correlation$topic)

# Update or save a new file

if (identical(
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
    data_for_plot_correlation,
    "data/Results/extended_data_figure_7/data_for_plot_correlation_toxic_non_toxic_threads_05.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets #
  # Read the previous file
  
  message("Updating: ", social)
  
  use = str_to_title(social)
  all_data_old = read_parquet(
    "data/Results/extended_data_figure_7/data_for_plot_correlation_toxic_non_toxic_threads_05.parquet"
  ) %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  data_for_plot_correlation = rbind(all_data_old, data_for_plot_correlation)
  print(unique(data_for_plot_correlation$social))
  write_parquet(
    data_for_plot_correlation,
    "data/Results/extended_data_figure_7/data_for_plot_correlation_toxic_non_toxic_threads_05.parquet"
  )
  
}