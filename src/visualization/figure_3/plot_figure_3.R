

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(patchwork)
library(cowplot)

# Plot a) ####
# all_data = read_parquet("data/Results/figure_3/all_data_for_correlation_and_participation.parquet")
# social_to_plot = "Twitter"
# topic_to_plot = "Vaccines"
#
# data_for_plot_curves = all_data[topic == topic_to_plot &
#                                   social == social_to_plot,]
#
# p1 = ggplot(data_for_plot_curves, aes(x = as.numeric(lin_bin),
#                                  y = mean_participation)) +
#   scale_y_continuous(breaks = c(0.75,0.8,0.85)) +
#   geom_line(linewidth = 0.6, col = "lightblue") + theme_classic() +
#   labs(x = NULL,
#       y = "Participation") +
#       theme(text = element_text(size = 15))
#
# p2 = ggplot(data_for_plot_curves, aes(x = as.numeric(lin_bin),
#                                  y = mean_toxicity)) +
#   scale_y_continuous(breaks = c(0,0.05,0.1), limits = c(0,0.1)) +
#   geom_line(linewidth = 0.6, col = "orange") + theme_classic() +
#   labs(x = "Normalized comment position",
#        y = "Toxicity") +
#        theme(text = element_text(size = 15))
#
# pa = p1 + p2 + plot_layout(nrow = 2, guides = "collect")
#
#
# # Plot b) ####

data_for_plot_lollipop = read_parquet(
  "data/Results/figure_3/data_for_plot_correlation_participation_toxicity.parquet"
)

pb = ggplot(
  data_for_plot_lollipop,
  aes(
    x = topic_and_social,
    y = correlation,
    col = correlation,
    alpha = abs(correlation)
  )
) +
  geom_segment(aes(
    x = topic_and_social,
    xend = topic_and_social,
    y = 0,
    yend = correlation
  )) +
  geom_point() +
  coord_flip() +
  theme_bw() +
  theme(legend.position = "right") +
  scale_colour_gradient(low = "blue", high = "red") +
  theme(legend.position = "none", text = element_text(size = 15)) +
  labs(x = NULL,
       y = "Correlation between user \n participation and toxicity",
       col = NULL,
       alpha = NULL)
#
# # Plot c)- ####

data_for_plot_slopes = read_parquet("data/Results/figure_3/data_for_plot_slopes.parquet")

tmp1 = select(data_for_plot_slopes, -c("toxicity_slopes"))
tmp1$type = "Participation"
colnames(tmp1)[3] = "value"

tmp2 = select(data_for_plot_slopes, -c("participation_slopes"))
tmp2$type = "Toxicity"
colnames(tmp2)[3] = "value"

data_for_plot_slopes = rbind(tmp1,tmp2) %>%
               mutate(type = factor(type, levels = c("Toxicity","Participation")))

pc = ggplot(data_for_plot_slopes, aes(x = type, y = value, fill = type)) +
  geom_boxplot(col = "black") +
  theme_classic() +
  labs(y = "Angular coefficient values",
       x = "",
       col = NULL, fill = NULL) +
     theme(legend.position = c(0.35,0.25),
           legend.background = element_rect(linewidth=0.5,
           linetype="solid",
          colour ="black"),
          text = element_text(size = 15)) +
          scale_color_manual(values=c("orange","lightblue")) +
          scale_fill_manual(values=c("orange","lightblue"))  +
          scale_x_discrete(labels=c('', ''))

# Plot d) ####

# all_data = read_parquet("data/Results/figure_3/toxic_vs_non_toxic_threads_all_dataset.parquet")
# 
# social_to_plot = "Twitter"
# topic_to_plot = "News"
# 
# data_for_plot_curves = all_data %>%
#   group_by(social, topic) %>% 
#   mutate(lin_bin = as.numeric(lin_bin),
#          is_toxic_thread = as.factor(is_toxic_thread))
# 
# pd = ggplot(
#   data_for_plot_curves,
#   aes(
#     x = lin_bin,
#     y = mean_participation,
#     col = is_toxic_thread,
#     group = is_toxic_thread
#   )
# ) +
#   geom_line(linewidth = 0.6) + theme_classic() +
#   labs(x = "Normalized comment position",
#        y = "Participation", col = NULL) +
#   scale_color_manual(
#     values = c("purple", "green"),
#     labels = c('Non-toxic threads', 'Toxic threads')
#   ) +
#   theme(
#     text = element_text(size = 15),
#     legend.position = c(0.35, 0.25),
#     legend.background = element_rect(
#       linewidth = 0.5,
#       linetype = "solid",
#       colour = "black"
#     )
#   )

# Plot e) ####

data_for_plot_correlation_participation = read_parquet("data/Results/figure_3/data_for_plot_correlation_participation.parquet")

pe = ggplot(
  data_for_plot_correlation_participation,
  aes(
    x = topic_and_social,
    y = correlation,
    col = correlation,
    alpha = abs(correlation)
  )
) +
  geom_segment(aes(
    x = topic_and_social,
    xend = topic_and_social,
    y = 0,
    yend = correlation
  )) +
  geom_point() +
  coord_flip() +
  theme_bw() +
  theme(legend.position = "right") +
  scale_colour_gradient(low = "blue", high = "red") +
  theme(legend.position = "none", text = element_text(size = 15)) +
  labs(x = NULL,
       y = "Correlation between user participation \n in toxic and non toxic threads",
       col = NULL,
       alpha = NULL) + ylim(-1, 1)


###########################
# Aggregate with cowplot #
###########################

# first_row <- plot_grid(pa,
#                       pc,
#                       pd,
#                       nrow = 1,
#                       labels = c("(a)", "(b)", "(c)"))

first_row <- plot_grid(pc,
                      nrow = 1,
                      labels = c("(b)"))

second_row <- plot_grid(pb, pe, nrow = 1, labels = c("(d)", "(e)"))

pdf(file = "figures/figure_3.pdf",
    width = 12,
    height = 12)

# first_row / (pb | pe) / (pc | pf) +
#           plot_annotation(tag_levels = list(c("(a)","","(b)","(c)","(d)","(e)","(f)"))) +
#           plot_layout(height = c(0.75,1.5,1.5)) +
#           theme(aspect.ratio = 1)

plot_grid(first_row,
          second_row,
          nrow = 2,
          rel_heights = c(0.5, 1))

dev.off()
