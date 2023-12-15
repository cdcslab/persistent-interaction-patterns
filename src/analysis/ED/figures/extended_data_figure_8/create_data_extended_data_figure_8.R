rm(list = ls())

library(data.table)
library(dplyr)
library(arrow)
library(stringr)
library(scales)

assign_comment_position = function(x) {
  comment_position = rep(NA, length(x))
  
  comment_position[1:3] = "Begin"
  comment_position[(length(x) - 2):length(x)] = "End"
  
  return(comment_position)
  
}

all_data = setDT(NULL)
wilcox_table = setDT(NULL)
# social = c("gab","reddit","voat","telegram","twitter","usenet","youtube","facebook","facebook_news")
social = c(
  "gab",
  "reddit",
  "voat",
  "telegram",
  "twitter",
  "usenet",
  "youtube",
  "facebook",
  "facebook_news"
)

for (i in social) {
  # Read short conversations
  
  df <- read_parquet(paste0("data/data_short_threads/", i,
                            "_short_threads.parquet")) %>%
    setDT()
  
  message("Read: ", i)
  
  if (i == "gab") {
    df$topic = "feed"
    
  }
  
  # Set NA toxicity to 0
  
  df[is.na(toxicity_score), "toxicity_score"] = 0
  
  # Order the comments
  
  df = df[order(topic, root_submission, date), ]
  
  # Assign a label that indicate the positions
  
  df[, comment_position := sapply(.SD, assign_comment_position),
     by = .(topic, root_submission), .SDcols = "date"]
  
  data_for_plot = df[!is.na(comment_position), c("topic",
                                                 "root_submission",
                                                 "comment_position",
                                                 "toxicity_score")]
  data_for_plot$social = ifelse(i == "facebook_news", "Facebook", str_to_title(i))
  
  for (j in unique(data_for_plot$topic)) {
    tmp = data_for_plot[topic == j, ]
    
    test = wilcox.test(tmp[comment_position == "Begin"]$toxicity_score,
                       tmp[comment_position == "End"]$toxicity_score)
    
    wilcox_table = rbind(wilcox_table,
                         data.table(
                           social = unique(data_for_plot$social),
                           topic = j,
                           p_value = test$p.value
                         ))
    
  }
  
  all_data = rbind(all_data, data_for_plot)
  
  
  rm(df, data_for_plot)
  gc()
  
  message("Done with ", i)
  
}

# Save data

all_data$topic = str_to_title(all_data$topic)
all_data[topic == "Climatechange", "topic"] = "Climate Change"
all_data[social == "Youtube", "social"] <- "YouTube"

write_parquet(
  all_data,
  "data/Results/extended_data_figure_8/data_for_plot_short_conversation.parquet"
)
write_parquet(
  wilcox_table,
  "data/Results/extended_data_figure_8/wilcox_test_short_conversation.parquet"
)