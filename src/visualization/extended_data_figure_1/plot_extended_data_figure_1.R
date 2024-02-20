library(ggplot2)
library(ggpubr)
library(scales)
library(patchwork)
library(arrow)
library(dplyr)
library(stringr)
library(data.table)

group.colors = c("Brexit" = "#0066CC", "News" = "#FF9933", "Vaccines" = "#339900",
                                "Feed" = "red", "Climate Change" = "purple",
                                "Conspiracy" = "#663300", "Science" = "#FF66CC",
                                "Politics" = "gray", "Talk" = "#CCCC00")

##########################
# Plot size distribution #
##########################

all_data_thread_size = read_parquet("data/Results/extended_data_figure_1/data_for_plot_thread_size_distribution_except_fb_news.parquet") %>% setDT()
all_data_thread_size$topic = str_to_title(all_data_thread_size$topic)

# fb_news_data = read_parquet("data/Results/extended_data_figure_1/facebook_news_data_for_plot_thread_size_distribution.parquet") %>%
#                rename("thread_size" = "n_comments", "count" = "n_posts" )
# fb_news_data = fb_news_data[,c("topic","thread_size","count","social")]
# 
# all_data_thread_size = rbind(all_data_thread_size, fb_news_data)
all_data_thread_size$social = factor(all_data_thread_size$social, 
                    levels = c("Usenet","Facebook","Gab","Reddit","Telegram","Twitter","Voat","Youtube"))
all_data_thread_size[social == "Youtube", "social"] = "YouTube"

p1 = ggplot(all_data_thread_size , aes(x = thread_size, 
                     y = count,
                     col = topic, group = topic)) + 
  theme_classic() + theme(strip.background = element_blank(),
        text = element_text(size = 15)) +
  geom_point(size = 0.3, alpha = 0.6) + facet_wrap(.~ social, nrow = 2) +
  scale_x_log10(labels=trans_format('log10',math_format(10^.x))) + 
  scale_y_log10(labels=trans_format('log10',math_format(10^.x))) +
  labs(x = "Number of comments",
       y = "Number of posts", col = "Topic") +
  scale_color_manual(values = group.colors) +
  guides(colour = guide_legend(override.aes = list(alpha = 1)))

###################################
# Plot user lifetime distribution #
###################################

all_data_user_lifetime = read_parquet("data/Results/extended_data_figure_1/data_for_plot_user_lifetime_distribution.parquet") %>%
               mutate(lifetime = as.numeric(lifetime))

# fb_news_data = read_parquet("data/Results/extended_data_figure_1/facebook_news_data_for_plot_user_lifetime_distribution.parquet") %>%
#                mutate(lifetime = as.numeric(lifetime)*86400)
# 
# fb_news_data = fb_news_data[,c("topic","lifetime","count","social")] 
# all_data_user_lifetime = rbind(all_data_user_lifetime, fb_news_data)

all_data_user_lifetime$social = factor(all_data_user_lifetime$social, 
                    levels = c("Usenet","Facebook","Gab","Reddit","Telegram","Twitter","Voat","Youtube"))
all_data_user_lifetime[social == "Youtube", "social"] = "YouTube"

p2 = ggplot(all_data_user_lifetime, aes(x = as.numeric(lifetime)/86400, 
                     y = count,
                     col = topic, group = topic)) + 
     theme_classic() + theme(strip.background = element_blank(),
        text = element_text(size = 15)) + 
     geom_point(size = 0.3, alpha = 0.6) + facet_wrap(.~ social, nrow = 2) +
     scale_x_log10(labels=trans_format('log10',math_format(10^.x))) + 
  scale_y_log10(labels=trans_format('log10',math_format(10^.x))) +
  labs(x = "Lifetime",
       y = "Number of users", col = "Topic") +
  scale_color_manual(values = group.colors)  +
  guides(colour = guide_legend(override.aes = list(alpha = 1)))

#####################################
# Plot thread lifetime distribution #
#####################################

all_data_thread_lifetime = read_parquet("data/Results/extended_data_figure_1/data_for_plot_thread_lifetime_distribution.parquet") %>%
               mutate(lifetime = as.numeric(lifetime))

# fb_news_data = read_parquet("data/Results/extended_data_figure_1/facebook_news_data_for_plot_thread_lifetime_distribution.parquet") %>%
#                mutate(lifetime = as.numeric(lifetime)*86400)
# 
# fb_news_data = fb_news_data[,c("topic","lifetime","count","social")] 
# all_data_thread_lifetime = rbind(all_data_thread_lifetime, fb_news_data)

all_data_thread_lifetime[social == "Youtube", "social"] = "YouTube"
all_data_thread_lifetime$social = factor(all_data_thread_lifetime$social, 
                    levels = c("Usenet","Facebook","Gab","Reddit","Telegram","Twitter","Voat","YouTube"))

p3 = ggplot(all_data_thread_lifetime, aes(x = as.numeric(lifetime)/86400, 
                     y = count,
                     col = topic, group = topic)) + 
  theme_classic() + theme(strip.background = element_blank(),
        text = element_text(size = 15)) +
  geom_point(size = 0.3, alpha = 0.6) + facet_wrap(.~ social, nrow = 2) +
  scale_x_log10(labels=trans_format('log10',math_format(10^.x))) + 
  scale_y_log10(labels=trans_format('log10',math_format(10^.x))) +
  labs(x = "Lifetime",
       y = "Number of posts", col = "Topic") +
  scale_color_manual(values = group.colors) +
  guides(colour = guide_legend(override.aes = list(alpha = 1)))

##############
# Final plot #
##############

pdf(file = "figures/extended_data_figure_1.pdf", width = 9, height = 12)

p1 + p2 + p3 + plot_layout(nrow = 3, guides = "collect") +
     plot_annotation(tag_levels = list(c("(a)","(b)","(c)")))  

dev.off()
