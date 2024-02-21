library(data.table)
library(ggplot2)
library(patchwork)
library(dplyr)
library(arrow)

# Plot perspective

all_data_perspective = read_parquet("data/Results/extended_data_figure_5/data_for_plot_validation_toxicity_threads_by_bin_perspective.parquet")

p1 = ggplot(all_data_perspective, aes(x = resize_discretized_bin_label,
                              y = mean_t,
                              group = topic, color = topic, fill = topic)) +
  geom_line(linewidth = 0.6) + facet_wrap(.~ social, nrow = 2) +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL), 
              alpha = 0.15, show.legend = FALSE) +
  theme_classic() +
  theme(text = element_text(size = 15)) +
  labs(x = "Normalized thread length",
       y = "Thread toxicity",
       col = "Topic", title = "Perspective") +
       scale_x_discrete(breaks = c(0,0.5,1)) +
       guides(fill = 'none') +
       theme(strip.background = element_blank(),
        text = element_text(size = 15)) +
        scale_y_continuous(breaks = c(0,0.1,0.2,0.3))

# Plot Detoxify

all_data_detoxify = read_parquet("data/Results/extended_data_figure_5/data_for_plot_validation_toxicity_threads_by_bin_detoxify.parquet")

p2 = ggplot(all_data_detoxify, aes(x = resize_discretized_bin_label,
                              y = mean_t,
                              group = topic, color = topic, fill = topic)) +
  geom_line(linewidth = 0.6) + facet_wrap(.~ social, nrow = 2) +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL), 
              alpha = 0.15, show.legend = FALSE) +
  theme_classic() +
  theme(text = element_text(size = 15)) +
  labs(x = "Normalized thread length",
       y = "Thread toxicity",
       col = "Topic", title = "Detoxify") +
       scale_x_discrete(breaks = c(0,0.5,1)) +
       guides(fill = 'none') +
       theme(strip.background = element_blank(),
        text = element_text(size = 15))

# Plot IMSYPP

all_data_imsypp = read_parquet("data/Results/extended_data_figure_5/data_for_plot_validation_toxicity_threads_by_bin_imsypp.parquet")

p3 = ggplot(all_data_imsypp, aes(x = resize_discretized_bin_label,
                              y = mean_t,
                              group = topic, color = topic, fill = topic)) +
  geom_line(linewidth = 0.6) + facet_wrap(.~ social, nrow = 2) +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL), 
              alpha = 0.15, show.legend = FALSE) +
  theme_classic() +
  theme(text = element_text(size = 15)) +
  labs(x = "Normalized thread length",
       y = "Thread toxicity",
       col = "Topic", title = "Imsypp") +
       scale_x_discrete(breaks = c(0,0.5,1)) +
       guides(fill = 'none') +
       theme(strip.background = element_blank(),
        text = element_text(size = 15))

pdf(file = "figures/extended_data_figure_5.pdf", width = 8, height = 12)

p1 + p2 + p3 + plot_layout(nrow = 3, guides = "collect") +
     plot_annotation(tag_levels = list(c("(a)","(b)","(c)")))

dev.off()
