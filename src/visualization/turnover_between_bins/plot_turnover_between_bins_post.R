library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)

group.colors = c(
  "Brexit" = "#0066CC",
  "News" = "#FF9933",
  "Vaccines" = "#339900",
  "Feed" = "red",
  "Climate Change" = "purple",
  "Conspiracy" = "#663300",
  "Science" = "#FF66CC",
  "Politics" = "gray",
  "Talk" = "#CCCC00"
)

all_data = read_parquet("data/Results/turnover_between_bins/data_for_plot_turnover_post.parquet")

all_data$social = factor(
  all_data$social,
  levels = c(
    "Usenet",
    "Facebook",
    "Gab",
    "Reddit",
    "Telegram",
    "Twitter",
    "Voat",
    "YouTube"
  )
)

p = ggplot(all_data,
           aes(
             x = lin_bin,
             y = mean_j,
             col = topic,
             fill = topic,
             group = topic
           )) +
  geom_line(linewidth = 0.6) + theme_classic() +
  facet_wrap(. ~ social, nrow = 2) +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL),
              alpha = 0.2,
              show.legend = FALSE) +
  ylim(0, NA) +
  labs(x = "Normalized comment position",
       y = "Jaccard index",
       col = "Topic") +
  theme(strip.background = element_blank(),
        text = element_text(size = 15)) +
  scale_color_manual(values = group.colors) +
  scale_fill_manual(values = group.colors) +
  scale_x_continuous(breaks = c(0, 0.5, 1)) +
  guides(fill = 'none')

pdf(file = "figures/turnover_between_bins_post.pdf",
    width = 8,
    height = 4)

p

dev.off()
