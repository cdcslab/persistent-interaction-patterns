library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(data.table)
source("src/utils/binning_functions.R")
source("src/utils/compute_CI.R")
source("src/utils/unify_validation_dataset.R")
source("src/utils/participation_and_regression_functions.R")

# Start with a vector of social

all_data = setDT(NULL)
list_dataset = list.files("data/validation_dataset_without_root/")
n_bin = 21

for (i in list_dataset){

  df <- read_parquet(paste0("data/validation_dataset_without_root/",i)) %>% setDT()

  message("Read: ", i)

  # Unify column names

  df = unify_validation_dataset(df,i)
  k = unique(df$social)

  # Define toxic comments
  # In this case we consider toxic a comment having a score greater than 0.5
  df[is.na(imsypp_label), "imsypp_label"] = "acceptable"
  df$is_toxic <- ifelse(df$imsypp_label != "acceptable", 1, 0)

  # Compute the length of each thread

  df <- df[, .(thread_length = .N,
    toxicity_percentage = sum(is_toxic) / .N
  ), by = .(root_submission, topic)]

  # Just to be clear

  df <- df[, .(root_submission, thread_length, toxicity_percentage,topic)]
  df <- df[order(thread_length, topic)]

  # Binning for the thread length

  df[, discretized_bin_label := sapply(.SD, log_bin, 21),
    by = .(topic), .SDcols = "thread_length"]

  # Modify the binning -> the last bin must have 50 elements

  resize_df <- setDT(NULL)

  for (j in unique(df$topic)) {

    aux <- resize_last_bin(df[topic == j], n_bin = 21)
    resize_df <- rbind(resize_df, aux)

  }

  rm(aux)

  data_for_plot <- resize_df[, .(mean_t = mean(toxicity_percentage),
    CI_toxicity = lapply(.SD, compute_CI)),
  by = .(topic, resize_discretized_bin_label),
  .SDcols = "toxicity_percentage"]

  tmp <- unlist(data_for_plot$CI_toxicity)

  data_for_plot <- data_for_plot %>%
    mutate(
      CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
      CI_sup = tmp[seq(2, length(tmp), by = 2)],
      CI_toxicity = NULL
    )

  # Gather data together
  data_for_plot$social <- k
  all_data <- rbind(all_data, data_for_plot)
  rm(tmp, df)
  gc()
  message("Done with ", i)

}

all_data$topic = str_to_title(all_data$topic)
all_data$social <- factor(all_data$social,
  levels = c("Facebook","Reddit","Telegram","Twitter","Voat","YouTube"))

write_parquet(all_data, "data/Results/extended_data_figure_5/data_for_plot_validation_toxicity_threads_by_bin_imsypp.parquet")
