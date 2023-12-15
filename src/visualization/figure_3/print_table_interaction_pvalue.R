
library(arrow)
library(data.table)
library(xtable)

dt = read_parquet("data/Results/figure_3/data_for_table_interactions.parquet") %>%
     rename("Dataset" = "social_topic") %>% arrange(Dataset)

print(xtable(dt, digits = 3), include.rownames = F)


