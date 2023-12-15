library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(trend)
library(xtable)

# Print xtable

all_data = read_parquet("data/Results/extended_data_table_9.parquet")

# Put the table in the paper form

all_data$social = factor(all_data$social, 
                          levels = c("Facebook","Gab","Reddit","Telegram","Twitter","Usenet",
                                      "Voat","YouTube"))
all_data = all_data[order(social),]

table_to_plot = all_data[,.(social_topic,trend_perspective,slope_regression_perspective,p_regression_perspective,
                            trend_detoxify,slope_regression_detoxify,p_regression_detoxify,
                            trend_imsypp,slope_regression_imsypp,p_regression_imsypp)] %>%
                mutate(slope_regression_perspective = slope_regression_perspective*10^3,
                       slope_regression_detoxify = slope_regression_detoxify*10^3,
                       slope_regression_imsypp = slope_regression_imsypp*10^3)

# Print the table as latex

print(xtable(table_to_plot, digits=3), include.rownames = F)
