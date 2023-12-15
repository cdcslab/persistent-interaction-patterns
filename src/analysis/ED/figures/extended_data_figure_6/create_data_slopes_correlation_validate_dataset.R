rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
source("src/transformation/binning_functions.R")
source("src/transformation/participation_and_regression_functions.R")
source("src/transformation/compute_CI.R")
source("src/transformation/unify_validation_dataset.R")

folder_to_save = "data/Results/extended_data_figure_6/"
all_data = setDT(NULL)
list_dataset = list.files("data/validation_dataset_ge_07/")
n_bin = 21

# Chose one between perspective, imsypp and detoxify
classificator = "detoxify"

for (i in list_dataset) {
  # Load already thresholded data, i.e. only threads belonging
  # to [0.7,1]
  
  df <-
    read_parquet(paste0("data/validation_dataset_ge_07/", i)) %>% setDT()
  
  message("Read: ", i)
  
  # Unify column names
  
  k = unique(df$social)
  
  # Set toxicity from NA to 0 and define toxic comments
  
  if (classificator == "perspective") {
    df[is.na(toxicity_score), "toxicity_score"] = 0
    df$is_toxic_comment = ifelse(df$toxicity_score > 0.6, 1, 0)
    
  } else if (classificator == "detoxify") {
    df[is.na(detoxify_scoreM), "detoxify_scoreM"] = 0
    df$is_toxic_comment <- ifelse(df$detoxify_scoreM > 0.6, 1, 0)
    
  } else if (classificator == "imsypp") {
    df[is.na(imsypp_label), "imsypp_label"] = "acceptable"
    df$is_toxic_comment <-
      ifelse(df$imsypp_label != "acceptable", 1, 0)
    
  } else {
    stop("Not a valid classificator!")
    
  }
  
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
  
  tmp$social = k
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", i)
  
}

rm(i, n_bin)

all_data$social = str_to_title(all_data$social)
all_data[social == "Youtube", "social"] = "YouTube"

write_parquet(
  all_data,
  paste0(
    folder_to_save,
    "all_data_for_correlation_and_slopes_",
    classificator,
    ".parquet"
  )
)

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

write_parquet(
  data_for_plot_slopes,
  paste0(
    folder_to_save,
    "all_data_for_slopes_",
    classificator,
    ".parquet"
  )
)

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
  paste0(
    folder_to_save,
    "all_data_for_correlation_participation_toxicity_",
    classificator,
    ".parquet"
  )
)