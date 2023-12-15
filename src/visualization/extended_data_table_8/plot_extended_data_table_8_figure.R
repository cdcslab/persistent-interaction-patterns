
library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(patchwork)

all_data = read_parquet("data/Results/extended_data_table_8/data_for_plot_engagement_vs_toxicity.parquet")

pdf(file = "figures/extended_data_table_8_plot.pdf", width = 8, height = 4)

ggplot(all_data, aes(x = toxicity_lin_bin, y = normalized_engagement,
                     group = topic, col = topic)) +
  geom_line(linewidth = 0.6) + theme_classic() + ylim(0,1) +
  scale_x_discrete(breaks = c(0,0.25,0.5,0.75,1)) +
  labs(x = "Toxicity", y = "Likes/upvotes", col = "Topic") +
  facet_wrap(.~social, nrow = 1)

dev.off()
