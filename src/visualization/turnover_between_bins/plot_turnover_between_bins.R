library(data.table)
library(ggplot2)
library(patchwork)
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

# Plot toxicity vs thread size

all_data = read_parquet("data/Results/turnover_between_bins/data_for_plot_turnover.parquet")
all_data[type == "first", "type"] = "Comparison with first bin"
all_data[type == "shifting", "type"] = "Comparison between consecutive bins"
all_data[topic == "Climatechange", "topic"] = "Climate Change"

all_data[topic == "Greatawakening", "topic"] = "Conspiracy"

p1 = ggplot(all_data,
            aes(
              x = bin,
              y = value,
              group = topic,
              color = topic,
              fill = topic
            )) +
  geom_line(linewidth = 0.6) + facet_grid(vars(social), vars(type)) +
  theme_classic() +
  theme(
    text = element_text(size = 15),
    strip.background = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    axis.line = element_line(colour = "black")
  ) +
  labs(x = "Normalized thread length",
       y = "Jaccard Index",
       col = "Topic") +
  scale_x_continuous(breaks = c(0, 0.5, 1)) +
  guides(fill = "none") +
  scale_color_manual(values = group.colors) +
  scale_fill_manual(values = group.colors)

pdf(file = "figures/turnover_between_bins.pdf",
    width = 8,
    height = 8)

p1

dev.off()
