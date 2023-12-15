library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(patchwork)

# Variables ####
plot_controversy <- F
plot_engagement_vs_toxicity <- T
plot_frequency_toxicty_comments <- F
pa <- NULL
pb <- NULL
pc <- NULL
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

# Controversy ####

if (plot_controversy == T)
{
  fb_news = read_parquet(
    "data/Results/figure_4/Facebook/facebook_news_average_controversy_quantities_by_bin.parquet"
  )
  
  tmp1 = fb_news %>%
    select(
      c(
        resize_discretized_bin_label,
        mean_toxicity_percentage_by_bin,
        CI_inf_toxicity,
        CI_sup_toxicity
      )
    ) %>%
    rename(
      "bin" = "resize_discretized_bin_label",
      "value" = "mean_toxicity_percentage_by_bin",
      "CI_inf" = "CI_inf_toxicity",
      "CI_sup" = "CI_sup_toxicity"
    ) %>%
    mutate(type = "Toxicity")
  
  tmp2 = fb_news %>%
    select(
      c(
        resize_discretized_bin_label,
        mean_sd_leaning_by_bin,
        CI_inf_leaning,
        CI_sup_leaning
      )
    ) %>%
    rename(
      "bin" = "resize_discretized_bin_label",
      "value" = "mean_sd_leaning_by_bin",
      "CI_inf" = "CI_inf_leaning",
      "CI_sup" = "CI_sup_leaning"
    ) %>%
    mutate(type = "Controversy")
  
  fb_news = rbind(tmp1, tmp2) %>% mutate(social = "Facebook News")
  
  gab = read_parquet(
    "data/Results/figure_4/Gab/gab_average_controversy_quantities_by_bin.parquet"
  )
  
  tmp1 = gab %>%
    select(
      c(
        resize_discretized_bin_label,
        mean_toxicity_percentage_by_bin,
        CI_inf_toxicity,
        CI_sup_toxicity
      )
    ) %>%
    rename(
      "bin" = "resize_discretized_bin_label",
      "value" = "mean_toxicity_percentage_by_bin",
      "CI_inf" = "CI_inf_toxicity",
      "CI_sup" = "CI_sup_toxicity"
    ) %>%
    mutate(type = "Toxicity")
  
  tmp2 = gab %>%
    select(
      c(
        resize_discretized_bin_label,
        mean_sd_leaning_by_bin,
        CI_inf_leaning,
        CI_sup_leaning
      )
    ) %>%
    rename(
      "bin" = "resize_discretized_bin_label",
      "value" = "mean_sd_leaning_by_bin",
      "CI_inf" = "CI_inf_leaning",
      "CI_sup" = "CI_sup_leaning"
    ) %>%
    mutate(type = "Controversy")
  
  gab = rbind(tmp1, tmp2) %>% mutate(social = "Gab Feed")
  
  tw_news = read_parquet(
    "data/Results/figure_4/Twitter/twitter_news_average_controversy_quantities_by_bin.parquet"
  )
  
  tmp1 = tw_news %>%
    select(
      c(
        resize_discretized_bin_label,
        mean_toxicity_percentage_by_bin,
        CI_inf_toxicity,
        CI_sup_toxicity
      )
    ) %>%
    rename(
      "bin" = "resize_discretized_bin_label",
      "value" = "mean_toxicity_percentage_by_bin",
      "CI_inf" = "CI_inf_toxicity",
      "CI_sup" = "CI_sup_toxicity"
    ) %>%
    mutate(type = "Toxicity")
  
  tmp2 = tw_news %>%
    select(
      c(
        resize_discretized_bin_label,
        mean_sd_leaning_by_bin,
        CI_inf_leaning,
        CI_sup_leaning
      )
    ) %>%
    rename(
      "bin" = "resize_discretized_bin_label",
      "value" = "mean_sd_leaning_by_bin",
      "CI_inf" = "CI_inf_leaning",
      "CI_sup" = "CI_sup_leaning"
    ) %>%
    mutate(type = "Controversy")
  
  tw_news = rbind(tmp1, tmp2) %>% mutate(social = "Twitter News")
  
  tw_vaccines = read_parquet(
    "data/Results/figure_4/Twitter/twitter_vaccines_average_controversy_quantities_by_bin.parquet"
  )
  
  tmp1 = tw_vaccines %>%
    select(
      c(
        resize_discretized_bin_label,
        mean_toxicity_percentage_by_bin,
        CI_inf_toxicity,
        CI_sup_toxicity
      )
    ) %>%
    rename(
      "bin" = "resize_discretized_bin_label",
      "value" = "mean_toxicity_percentage_by_bin",
      "CI_inf" = "CI_inf_toxicity",
      "CI_sup" = "CI_sup_toxicity"
    ) %>%
    mutate(type = "Toxicity")
  
  tmp2 = tw_vaccines %>%
    select(
      c(
        resize_discretized_bin_label,
        mean_sd_leaning_by_bin,
        CI_inf_leaning,
        CI_sup_leaning
      )
    ) %>%
    rename(
      "bin" = "resize_discretized_bin_label",
      "value" = "mean_sd_leaning_by_bin",
      "CI_inf" = "CI_inf_leaning",
      "CI_sup" = "CI_sup_leaning"
    ) %>%
    mutate(type = "Controversy")
  
  tw_vaccines = rbind(tmp1, tmp2) %>% mutate(social = "Twitter Vaccines")
  
  data_for_plot = rbind(fb_news, gab, tw_news, tw_vaccines)
  
  # Add correlations as captions
  
  pa = ggplot(data_for_plot,
              aes(
                x = bin,
                y = value,
                group = type,
                col = type,
                fill = type
              )) +
    geom_line(linewidth = 0.6) + theme_classic() +
    geom_ribbon(
      aes(ymin = CI_inf, ymax = CI_sup, col = NULL),
      alpha = 0.3,
      show.legend = FALSE
    ) +
    theme(
      strip.background = element_blank(),
      text = element_text(size = 15),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_blank(),
      axis.line = element_line(colour = "black")
    ) +
    scale_x_discrete(breaks = c(0, 0.5, 1)) + facet_wrap(. ~ social, nrow = 1) +
    labs(x = "Normalized thread size",
         y = NULL, col = NULL) +
    scale_color_manual(values = c(
      "Toxicity" = "orange",
      "Controversy" = "lightblue"
    )) +
    scale_fill_manual(values = c(
      "Toxicity" = "orange",
      "Controversy" = "lightblue"
    ))
}
# Plot engagement vs toxicity ####
if (plot_engagement_vs_toxicity == T)
{
  all_data = read_parquet("data/Results/figure_4/engagement_vs_toxicity.parquet")
  # fb_news_data = read_parquet(
  #   "data/Results/figure_4/Facebook/facebook_news_average_likes_by_toxicity_bin.parquet"
  # ) %>%
  #   rename("toxicity_lin_bin" = "bin",
  #          "engagement" = "mean_likes") %>%
  #   mutate(
  #     topic = "News",
  #     social = "Facebook",
  #     normalized_engagement = engagement / max(engagement)
  #   )
  #
  # fb_news_data = fb_news_data[, c("topic",
  #                                 "toxicity_lin_bin",
  #                                 "engagement",
  #                                 "social",
  #                                 "normalized_engagement")]
  #
  # all_data = rbind(all_data, fb_news_data)
  
  pb = ggplot(all_data,
              aes(
                x = as.character(toxicity_lin_bin),
                y = normalized_engagement,
                group = topic,
                col = topic
              )) +
    geom_line(linewidth = 0.6) + theme_classic() + ylim(0, 1) +
    theme(strip.background = element_blank(), text = element_text(size = 15)) +
    scale_x_discrete(breaks = c(0, 0.5, 1)) + facet_wrap(. ~ social, nrow = 1) +
    labs(x = "Toxicity score", y = "Likes/upvotes", col = "Topic") +
    scale_color_manual(values = group.colors)
}
# Plot frequency of toxic comments ####
if (plot_frequency_toxicty_comments == T)
{
  all_data_frequency = read_parquet("data/Results/figure_4/data_plot_4c.parquet")
  all_data_frequency$phase = factor(all_data_frequency$phase, levels = c("Pre", "Peak", "Post"))
  
  pc = ggplot(all_data_frequency,
              aes(x = phase, y  = percentage_toxicity, fill = phase)) +
    geom_boxplot(
      col = "black",
      outlier.alpha = 0.1,
      outlier.size = 0.1
    ) +
    theme_classic() +
    labs(x = NULL,
         y = "Fraction of \n toxic comments",
         col = NULL,
         fill = NULL) +
    theme(
      legend.background = element_rect(
        linewidth = 0.5,
        linetype = "solid",
        colour = "black"
      ),
      text = element_text(size = 15),
      axis.text.x = element_blank()
    ) +
    scale_fill_discrete()
}

# Join all together

p3 = plot_spacer() + pc + plot_spacer() + plot_layout(widths = c(0.25, 1, 0.25))

pdf(file = "figures/figure_4.pdf",
    width = 8,
    height = 6)

pa / pb / p3 + plot_annotation(tag_levels = list(c("(a)", "(b)", "(c)")))

dev.off()
