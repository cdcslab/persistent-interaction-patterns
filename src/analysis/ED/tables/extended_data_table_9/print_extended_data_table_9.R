rm(list = ls())
gc()

library(data.table)
library(dplyr)
library(arrow)
library(xtable)

all_data = read_parquet("data/Results/data_extended_data_table_9.parquet")

print(xtable(all_data), include.rownames = F)
