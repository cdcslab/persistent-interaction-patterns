library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(patchwork)
library(scales)

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

# Plot distributions

all_data_distributions = read_parquet("data/Results/figure_1/data_for_plot_user_comments_distribution.parquet")
all_data_distributions[topic == "Climatechange", "topic"] = "Climate Change"
all_data_distributions[topic == "Greatawakening", "topic"] = "Conspiracy"

# fb_news_data = read_parquet("data/Results/figure_1/facebook_news_n_users_by_n_comments.parquet") %>%
#   rename("count" = "n_users") %>% setDT()
#
# fb_news_data = fb_news_data[, c("topic", "n_comments", "count", "social")]
# all_data_distributions = rbind(fb_news_data, all_data_distributions)

all_data_distributions$social = factor(
  all_data_distributions$social,
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

p1 = ggplot(all_data_distributions ,
            aes(
              x = n_comments,
              y = count,
              col = topic,
              group = topic
            )) +
  theme_classic() + theme_classic() +
  theme(
    legend.position = 'none',
    strip.background = element_blank(),
    text = element_text(size = 15)
  ) +
  geom_point(size = 0.3, alpha = 0.1) + facet_wrap(. ~ social, nrow = 2) +
  scale_x_log10(labels = trans_format('log10', math_format(10 ^ .x)),
                breaks = c(10 ^ 0, 10 ^ 2, 10 ^ 4)) +
  scale_y_log10(labels = trans_format('log10', math_format(10 ^ .x))) +
  labs(x = "Number of comments",
       y = "Number of users", col = "Topic") +
  scale_color_manual(values = group.colors)


# Plot participation

all_data_participation = read_parquet("data/Results/figure_1/data_for_plot_participation_vs_bin.parquet")

all_data_participation[topic == "Climatechange", "topic"] = "Climate Change"
all_data_participation[topic == "Greatawakening", "topic"] = "Conspiracy"

p2 = ggplot(
  all_data_participation,
  aes(
    x = lin_bin,
    y = mean_p,
    col = topic,
    group = topic,
    fill = topic
  )
) +
  geom_line(linewidth = 0.6) + theme_classic() +
  theme(strip.background = element_blank(),
        text = element_text(size = 15)) +
  facet_wrap(. ~ social, nrow = 2) +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL),
              alpha = 0.2,
              show.legend = FALSE) +
  labs(x = "Normalized comment position",
       y = "Participation",
       col = "Topic") +
  scale_x_discrete(breaks = c(0, 0.5, 1)) +
  guides(fill = 'none') +
  scale_color_manual(values = group.colors) +
  scale_fill_manual(values = group.colors)

#################
# Plot together #
#################

pdf(file = "figures/figure_1.pdf",
    width = 8,
    height = 8)

p1 + p2 + plot_layout(nrow = 2, guides = "collect") +
  plot_annotation(tag_levels = list(c("(a)", "(b)")))

dev.off()
