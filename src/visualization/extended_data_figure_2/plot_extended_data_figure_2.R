library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(patchwork)
library(stringr)
library(scales)

group.colors = c("Brexit" = "#0066CC", "News" = "#FF9933", "Vaccines" = "#339900",
                                "Feed" = "red", "Climate Change" = "purple",
                                "Conspiracy" = "#663300", "Science" = "#FF66CC",
                                "Politics" = "gray", "Talk" = "#CCCC00")

# CCDF 

all_data_toxic_authors = read_parquet("data/Results/extended_data_figure_2/data_for_plot_toxicity_extremely_toxic_authors.parquet")

# fb_news_data = read_parquet("data/Results/extended_data_figure_2/facebook_news_ccdf_extended_figure_3a.parquet") %>%
#                mutate(topic = "News", social = "Facebook", ccdf = ccdf) %>%
#                rename("toxicity_percentage" = "toxicity_values")
# 
# fb_news_data = fb_news_data[,c("topic","toxicity_percentage","ccdf","social")]
# all_data_toxic_authors = rbind(all_data_toxic_authors, fb_news_data)

all_data_toxic_authors$social = factor(all_data_toxic_authors$social, 
                    levels = c("Usenet","Facebook","Gab","Reddit","Telegram","Twitter","Voat","Youtube"))
all_data_toxic_authors[social == "Youtube","social"] = "YouTube"
all_data_toxic_authors[topic == "Climatechange","topic"] = "Climate Change"

p1 = ggplot(all_data_toxic_authors, aes(x = toxicity_percentage, y = ccdf, col = topic)) + 
  geom_line(linewidth = 0.5) + facet_wrap(.~social, nrow = 2) + 
  theme_classic() + scale_y_log10(labels=trans_format('log10',math_format(10^.x))) +
  scale_x_continuous(breaks = c(0,0.5,1)) +
  labs(x = "User toxicity",
       y = "Probability",
       color = "Topic") +
       scale_color_manual(values = group.colors) +
       theme(strip.background = element_blank(),
             text = element_text(size = 15))

###########
# Panel b #
###########

all_data_toxicity_threads = read_parquet("data/Results/extended_data_figure_2/data_for_plot_toxicity_long_threads.parquet") %>%
              mutate(root_submission = NULL)

# fb_news_data = read_parquet("data/Results/extended_data_figure_2/facebook_news_ccdf_extended_figure_3b.parquet") %>%
#                mutate(topic = "News", social = "Facebook", ccdf = ccdf) %>%
#                rename("toxicity_percentage" = "toxicity_values")
# 
# fb_news_data = fb_news_data[,c("topic","toxicity_percentage","ccdf","social")]
# all_data_toxicity_threads = rbind(all_data_toxicity_threads, fb_news_data)

all_data_toxicity_threads$social = factor(all_data_toxicity_threads$social, 
                    levels = c("Usenet","Facebook","Gab","Reddit","Telegram","Twitter","Voat","Youtube"))
all_data_toxicity_threads[social == "Youtube","social"] = "YouTube"
all_data_toxicity_threads[topic == "Climatechange","topic"] = "Climate Change"

p2 = ggplot(all_data_toxicity_threads, aes(x = toxicity_percentage, y = ccdf,
                     col = topic)) +
  geom_line(linewidth = 0.5) +facet_wrap(.~social, nrow = 2) + 
  theme_classic() + scale_y_log10(labels=trans_format('log10',math_format(10^.x))) +
  scale_x_continuous(breaks = c(0,0.5,1)) +
  labs(x = "Thread toxicity",
       y = "Probability",
       col = "Topic") +
       scale_color_manual(values = group.colors) +
     theme(strip.background = element_blank(),
        text = element_text(size = 15)) 

#################
# Plot together #
#################

pdf(file = "figures/extended_data_figure_2.pdf", width = 10.5, height = 10.5)

p1 + p2 + plot_layout(nrow = 2, guides = "collect") +
          plot_annotation(tag_levels = list(c("(a)","(b)")))

dev.off()

