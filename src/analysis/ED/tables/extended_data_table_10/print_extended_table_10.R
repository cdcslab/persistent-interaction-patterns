library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(trend)
library(xtable)

# Print xtable

all_data = read_parquet("data/Results/data_for_extended_data_table_10.parquet")

# Put the table in the paper form

all_data$social = factor(all_data$social, 
                          levels = c("Facebook","Gab","Reddit","Telegram","Twitter","Usenet",
                                      "Voat","YouTube"))
all_data = all_data[order(social),]

table_to_plot = all_data[,.(social_topic,trend,slope_regression,p_regression)] %>%
                mutate(slope_regression = slope_regression*10^3)

# Print the table as latex

xtable(table_to_plot, digits=3)
