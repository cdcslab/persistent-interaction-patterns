
library(arrow)
library(data.table)
library(xtable)

dt_perspective = read_parquet("data/Results/extended_data_figure_6/table_interactions_validation_perspective.parquet") %>%
     rename("Dataset" = "social_topic",
            "Perspective" = "p") %>% arrange(Dataset)

dt_imsypp = read_parquet("data/Results/extended_data_figure_6/table_interactions_validation_imsypp.parquet") %>%
     rename("Dataset" = "social_topic",
            "Imsypp" = "p") %>% arrange(Dataset)

dt_detoxify = read_parquet("data/Results/extended_data_figure_6/table_interactions_validation_detoxify.parquet") %>%
     rename("Dataset" = "social_topic",
            "Detoxify" = "p") %>% arrange(Dataset)

data_for_table = merge(dt_perspective,dt_detoxify) %>%
                 merge(dt_imsypp)

print(xtable(data_for_table, digits = 3), include.rownames = F)


