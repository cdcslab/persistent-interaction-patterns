rm(list = ls())
gc()

library(ggplot2)
library(patchwork)
library(arrow)
library(stringr)
library(data.table)

all_data = read_parquet("data/Results/extended_data_figure_8/data_for_plot_short_conversation.parquet") %>%
            setDT()
all_data$social = str_to_title(all_data$social)
all_data[social == "Facebook_news","social"] = "Facebook"
all_data$social_and_topic = paste(all_data$social,all_data$topic, sep = " ")

# Box plot

pdf(file = "figures/extended_data_figure_8.pdf", width = 7, height = 7)

ggplot(all_data, aes(x = social_and_topic, y = toxicity_score, fill = comment_position)) +
        geom_boxplot(alpha = 0.6, outlier.alpha = 0.005, outlier.size = 0.005) + coord_flip() +
        labs(y = "Toxicity score", x = "", fill = "") + theme_classic() +
        theme(text = element_text(size = 15))

dev.off()
