library(data.table)
library(ggplot2)
library(patchwork)
library(dplyr)
library(arrow)
library(stringr)

group.colors = c("Brexit" = "#0066CC", "News" = "#FF9933", "Vaccines" = "#339900",
                                "Feed" = "red", "Climate Change" = "purple",
                                "Conspiracy" = "#663300", "Science" = "#FF66CC",
                                "Politics" = "gray", "Talk" = "#CCCC00")

# Lifetime of threads

all_data_lifetime_thread = read_parquet("data/Results/extended_data_figure_4/data_for_plot_toxicity_vs_lifetime_thread.parquet")

# fb_news_data = read_parquet("data/Results/extended_data_figure_4/facebook_news_data_for_figure_4b.parquet") %>%
#                mutate(topic = "News", social = "Facebook")
# fb_news_data = fb_news_data[,c("topic","resize_discretized_bin_label","mean_toxicity","CI_inf","CI_sup","social")]
# all_data_lifetime_thread = rbind(all_data_lifetime_thread, fb_news_data)

all_data_lifetime_thread$topic = str_to_title(all_data_lifetime_thread$topic)
all_data_lifetime_thread[social == "Youtube","social"] = "YouTube"


p1 = ggplot(all_data_lifetime_thread, aes(x = resize_discretized_bin_label, 
                     y = mean_toxicity,
                     col = topic, fill = topic, group = topic)) + 
  theme_classic() +
  geom_line(linewidth = 0.6) + facet_wrap(.~ social, nrow = 2) +
  labs(x = "Lifetime (days)",
       y = "Thread toxicity", col = "Topic") +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL), 
              alpha = 0.15, show.legend = FALSE) +
  scale_x_discrete(breaks = c(0,0.5,1)) + ylim(0,NA) +
  theme(strip.background = element_blank(),
        text = element_text(size = 15)) +
        scale_color_manual(values = group.colors) +
        scale_fill_manual(values = group.colors) +
        guides(fill = 'none')

# Lifetime of users

all_data_lifetime_user = read_parquet("data/Results/extended_data_figure_4/toxicity_vs_lifetime_user_all_dataset.parquet")
# fb_news_data = read_parquet("data/Results/extended_data_figure_4/facebook_news_data_for_figure_4a.parquet") %>%
#                mutate(topic = "News", social = "Facebook")
# fb_news_data = fb_news_data[,c("topic","resize_discretized_bin_label","mean_toxicity","CI_inf","CI_sup","social")]
# all_data_lifetime_user = rbind(all_data_lifetime_user, fb_news_data)

all_data_lifetime_user$topic = str_to_title(all_data_lifetime_user$topic)
all_data_lifetime_user[social == "Youtube","social"] = "YouTube"

p2 = ggplot(all_data_lifetime_user, aes(x = resize_discretized_bin_label, 
                     y = mean_toxicity,
                     col = topic, fill = topic, group = topic)) + 
  theme_classic() +
  geom_line(linewidth = 0.6) + facet_wrap(.~ social, nrow = 2) +
  labs(x = "Lifetime (days)",
       y = "User toxicity", col = "Topic") +
  geom_ribbon(aes(ymin = CI_inf, ymax = CI_sup, col = NULL), 
              alpha = 0.15, show.legend = FALSE) +
  scale_x_discrete(breaks = c(0,0.5,1)) + ylim(0,NA) +
  theme(strip.background = element_blank(),
        text = element_text(size = 15)) +
        scale_color_manual(values = group.colors) +
        scale_fill_manual(values = group.colors) + 
        guides(fill = 'none')

# Join plots

pdf(file = "figures/extended_data_figure_4.pdf", width = 8, height = 8)

p2 + p1 + plot_layout(nrow = 2, guides = "collect") +
          plot_annotation(tag_levels = list(c("(a)","(b)")))  

dev.off()
