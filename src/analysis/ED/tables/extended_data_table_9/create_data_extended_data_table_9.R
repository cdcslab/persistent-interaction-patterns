rm(list = ls())
gc()

library(data.table)
library(dplyr)
library(arrow)
library(xtable)
source("./src/utils/unify_validation_dataset.R")

list_dataset = list.files("data/validation_dataset_without_root/")
all_data = setDT(NULL)

for (i in list_dataset) {
        
    # Read the whole dataset
        
    df <- read_parquet(paste0("data/validation_dataset_without_root/",i)) %>% setDT()
    message("Read: ", i)

    # Unify column names
    df = unify_validation_dataset(df,i)
    k = unique(df$social)

    # Define toxic comments 

    df[is.na(toxicity_score),"toxicity_score"] = 0
    df$is_toxic_perspective = ifelse(df$toxicity_score > 0.6,1,0)
    
    df[is.na(detoxify_scoreM), "detoxify_scoreM"] = 0
    df$is_toxic_detoxify <- ifelse(df$detoxify_scoreM > 0.6, 1, 0)

    df[is.na(imsypp_label), "imsypp_label"] = "acceptable"
    df$is_toxic_imsypp <- ifelse(df$imsypp_label != "acceptable", 1, 0)

    # create table
    data_for_table = data.table(type = c("NT","T"))

    # count with detoxify

    t = table(df$is_toxic_perspective, df$is_toxic_detoxify)
    data_for_table = cbind(data_for_table, 
                           data.table(NT_detoxify = 100*c(t[1,1]/nrow(df[is_toxic_perspective == 0,]),
                                                      t[2,1]/nrow(df[is_toxic_perspective == 1,])),
                                      T_detoxify = 100*c(t[1,2]/nrow(df[is_toxic_perspective == 0,]),
                                                      t[2,2]/nrow(df[is_toxic_perspective == 1,]))))

    # count with imsypp

    t = table(df$is_toxic_perspective, df$is_toxic_imsypp)
    data_for_table = cbind(data_for_table, 
                           data.table(NT_imsypp = 100*c(t[1,1]/nrow(df[is_toxic_perspective == 0,]),
                                                      t[2,1]/nrow(df[is_toxic_perspective == 1,])),
                                      T_imsypp = 100*c(t[1,2]/nrow(df[is_toxic_perspective == 0,]),
                                                      t[2,2]/nrow(df[is_toxic_perspective == 1,]))))

    data_for_table$social = str_to_title(paste(k,unique(df$topic)))
    data_for_table = data_for_table[,c("social","type","NT_detoxify","T_detoxify","NT_imsypp","T_imsypp")]
    all_data = rbind(all_data, data_for_table)
    rm(df)
    gc()
        
    message("Done with ", i)
        
}   

write_parquet(all_data, "data/Results/data_extended_data_table_9.parquet")
