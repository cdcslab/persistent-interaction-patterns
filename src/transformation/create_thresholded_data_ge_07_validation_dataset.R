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

# Use this script to save the thread in [0.7,1] of the validation datasets

all_data = setDT(NULL)
list_dataset = list.files("data/validation_dataset_without_root/")
n_bin = 21

for (i in list_dataset) {
  df <-
    read_parquet(paste0("data/validation_dataset_without_root/", i)) %>% setDT()
  
  message("Read: ", i)
  
  # Unify column names
  
  df = unify_validation_dataset(df, i)
  
  # Compute the length of each thread
  
  tmp <- df[, .(thread_length = .N),
            by = .(root_submission, topic)]
  
  # Binning for the thread length
  
  tmp[, discretized_bin_label := sapply(.SD, log_bin, 21),
      by = .(topic), .SDcols = "thread_length"]
  
  # Modify the binning -> the last bin must have 50 elements
  
  resize_df <- setDT(NULL)
  
  for (j in unique(df$topic)) {
    aux <- resize_last_bin(tmp[topic == j], n_bin = n_bin)
    resize_df <- rbind(resize_df, aux)
    
  }
  
  # Keep only threads in [0.7,1]
  
  keep_thread = resize_df[resize_discretized_bin_label >= 0.7]$root_submission
  keep_df = df[root_submission %in% keep_thread, ]
  
  rm(df, aux, tmp)
  gc()
  
  write_parquet(keep_df,
                paste0(
                  "data/validation_dataset_ge_07/",
                  substr(i, 1, nchar(i) - 8),
                  "_ge_07.parquet"
                ))
  message("Done: ", i)
  
}
