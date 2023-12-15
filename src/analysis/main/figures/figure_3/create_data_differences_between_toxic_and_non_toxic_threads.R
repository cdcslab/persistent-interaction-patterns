rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
source("src/utils/binning_functions.R")
source("src/utils/participation_and_regression_functions.R")
source("src/utils/compute_CI.R")
source("src/utils/unify_dataset_columns.R")

all_data = setDT(NULL)
social_to_work_with <- c("voat")
social_unique_names <- social_to_work_with
n_bin = 21

for (social_media_name in social_to_work_with) {
  # Read already thresholded data, i.e. only threads belonging
  # to [0.7,1]
  
  df = read_parquet(
    paste0(
      "data/Processed/BinFiltering/",
      social_media_name,
      "_comments_with_bin_ge_07.parquet"
    )
  ) %>% setDT()
  
  message("Reading: ", social_media_name)
  
  # Unify column names
  
  df = unify_dataset_columns(df, social_media_name)
  print(nrow(df[is.na(date)]))
  df = df[!is.na(date)]
  
  # Set toxicity from NA to 0 and define toxic comments
  
  df[is.na(toxicity_score), "toxicity_score"] = 0
  df$is_toxic_comment = ifelse(df$toxicity_score > 0.6, 1, 0)
  
  # Apply linear binning
  
  df = df[, .(topic,
              root_submission,
              date,
              comment_id,
              user,
              toxicity_score,
              is_toxic_comment)]
  df = df[order(topic, root_submission, date, ), ]
  
  df[, lin_bin := sapply(.SD, linear_bin, n_bin),
     by = .(root_submission, topic), .SDcols = "comment_id"]
  
  # Compute participation and toxicity in each topic, thread
  # and linear bin
  
  tmp = df[, .(participation_value =
                 sapply(.SD, participation)),
           by = .(topic, root_submission, lin_bin),
           .SDcols = "user"]
  
  # Now it's time to distinguish between toxic and non-toxic thread
  # Compute toxicity of each thread (i.e. fraction of toxic comments)
  
  toxicity_distribution = df[, .(toxicity = sum(is_toxic_comment) / .N),
                             by = .(topic, root_submission)]
  
  # Define toxic threads
  # is_toxic_thread say if the toxicity of a thread is greater than
  # the mean plus a standard deviation
  
  aux = setDT(NULL)
  
  for (t in unique(df$topic)) {
    df_topic = toxicity_distribution[topic == t, ]
    df_topic$is_toxic_thread =
      ifelse(df_topic$toxicity >
               mean(df_topic$toxicity) +
               sd(df_topic$toxicity),
             1,
             0)
    
    aux = rbind(aux, df_topic)
    
  }
  
  # Merge with the previous information
  
  tmp = merge(tmp, select(aux, -c("toxicity")))
  
  # Average over all the threads considering its toxicity status
  # Obtain only [lin_bin,is_toxic_thread,mean_participation,mean_toxicity]
  
  tmp = tmp[, .(mean_participation = mean(participation_value)),
            by = .(topic, lin_bin, is_toxic_thread)]
  
  tmp$social = ifelse(
    social_media_name == "facebook_news",
    "Facebook",
    str_to_title(social_media_name)
  )
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", social_media_name)
  
}

rm(n_bin, social_media_name)

all_data$social = str_to_title(all_data$social)
all_data[topic == "Climatechange", "topic"] = "Climate Change"
all_data[social == "Youtube", "social"] = "YouTube"

if (identical(
  social_to_work_with,
  social_unique_names
)) {
  # In this case save directly the file
  message("Writing results..")
  write_parquet(
    all_data,
    "data/Results/figure_3/toxic_vs_non_toxic_threads_all_dataset.parquet"
  )
  
} else {
  # Change the result of a subset of the datasets
  # Read the previous file
  message("Updating: ", social)
  use = str_to_title(social)
  all_data_old = read_parquet("data/Results/figure_3/toxic_vs_non_toxic_threads_all_dataset.parquet") %>%
    filter(!(social %in% use))
  print(unique(all_data_old$social))
  
  # Update it
  
  all_data = rbind(all_data_old, all_data)
  print(unique(all_data$social))
  write_parquet(
    all_data,
    "data/Results/figure_3/toxic_vs_non_toxic_threads_all_dataset.parquet"
  )
  
}

all_data_long = all_data

write_parquet(all_data_long,
              "data/Results/figure_3/all_data_long_version.parquet")

# Adjust data to have two columns for toxic participation and non toxic
# participation

tmp1 = all_data[is_toxic_thread == 0, -c("is_toxic_thread")] %>%
  rename("participation_non_toxic" = "mean_participation")

tmp2 = all_data[is_toxic_thread == 1, -c("is_toxic_thread")] %>%
  rename("participation_toxic" = "mean_participation")

all_data = merge(tmp1, tmp2)
rm(tmp1, tmp2)

#########################################################################
# Plot correlation between participation in toxic and non toxic threads #
#########################################################################

data_for_plot_correlation = all_data[, .(correlation =
                                           cor(participation_non_toxic,
                                               participation_toxic)),
                                     by = .(social, topic)]

data_for_plot_correlation$topic_and_social =
  paste(data_for_plot_correlation$social,
        data_for_plot_correlation$topic)

write_parquet(
  data_for_plot_correlation,
  "data/Results/figure_3/data_for_plot_correlation_participation.parquet"
)

############################################
# Differences between angular coefficients #
############################################

tmp1 = all_data[, .(participation_toxic_slopes =
                      sapply(.SD, regression_coefficient)),
                by = .(social, topic),
                .SDcols = c("participation_toxic")]

tmp2 = all_data[, .(participation_non_toxic_slopes =
                      sapply(.SD, regression_coefficient)),
                by = .(social, topic),
                .SDcols = c("participation_non_toxic")]

data_for_plot_slopes = merge(tmp1, tmp2)
rm(tmp1, tmp2)

data_for_plot_slopes$difference = data_for_plot_slopes$participation_toxic_slopes -
  data_for_plot_slopes$participation_non_toxic_slopes

data_for_plot_slopes$topic_and_social =
  paste(data_for_plot_slopes$social,
        data_for_plot_slopes$topic)

write_parquet(
  data_for_plot_slopes,
  "data/Results/figure_3/data_for_slopes_differences.parquet"
)

############################################
# Correlation with interaction coefficient #
############################################

table_interaction = setDT(NULL)

for (social_media_name in unique(all_data_long$social)) {
  tmp = all_data_long[social == social_media_name, ]
  
  for (j in unique(tmp$topic)) {
    tmp_topic = tmp[topic == j] %>%
      mutate(lin_bin = as.numeric(lin_bin),
             is_toxic_thread = as.numeric(is_toxic_thread))
    model = lm(mean_participation ~ lin_bin * is_toxic_thread, data = tmp_topic)
    p_value_interaction <-
      summary(model)$coefficients["lin_bin:is_toxic_thread", "Pr(>|t|)"]
    tmp_topic$social_topic = paste(unique(tmp_topic$social), unique(tmp_topic$topic))
    
    table_interaction = rbind(table_interaction,
                              data.table(
                                social_topic = unique(tmp_topic$social_topic),
                                p = p_value_interaction
                              ))
    
  }
  
}

write_parquet(table_interaction,
              "data/Results/figure_3/data_for_table_interactions.parquet")
message("Done")
