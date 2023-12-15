rm(list = ls())
gc()

library(data.table)
library(dplyr)
library(arrow)
library(xtable)

list_dataset = list.files("data/validation_dataset_ge_07/")
all_data = setDT(NULL)

for (i in list_dataset) {
        
    # Read the whole dataset
        
    df <- read_parquet(paste0("data/validation_dataset_ge_07/",i)) %>% setDT()
    message("Read: ", i)

    # Unify column names

    k = unique(df$social)
    
    # Size of threads (i.e. number of comments)

    tmp = df[,.(thread_size = .N), by = .(topic, root_submission)]
    tmp = tmp[,.(min_size = min(thread_size), max_size = max(thread_size)), by = .(topic)]

    # Compute number of threads
    thread_number = unique(df[,.(topic,root_submission)])
    thread_number = thread_number[, .(threads = .N), by = .(topic)]    

    data_for_table = merge(tmp, thread_number, by = "topic") 
    data_for_table$social = str_to_title(k)
    data_for_table = data_for_table[,c("social","topic","threads","min_size","max_size")]
    all_data = rbind(all_data, data_for_table)
    rm(tmp,df)
    gc()
        
    message("Done with ", i)
        
}   

all_data$social_topic = paste(all_data$social, str_to_title(all_data$topic))
write_parquet(all_data, "data/Results/data_extended_data_table_6.parquet")
