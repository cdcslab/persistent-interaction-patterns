library(dplyr)
library(tibble)
library(arrow)
library(stringr)
library(data.table)
library(ggplot2)

rm(list = ls())
gc()

source("src/utils/binning_functions.R")
source("src/utils/compute_CI.R")
# Variables ####
social_name <- "twitter"
topic_name <- "news"

social_topic_name <- ifelse(social_name == "gab",
                            social_name,
                            paste(social_name, topic_name, sep = "_"))

folder <-
  file.path("data/Results/figure_4", str_to_title(social_name))

figures_folder <- "figures"

input_filename <- file.path(folder,
                            paste(social_topic_name,
                                  "controversy_stats.parquet",
                                  sep = "_"))

controversy_quantities_by_bin_filename <- file.path(
  folder,
  paste(
    social_topic_name,
    "average_controversy_quantities_by_bin.parquet",
    sep = "_"
  )
)

overall_correlations_filename <- file.path(folder,
                                           paste(social_topic_name,
                                                 "overall_correlations.parquet",
                                                 sep = "_"))

# Read data ####
n_bin <- 21

message("Reading ", input_filename)
df <- read_parquet(input_filename)
df$post_id <- as.character(df$post_id)
df <- df %>%
  rename(thread_length = number_of_comments) %>%
  setDT()

# Perform analysis ####
min_thread_length <- log10(min(df$thread_length))
max_thread_length <- log10(max(df$thread_length))

bin_edges <- 10 ^ seq(min_thread_length, max_thread_length,
                      length.out = n_bin + 1)
cat(bin_edges, "\n")

# Discrete labels to assign to each bin

discretized_bin_labels <- seq(0, 1,
                              length.out = n_bin)

# Assign each thread to its (labelled) bin
df$discretized_bin_label <- cut(
  df$thread_length,
  breaks = bin_edges,
  right = T,
  include.lowest = T,
  labels = discretized_bin_labels,
  ordered_result = TRUE
)

# Since some approximation errors could arise in the first and last bin
# I use the following lines to be sure that they are correctly assigned
df[thread_length == min(thread_length), "discretized_bin_label"] = factor(0)
df[thread_length == max(thread_length), "discretized_bin_label"] = factor(1)

# Modify the binning -> the last bin must have 50 element
df_binned <- resize_last_bin(df, n_bin = n_bin)

df_averages_by_bin <- df_binned %>% setDT()

df_avg_toxicity <- df_averages_by_bin[, .(mean_toxicity_percentage_by_bin = mean(percentage_of_toxic_comments, na.rm = T),
                                             CI_mean_toxicity_percentage_by_bin = lapply(.SD, compute_CI)),
                           by = .(resize_discretized_bin_label),
                           .SDcols = "percentage_of_toxic_comments"]

df_avg_leaning <- df_averages_by_bin[, .(mean_sd_leaning_by_bin = mean(sd_leaning, na.rm = T),
                                         CI_mean_sd_leaning_by_bin = lapply(.SD, compute_CI)),
                                      by = .(resize_discretized_bin_label),
                                      .SDcols = "sd_leaning"]

df_avg_sentiment <- df_averages_by_bin[, .(mean_sentiment_score_by_bin = mean(sd_sentiment_score, na.rm = T)),
                                     by = .(resize_discretized_bin_label)]

df_averages_by_bin <- df_avg_toxicity %>% 
  inner_join(df_avg_leaning, by = "resize_discretized_bin_label") %>% 
  inner_join(df_avg_sentiment, by = "resize_discretized_bin_label")

tmp_toxicity <- unlist(df_averages_by_bin$CI_mean_toxicity_percentage_by_bin)
tmp_leaning <- unlist(df_averages_by_bin$CI_mean_sd_leaning_by_bin)
# tmp_sentiment <- unlist(df_avg_sentiment$CI_mean_sentiment_score)

df_averages_by_bin <- df_averages_by_bin %>%
  mutate(CI_inf_toxicity = tmp_toxicity[seq(1, length(tmp_toxicity) - 1, by = 2)],
         CI_sup_toxicity = tmp_toxicity[seq(2, length(tmp_toxicity), by = 2)],
         CI_inf_leaning = tmp_leaning[seq(1, length(tmp_leaning) - 1, by = 2)],
         CI_sup_leaning = tmp_leaning[seq(2, length(tmp_leaning), by = 2)],)

write_parquet(df_averages_by_bin,
              controversy_quantities_by_bin_filename)

# Perform correlations
pearson_cor <- cor(
  df_averages_by_bin$mean_toxicity_percentage_by_bin,
  df_averages_by_bin$mean_sd_leaning_by_bin,
  method = "pearson"
)

pearson_cor_test <- cor.test(df_averages_by_bin$mean_toxicity_percentage_by_bin[1:18],
         df_averages_by_bin$mean_sd_leaning_by_bin[1:18],
         method = "pearson")
pearson_cor_test
pearson_cor_test
spearman_cor <- cor(
  df_averages_by_bin$mean_toxicity_percentage_by_bin,
  df_averages_by_bin$mean_sd_leaning_by_bin,
  method = "spearman"
)


kendall_cor <- cor(
  df_averages_by_bin$mean_toxicity_percentage_by_bin,
  df_averages_by_bin$mean_sd_leaning_by_bin,
  method = "kendall"
)

message("Pearson correlation: ", pearson_cor)
message("Spearman correlation: ", spearman_cor)
message("Kendall correlation: ", kendall_cor)

# Correlation between sentiment and toxicity
toxicity_sentiment_pearson_cor <- cor(
  df_averages_by_bin$mean_toxicity_percentage_by_bin,
  df_averages_by_bin$mean_sentiment_score_by_bin,
  method = "pearson"
)

message("Pearson correlation between toxicity and sentiment: ", toxicity_sentiment_pearson_cor)

df_overall_correlations <-
  tibble(
    social = str_to_title(social_name),
    topic = str_to_title(topic_name),
    pearson = pearson_cor,
    spearman = spearman_cor,
    kendall = kendall_cor
  )

write_parquet(df_overall_correlations,
              overall_correlations_filename)

# Plot correlation by number of bins considered ####
df_averages_by_bin$resize_discretized_bin_label <-
  as.numeric(df_averages_by_bin$resize_discretized_bin_label)
correlations <- c()
intervals_considered <- c()
for (i in 10:n_bin)
{
  cor_interval <- cor(
    df_averages_by_bin[1:i, ]$mean_toxicity_percentage_by_bin,
    df_averages_by_bin[1:i, ]$mean_sd_leaning_by_bin
  )
  
  correlations <- append(cor_interval, correlations)
  intervals_considered <- append(i, intervals_considered)
  message("Intervals considered: ", i, " Correlation: ", cor_interval)
}

df_averages_by_bin_by_intervals_considered <- tibble(correlations,
                                                     intervals_considered)
plot_correlations_by_interval <- ggplot(
  df_averages_by_bin_by_intervals_considered,
  aes(x = intervals_considered, y = correlations)
) +
  geom_line() +
  geom_point() +
  ylim(-1, 1) +
  scale_x_continuous(breaks = 10:n_bin) +
  theme_classic() +
  labs(x = "Number of bins considered",
       y = "Correlation")

plot_correlations_by_interval

output_filename_correlations_by_bin <- file.path(
  figures_folder,
  paste(
    social_topic_name,
    "correlation_by_n_intervals_considered.pdf",
    sep = "_"
  )
)

ggsave(
  plot_correlations_by_interval,
  file = output_filename_correlations_by_bin,
  device = "pdf",
  unit = "cm",
  width = 20,
  height = 20
)

