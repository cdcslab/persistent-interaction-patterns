library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(trend)
library(xtable)
source("functions/binning_functions.R")
source("functions/apply_mk_and_regression.R")
source("functions/unify_dataset_columns.R")

# Print xtable

all_data = read_parquet("data/Results/data_for_extended_data_table_1.parquet")

# Put the table in the paper form

all_data$social = factor(all_data$social, 
                          levels = c("Facebook","Gab","Reddit","Telegram","Twitter","Usenet",
                                      "Voat","YouTube"))
all_data = all_data[order(social),]
all_data = all_data %>% mutate(z_score = (slope_regression - mean_slopes)/sd_slopes)

table_to_plot = all_data[,.(social_topic,trend,slope_regression,p_regression,
                            mean_slopes, sd_slopes, z_score, perc_increasing,perc_ambigous,trend_16,trend_26)] %>%
                mutate(slope_regression = slope_regression*10^3,
                       mean_slopes = mean_slopes*10^3,
                       sd_slopes = sd_slopes*10^3,
                       z_score = ifelse(z_score > 10, ">10",as.character(z_score)))

# Print the table as latex

print(xtable(table_to_plot, digits = 3), include.rownames = F)
