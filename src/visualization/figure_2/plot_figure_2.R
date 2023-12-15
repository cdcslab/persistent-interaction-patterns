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

all_data_toxicity_vs_thread_size = read_parquet("data/Results/figure_2/data_for_plot_toxicity_threads_by_bin.parquet")
all_data_toxicity_vs_thread_size[topic == "Climatechange", "topic"] = "Climate Change"

all_data_toxicity_vs_thread_size[topic == "Greatawakening", "topic"] = "Conspiracy"

# fb_news_data = read_parquet("data/Results/figure_2/facebook_news_toxicity_percentage_binned.parquet")
#
# tmp <- unlist(fb_news_data$CI_toxicity)
#
# fb_news_data <- fb_news_data %>%
#     mutate(CI_inf = tmp[seq(1, length(tmp) - 1, by = 2)],
#       CI_sup = tmp[seq(2, length(tmp), by = 2)],
#       CI_toxicity = NULL, social = "Facebook"
#     )
#
# all_data_toxicity_vs_thread_size = rbind(all_data_toxicity_vs_thread_size, fb_news_data)
# all_data_toxicity_vs_thread_size$topic = factor(all_data_toxicity_vs_thread_size$topic,
#                     levels = c("Brexit","News","Vaccines","Feed","Climate Change",
#                                "Conspiracy","Science","Politics","Talk"))

p1 = ggplot(
  all_data_toxicity_vs_thread_size,
  aes(
    x = resize_discretized_bin_label,
    y = mean_t,
    group = topic,
    color = topic,
    fill = topic
  )
) +
  geom_line(linewidth = 0.6) + facet_wrap(. ~ social, nrow = 2) +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL),
              alpha = 0.15,
              show.legend = FALSE) +
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
       y = "Average thread toxicity",
       col = "Topic") +
  scale_x_discrete(breaks = c(0, 0.5, 1)) +
  guides(fill = "none") +
  scale_color_manual(values = group.colors) +
  scale_fill_manual(values = group.colors)

pdf(file = "figures/figure_2.pdf",
    width = 8,
    height = 4)

p1

dev.off()
