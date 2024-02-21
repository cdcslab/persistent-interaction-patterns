rm(list = ls())
gc()


library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(logr)
library(stringr)
source("src/utils/binning_functions.R")

# Functions ####

load_data_frame <- function(input_filename) {
  input_format <-
    tolower(tail(strsplit(input_filename, "\\.")[[1]], 1))
  
  if (input_format == "csv") {
    df_data <- read.csv(input_filename)
  } else if (input_format == "parquet") {
    df_data <- read_parquet(input_filename)
  } else {
    cat("Error: Unsupported input format\n", file = stderr())
    return(NULL)
  }
  
  return(df_data)
}

compute_CI <- function(x) {
  result = t.test(x)
  return(as.numeric(result$conf.int))
}

# Variables ####
n_bin <- 21
bin_threshold <- 50
social_media_name <- "voat"
thread_identifier <- "root_submission"
labeled_folder <-
  file.path("data/Labeled",
            str_to_title(social_media_name))

if (social_media_name == "facebook")
{
  input_filename <- file.path(
    labeled_folder,
    paste(
      social_media_name,
      "labeled_data_unified_except_news.parquet",
      sep = "_"
    )
  )
  output_filename <-
    paste(social_media_name,
          "toxicity_percentage_binned_except_news.parquet",
          sep = "_")
  
  output_threshold_filename <-
    paste(social_media_name,
          "comments_with_bin_ge_07_except_news.parquet",
          sep = "_")
  
  
} else {
  input_filename <- file.path(
    labeled_folder,
    paste(social_media_name, "labeled_data_unified.parquet", sep = "_")
  )
  
  output_filename <-
    paste(social_media_name, "toxicity_percentage_binned", sep = "_")
  
  output_threshold_filename <-
    paste(social_media_name,
          "comments_with_bin_ge_07",
          sep = "_")
}

labeled_folder <-
  file.path("data/Labeled",
            str_to_title(social_media_name))

output_folder <-
  "data/Results/figure_2"

comments_with_binned_threshold_folder <-
  "data/Processed/BinFiltering/"

output_format <- "parquet"


# Load data ####
df_data <- load_data_frame(input_filename) %>%
  setDT()

df_data$topic <- str_to_title(df_data$topic)
df_data$topic <- ifelse(df_data$topic == "Greatawakening", "Conspiracy", df_data$topic)

# Define toxic comments
df_data[is.na(toxicity_score), "toxicity_score"] <- 0
df_data$is_toxic = ifelse(df_data$toxicity_score > 0.6, T, F)


df_data <- df_data %>%
  select(-text)

# Compute the length of each thread
df <- df_data[, .(thread_length = .N,
                  toxicity_percentage = sum(is_toxic) / .N),
              by = .(eval(parse(text = thread_identifier)),
                     topic)]

colnames(df)[colnames(df) == "parse"] <- thread_identifier

# Select column of interest
df <- df[, .(eval(parse(text = thread_identifier)),
             thread_length,
             toxicity_percentage,
             topic)]
df <- df[order(thread_length, topic)]
colnames(df)[colnames(df) == "V1"] <- thread_identifier


# Binning for the thread length
df[,
   discretized_bin_label := sapply(.SD, log_bin, n_bin),
   by = .(topic),
   .SDcols = "thread_length"]

# Resize last bin ####
df_binned <- setDT(NULL)

for (i in unique(df$topic)) {
  cat(paste("Topic", i, "\n\n"))
  aux <- resize_last_bin(df[topic == i])
  df_binned <- rbind(df_binned,
                     aux)
}


df_toxicity_percentage_binned <-
  df_binned[, .(mean_t = mean(toxicity_percentage),
                CI_toxicity = lapply(.SD,
                                     compute_CI)),
            by = .(topic,
                   resize_discretized_bin_label),
            .SDcols = "toxicity_percentage"]


df_data_with_bin_after_threshold <-
  as.data.frame(df_binned[resize_discretized_bin_label >= 0.7])

df_data_with_bin_after_threshold <- df_data %>%
  inner_join(df_data_with_bin_after_threshold,
             by = c(thread_identifier, "topic"))

# Write results ####

# Toxicity percentage binned
output_filename <- file.path(output_folder,
                             paste(output_filename, output_format, sep = "."))
write_parquet(df_toxicity_percentage_binned, output_filename)

message("Result can be found in ", output_filename, " file")

# Toxicity percentage binned
output_filename <- file.path(
  comments_with_binned_threshold_folder,
  paste(output_threshold_filename, output_format, sep = ".")
)
write_parquet(df_data_with_bin_after_threshold, output_filename)

message("Comments with discretized bin >= 0.7 can be found in",
        output_filename,
        "file")
