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
source("src/transformation/unify_validation_dataset.R")

folder_to_save = "data/Results/extended_data_figure_6/"
all_data = setDT(NULL)
list_dataset = list.files("data/validation_dataset_ge_07/")
n_bin = 21

# Chose one between perspective, imsypp and detoxify
classificator = "detoxify"

for (i in list_dataset) {
  # Read already thresholded data, i.e. only threads belonging
  # to [0.7,1]
  
  df <-
    read_parquet(paste0("data/validation_dataset_ge_07/", i)) %>% setDT()
  
  message("Read: ", i)
  
  # Unify column names
  
  k = unique(df$social)
  
  # Set toxicity from NA to 0 and define toxic comments
  
  if (classificator == "perspective") {
    df[is.na(toxicity_score), "toxicity_score"] = 0
    df$is_toxic_comment = ifelse(df$toxicity_score > 0.6, 1, 0)
    
  } else if (classificator == "detoxify") {
    df[is.na(detoxify_scoreM), "detoxify_scoreM"] = 0
    df$is_toxic_comment <- ifelse(df$detoxify_scoreM > 0.6, 1, 0)
    
  } else if (classificator == "imsypp") {
    df[is.na(imsypp_label), "imsypp_label"] = "acceptable"
    df$is_toxic_comment <-
      ifelse(df$imsypp_label != "acceptable", 1, 0)
    
  } else {
    stop("Not a valid classificator!")
    
  }
  
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
    one_topic = toxicity_distribution[topic == t, ]
    one_topic$is_toxic_thread =
      ifelse(one_topic$toxicity >
               mean(one_topic$toxicity) +
               sd(one_topic$toxicity),
             1,
             0)
    
    aux = rbind(aux, one_topic)
    
  }
  
  # Merge with the previous information
  
  tmp = merge(tmp, select(aux, -c("toxicity")))
  
  # Average over all the threads considering its toxicity status
  # Obtain only [lin_bin,is_toxic_thread,mean_participation,mean_toxicity]
  
  tmp = tmp[, .(mean_participation = mean(participation_value)),
            by = .(topic, lin_bin, is_toxic_thread)]
  
  tmp$social = k
  all_data = rbind(all_data, tmp)
  rm(tmp, df)
  gc()
  
  message("Done with ", i)
  
}

rm(n_bin, i)

all_data$social = str_to_title(all_data$social)
all_data[social == "Youtube", "social"] = "YouTube"

all_data_long = all_data
write_parquet(
  all_data_long,
  paste0(
    folder_to_save,
    "all_data_toxic_vs_non_toxic_threads_",
    classificator,
    ".parquet"
  )
)

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
  paste0(
    folder_to_save,
    "data_for_plot_correlation_participation_",
    classificator,
    ".parquet"
  )
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
  paste0(
    folder_to_save,
    "data_for_slopes_differences_",
    classificator,
    ".parquet"
  )
)

############################################
# Correlation with interaction coefficient #
############################################

table_interaction = setDT(NULL)

for (i in unique(all_data_long$social)) {
  tmp = all_data_long[social == i, ]
  
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

write_parquet(
  table_interaction,
  paste0(
    folder_to_save,
    "table_interactions_validation_",
    classificator,
    ".parquet"
  )
)
