library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(patchwork)
library(cowplot)

folder_to_load = "data/Results/extended_data_figure_6/"

###############
# Perspective #
###############

classificator = "perspective"

# Plot a) 

data_for_plot_lollipop = read_parquet(paste0(folder_to_load,"all_data_for_correlation_participation_toxicity_",classificator,".parquet"))

pa_p = ggplot(data_for_plot_lollipop, aes(x = topic_and_social, y = correlation, 
                                   col = correlation, alpha = abs(correlation))) +
  geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
                   y = 0, yend = correlation)) +
  geom_point() +
  coord_flip() +
  theme_bw() + 
  theme(legend.position = "right") +
  scale_colour_gradient(low = "blue", high = "red") +
  theme(legend.position = "none") +
  labs(x = NULL, 
       y = "Correlation between \n participation and toxicity",
       col 
       = NULL, alpha = NULL) +
       theme(text = element_text(size = 15))

# Plot d)

data_for_plot_slopes = read_parquet(paste0(folder_to_load,"all_data_for_slopes_", classificator,".parquet"))

tmp1 = select(data_for_plot_slopes, -c("toxicity_slopes"))
tmp1$type = "Participation"
colnames(tmp1)[3] = "value"

tmp2 = select(data_for_plot_slopes, -c("participation_slopes"))
tmp2$type = "Toxicity"
colnames(tmp2)[3] = "value"

data_for_plot_slopes = rbind(tmp1,tmp2) %>%
              mutate(type = factor(type, levels = c("Toxicity","Participation")))

pd_p = ggplot(data_for_plot_slopes, aes(x = type, y = value, fill = type)) +
  geom_boxplot(col = "black") + 
  theme_classic() + 
  labs(y = "Angular coefficient values",
       x = NULL,
       col = NULL, fill = NULL) + 
     theme(legend.position = c(0.35,0.23), axis.text.x = element_blank(),
           legend.background = element_rect(size=0.5, 
           linetype="solid", 
          colour ="black")) +
          scale_color_manual(values=c("orange","lightblue")) +
          scale_fill_manual(values=c("orange","lightblue")) +
          theme(text = element_text(size = 15))

# Plot b) 

data_for_plot_correlation_participation = read_parquet(paste0(folder_to_load,"data_for_plot_correlation_participation_",classificator,".parquet"))

pb_p = ggplot(data_for_plot_correlation_participation, aes(x = topic_and_social, y = correlation, 
                                   col = correlation, alpha = abs(correlation))) +
  geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
                   y = 0, yend = correlation)) +
  geom_point() +
  coord_flip() +
  theme_bw() + 
  theme(legend.position = "right") +
  scale_colour_gradient(low = "blue", high = "red") +
  theme(legend.position = "none") +
  labs(x = NULL, 
       y = "Correlation between \n participation in toxic \n and non toxic threads",
       col = NULL, alpha = NULL) + ylim(-1,1) +
       theme(text = element_text(size = 15))

# Plot c)

# data_for_plot_slopes_differences = read_parquet(paste0(folder_to_load,"data_for_slopes_differences_", classificator,".parquet"))

# pc_p = ggplot(data_for_plot_slopes_differences, aes(x = topic_and_social, y = difference, 
#                                       col = difference, alpha = abs(difference))) +
#   geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
#                    y = 0, yend = difference)) +
#   geom_point() +
#   coord_flip() +
#   theme_bw() + 
#   theme(legend.position = "right") +
#   scale_colour_gradient(low = "blue", high = "red") +
#   theme(legend.position = "none") +
#   labs(x = NULL, 
#        y = "Difference between \n angular coefficients",
#        col = NULL, alpha = NULL) +
#        theme(text = element_text(size = 15))

############
# Detoxify #
############

classificator = "detoxify"

# Plot a) 

data_for_plot_lollipop = read_parquet(paste0(folder_to_load,"all_data_for_correlation_participation_toxicity_",classificator,".parquet"))

pa_d = ggplot(data_for_plot_lollipop, aes(x = topic_and_social, y = correlation, 
                                   col = correlation, alpha = abs(correlation))) +
  geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
                   y = 0, yend = correlation)) +
  geom_point() +
  coord_flip() +
  theme_bw() + 
  theme(legend.position = "right") +
  scale_colour_gradient(low = "blue", high = "red") +
  theme(legend.position = "none") +
  labs(x = NULL, 
       y = "Correlation between \n participation and toxicity",
       col 
       = NULL, alpha = NULL) +
       theme(text = element_text(size = 15))

# Plot d)

data_for_plot_slopes = read_parquet(paste0(folder_to_load,"all_data_for_slopes_", classificator,".parquet"))

tmp1 = select(data_for_plot_slopes, -c("toxicity_slopes"))
tmp1$type = "Participation"
colnames(tmp1)[3] = "value"

tmp2 = select(data_for_plot_slopes, -c("participation_slopes"))
tmp2$type = "Toxicity"
colnames(tmp2)[3] = "value"

data_for_plot_slopes = rbind(tmp1,tmp2) %>%
              mutate(type = factor(type, levels = c("Toxicity","Participation")))

pd_d = ggplot(data_for_plot_slopes, aes(x = type, y = value, fill = type)) +
  geom_boxplot(col = "black") + 
  theme_classic() + 
  labs(y = "Angular coefficient values",
       x = NULL,
       col = NULL, fill = NULL) + 
     theme(legend.position = c(0.35,0.23), axis.text.x = element_blank(),
           legend.background = element_rect(size=0.5, 
           linetype="solid", 
          colour ="black")) +
          scale_color_manual(values=c("orange","lightblue")) +
          scale_fill_manual(values=c("orange","lightblue")) +
          theme(text = element_text(size = 15))

# Plot b) 

data_for_plot_correlation_participation = read_parquet(paste0(folder_to_load,"data_for_plot_correlation_participation_",classificator,".parquet"))

pb_d = ggplot(data_for_plot_correlation_participation, aes(x = topic_and_social, y = correlation, 
                                   col = correlation, alpha = abs(correlation))) +
  geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
                   y = 0, yend = correlation)) +
  geom_point() +
  coord_flip() +
  theme_bw() + 
  theme(legend.position = "right") +
  scale_colour_gradient(low = "blue", high = "red") +
  theme(legend.position = "none") +
  labs(x = NULL, 
       y = "Correlation between \n participation in toxic \n and non toxic threads",
       col = NULL, alpha = NULL) + ylim(-1,1) +
       theme(text = element_text(size = 15))

# Plot c)

# data_for_plot_slopes_differences = read_parquet(paste0(folder_to_load,"data_for_slopes_differences_", classificator,".parquet"))

# pc_d = ggplot(data_for_plot_slopes_differences, aes(x = topic_and_social, y = difference, 
#                                       col = difference, alpha = abs(difference))) +
#   geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
#                    y = 0, yend = difference)) +
#   geom_point() +
#   coord_flip() +
#   theme_bw() + 
#   theme(legend.position = "right") +
#   scale_colour_gradient(low = "blue", high = "red") +
#   theme(legend.position = "none") +
#   labs(x = NULL, 
#        y = "Difference between \n angular coefficients",
#        col = NULL, alpha = NULL) +
#        theme(text = element_text(size = 15))

##########
# Imsypp #
##########

classificator = "imsypp"

# Plot a) 

data_for_plot_lollipop = read_parquet(paste0(folder_to_load,"all_data_for_correlation_participation_toxicity_",classificator,".parquet"))

pa_i = ggplot(data_for_plot_lollipop, aes(x = topic_and_social, y = correlation, 
                                   col = correlation, alpha = abs(correlation))) +
  geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
                   y = 0, yend = correlation)) +
  geom_point() +
  coord_flip() +
  theme_bw() + 
  theme(legend.position = "right") +
  scale_colour_gradient(low = "blue", high = "red") +
  theme(legend.position = "none", text = element_text(size = 15)) +
  labs(x = NULL, 
       y = "Correlation between \n participation and toxicity",
       col 
       = NULL, alpha = NULL) +
       theme(text = element_text(size = 15))
       

# Plot d)

data_for_plot_slopes = read_parquet(paste0(folder_to_load,"all_data_for_slopes_", classificator,".parquet"))

tmp1 = select(data_for_plot_slopes, -c("toxicity_slopes"))
tmp1$type = "Participation"
colnames(tmp1)[3] = "value"

tmp2 = select(data_for_plot_slopes, -c("participation_slopes"))
tmp2$type = "Toxicity"
colnames(tmp2)[3] = "value"

data_for_plot_slopes = rbind(tmp1,tmp2) %>%
              mutate(type = factor(type, levels = c("Toxicity","Participation")))

pd_i = ggplot(data_for_plot_slopes, aes(x = type, y = value, fill = type)) +
  geom_boxplot(col = "black") + 
  theme_classic() + 
  labs(y = "Angular coefficient values",
       x = NULL,
       col = NULL, fill = NULL) + 
     theme(legend.position = c(0.35,0.23), axis.text.x = element_blank(),
           legend.background = element_rect(size=0.5, 
           linetype="solid", 
          colour ="black"),
          text = element_text(size = 15)) +
          scale_color_manual(values=c("orange","lightblue")) +
          scale_fill_manual(values=c("orange","lightblue")) +
          theme(text = element_text(size = 15))

# Plot b) 

data_for_plot_correlation_participation = read_parquet(paste0(folder_to_load,"data_for_plot_correlation_participation_",classificator,".parquet"))

pb_i = ggplot(data_for_plot_correlation_participation, aes(x = topic_and_social, y = correlation, 
                                   col = correlation, alpha = abs(correlation))) +
  geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
                   y = 0, yend = correlation)) +
  geom_point() +
  coord_flip() +
  theme_bw() + 
  theme(legend.position = "right") +
  scale_colour_gradient(low = "blue", high = "red") +
  theme(legend.position = "none") +
  labs(x = NULL, 
       y = "Correlation between \n participation in toxic \n and non toxic threads",
       col = NULL, alpha = NULL) + ylim(-1,1) +
       theme(text = element_text(size = 15))

# Plot c)

# data_for_plot_slopes_differences = read_parquet(paste0(folder_to_load,"data_for_slopes_differences_", classificator,".parquet"))

# pc_i = ggplot(data_for_plot_slopes_differences, aes(x = topic_and_social, y = difference, 
#                                       col = difference, alpha = abs(difference))) +
#   geom_segment(aes(x = topic_and_social, xend = topic_and_social, 
#                    y = 0, yend = difference)) +
#   geom_point() +
#   coord_flip() +
#   theme_bw() + 
#   theme(legend.position = "right") +
#   scale_colour_gradient(low = "blue", high = "red") +
#   theme(legend.position = "none") +
#   labs(x = NULL, 
#        y = "Difference between \n angular coefficients",
#        col = NULL, alpha = NULL)  +
#        theme(text = element_text(size = 15))

#############################
# Aggreagate with patchwork #
#############################

# pdf(file = "figures/extended_data_figure_6.pdf", width = 12.5, height = 12.5)

# (pa_p | pa_d | pa_i) / (pb_p | pb_d | pb_i) / (pd_p | pd_d | pd_i) +
#           plot_annotation(tag_levels = list(c("(a)","","","(b)","","","(c)","","","(d)")))

# dev.off()

first_row = plot_grid(pa_p,pa_d,pa_i, nrow = 1, labels = c("(a)","",""), hjust = 0.13)
second_row = plot_grid(pb_p,pb_d,pb_i, nrow = 1, labels = c("(b)","",""), hjust = 0.13)
third_row = plot_grid(pd_p,pd_d,pd_i, nrow = 1, labels = c("(c)","",""), hjust = 0.13)

pdf(file = "figures/extended_data_figure_6.pdf", width = 13, height = 13)

plot_grid(first_row,second_row,third_row,
          nrow = 3, rel_heights = c(1,1,0.8))

dev.off()
