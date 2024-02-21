library(arrow)
library(data.table)
library(ggplot2)
library(patchwork)
library(dplyr)

group.colors = c("Brexit" = "#0066CC", "News" = "#FF9933", "Vaccines" = "#339900",
                 "Feed" = "red", "Climate Change" = "purple",
                 "Conspiracy" = "#663300", "Science" = "#FF66CC",
                 "Politics" = "gray", "Talk" = "#CCCC00")

# Plot toxicity vs thread size
all_data_toxicity_vs_thread_size = read_parquet("data/Results/extended_data_figure_5/data_for_plot_toxicity_threads_by_bin_with_05.parquet")
all_data_toxicity_vs_thread_size[topic == "Climatechange","topic"] = "Climate Change"

# fb_news_data = read_parquet("data/Results/extended_data_figure_7/facebook_news_data_for_plot_toxicity_vs_threads_05.parquet")

# all_data_toxicity_vs_thread_size = rbind(all_data_toxicity_vs_thread_size, fb_news_data)

p1 = ggplot(all_data_toxicity_vs_thread_size, 
            aes(x = resize_discretized_bin_label, y = mean_t,
                group = topic, color = topic, fill = topic)) +
  geom_line(linewidth = 0.6) + facet_wrap(.~ social, nrow = 2) +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL), 
              alpha = 0.15, show.legend = FALSE) +
  theme_classic() +
  theme(text = element_text(size = 15),
        strip.background = element_blank()) +
  labs(x = "Normalized thread length",
       y = "Thread toxicity",
       col = "Topic") + scale_color_manual(values = group.colors) +
  scale_fill_manual(values = group.colors) +
  scale_x_discrete(breaks = c(0,0.5,1)) +
  guides(fill = 'none')

# Plot slopes distribution

# data_for_plot_slopes = read_parquet("data/Results/extended_data_figure_7/data_for_plot_toxicity_slopes_05.parquet")

# tmp1 = select(data_for_plot_slopes, -c("toxicity_slopes"))
# tmp1$type = "Participation"
# colnames(tmp1)[3] = "value"

# tmp2 = select(data_for_plot_slopes, -c("participation_slopes"))
# tmp2$type = "Toxicity"
# colnames(tmp2)[3] = "value"

# data_for_plot_slopes = rbind(tmp1,tmp2) %>%
#         mutate(type = factor(type, levels = c("Toxicity","Participation")))

# p2 = ggplot(data_for_plot_slopes, aes(x = type, y = value, fill = type)) +
#   geom_boxplot(col = "black") + 
#   theme_classic() + 
#   labs(y = "Angular coefficient \n values",
#        x = NULL,
#        col = NULL, fill = NULL) + 
#      theme(legend.position = c(0.25,0.25),
#            legend.background = element_rect(size=0.5, 
#            linetype="solid", 
#           colour ="black"), 
#           axis.text.x = element_blank(),
#           text = element_text(size = 15)) +
#           scale_color_manual(values=c("orange","lightblue")) +
#           scale_fill_manual(values=c("orange","lightblue"))

# p2_short = plot_spacer() + p2 + plot_spacer() + plot_layout(widths = c(0.15, 1, 0.15)) 

# Plot correlations participation & toxicity

all_data_correlation_participation_toxicity = read_parquet("data/Results/extended_data_figure_5/data_for_plot_correlations_05.parquet")

p3 = ggplot(all_data_correlation_participation_toxicity, aes(x = topic_and_social, y = correlation,
                                   col = correlation, alpha = abs(correlation))) +
  geom_segment(aes(x = topic_and_social, xend = topic_and_social,
                   y = 0, yend = correlation)) +
  geom_point() +
  coord_flip() +
  theme_bw() +
  theme(legend.position = "right") +
  scale_color_gradient2(midpoint = 0, low = "blue", mid = "white",
                            high = "red", space = "Lab" ) +
  theme(legend.position = "none", text = element_text(size = 15)) +
  labs(x = NULL,
       y = "Correlation between participation \n and toxicity",
       col = NULL, alpha = NULL) + ylim(-1,1)

# Plot correlations between toxic and non-toxic threads

all_data_toxic_non_toxic = read_parquet("data/Results/extended_data_figure_5/data_for_plot_correlation_toxic_non_toxic_threads_05.parquet")

p4 = ggplot(all_data_toxic_non_toxic, aes(x = topic_and_social, y = correlation, 
                                          col = correlation, alpha = abs(correlation))) +
  geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
                   y = 0, yend = correlation)) +
  geom_point() +
  coord_flip() +
  theme_bw() + 
  theme(legend.position = "right") +
  scale_color_gradient2(midpoint = 0, low = "blue", mid = "white",
                        high = "red", space = "Lab" ) +
  theme(legend.position = "none",
        axis.text.y =element_blank(),
        axis.title.y=element_blank(),
        axis.ticks.y=element_blank(),
        text = element_text(size = 15)) +
  labs(x = NULL, 
       y = "Correlation between participation \n in toxic and non toxic threads",
       col = NULL, alpha = NULL) + ylim(-1,1)

###########################
# Aggregate all the plots #
###########################

pdf(file = "figures/extended_data_figure_5.pdf", width = 11, height = 11)

p1 / (p3 + p4) + plot_layout(nrow = 3) + plot_annotation(tag_levels = list(c("(a)","(b)","(c)","(d)"))) +
  plot_layout(height = c(0.75,1,0.75))

dev.off()
