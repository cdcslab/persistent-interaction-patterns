library(data.table)
library(dplyr)
library(arrow)
library(xtable)

all_data = read_parquet("data/Results/data_extended_data_table_6.parquet")
all_data = all_data[,c("social_topic","threads","min_size","max_size")]

print(xtable(all_data), include.rownames = F)
