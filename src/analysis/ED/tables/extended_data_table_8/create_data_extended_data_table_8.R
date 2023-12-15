rm(list = ls())
gc()

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)
library(stringr)
library(scales)
library(trend)
library(xtable)
source("./src/utils/binning_functions.R")
source("./src/utils/compute_CI.R")
source("./src/utils/unify_validation_dataset.R")
source("./src/utils/participation_and_regression_functions.R")
source("./src/utils/apply_mk_and_regression.R")

list_dataset = list.files("data/validation_dataset_without_root/")
classificator = c("perspective","detoxify","imsypp")

data_for_table_all = setDT(NULL)

for (t in classificator) {

    all_data = setDT(NULL)

    for (i in list_dataset) {
        
        # Read the whole dataset
        
        df <- read_parquet(paste0("data/validation_dataset_without_root/",i)) %>% setDT()
        message("Read: ", i)

        # Unify column names

        df = unify_validation_dataset(df,i)
        k = unique(df$social)

        if (t == "perspective") {

            df[is.na(toxicity_score),"toxicity_score"] = 0
            df$is_toxic = ifelse(df$toxicity_score > 0.6,1,0)

        } else if (t == "detoxify") {

            df[is.na(detoxify_scoreM), "detoxify_scoreM"] = 0
            df$is_toxic <- ifelse(df$detoxify_scoreM > 0.6, 1, 0)

        } else if (t == "imsypp") {

            df[is.na(imsypp_label), "imsypp_label"] = "acceptable"
            df$is_toxic <- ifelse(df$imsypp_label != "acceptable", 1, 0)

        } else {

            stop("Not a valid classificator!")

        }

        ##########################################
        # Compute the log-binning (once for all) #
        ##########################################
        
        # Thread length
        
        df[, thread_length := .N, by = .(root_submission,topic)]
        
        # Bin thread length
        
        df[, discretized_bin_label := sapply(.SD, log_bin, 21),
            by = .(topic), .SDcols = "thread_length"] 
        
        # Modify the binning -> the last bin must have 50 elements
        
        resize_df = setDT(NULL)
        
        for (j in unique(df$topic)) {
            
            aux = resize_last_bin(df[topic == j], n_bin = 21)
            resize_df = rbind(resize_df,aux)
            
        }

        # Compute original trend
        
        tmp = resize_df[,.(toxicity_percentage = sum(is_toxic)/.N),
                    by = .(topic, root_submission, resize_discretized_bin_label)]
        
        real_trend = tmp[,.(mean_t = mean(toxicity_percentage)),
                        by = .(topic, resize_discretized_bin_label)]
        
        ##############################
        # Apply MK-test & regression #
        ##############################
        
        data_for_table = apply_mk_and_regression(real_trend)
        
        # Aggregate with other data
        
        colnames(data_for_table)[-length(colnames(data_for_table))] = 
                        paste(colnames(data_for_table)[-length(colnames(data_for_table))], t, sep = "_")
        data_for_table$social = str_to_title(k)
        all_data = rbind(all_data, data_for_table)
        rm(tmp,df)
        gc()
        
        message("Done with ", i)
        
        }   
     
    if (t == classificator[1]) {

        data_for_table_all = all_data

    } else {

        data_for_table_all = merge(data_for_table_all,all_data, by = c("social","topic"))

    }
    
    message("Done with: ", t)

}

data_for_table_all$social_topic = paste(data_for_table_all$social, str_to_title(data_for_table_all$topic))
write_parquet(data_for_table_all, "data/Results/extended_data_table_9.parquet")
