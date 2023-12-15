# Create dataset without roots

library(data.table)
library(ggplot2)
library(dplyr)
library(arrow)

path <- "data/validation_dataset_from_gdrive/"
files_validation <- list.files(path)

for (i in files_validation) {

 df = fread(paste0(path,i))

 message("Read: ",i)

 if (i == "reddit_askreddit.csv") {

    write_parquet(df[comment_code != post_id,],"data/validation_dataset_without_root/reddit_askreddit_no_root.parquet")

 } else if (i == "youtube_carbonara.csv") {

    write_parquet(df, "data/validation_dataset_without_root/youtube_carbonara_no_root.parquet")

 } else if (i == "facebook_film.csv") {

    # Split the post_id in two strings and keep only the comments in which comment_id and
    # root_id are different

    # split_string = unlist(strsplit(df$post_id, "_"))
    # comment_id = split_string[1]
    # root_id = split_string[2]

    write_parquet(df, "data/validation_dataset_without_root/facebook_film_no_root.parquet")

 } else if (i == "facebook_sports.csv") {

    # split_string = unlist(strsplit(df$post_id, "_"))
    # comment_id = split_string[1]
    # root_id = split_string[2]

    write_parquet(df, "data/validation_dataset_without_root/facebook_sports_no_root.parquet")

 } else if (i == "twitter_got.csv") {

    write_parquet(df[!is.na(replied_id),], "data/validation_dataset_without_root/twitter_got_no_root.parquet")

 } else if (i == "twitter_nasa.csv") {

    write_parquet(df[!is.na(replied_id),], "data/validation_dataset_without_root/twitter_nasa_no_root.parquet")

 } else if (i == "telegram_crypto.csv") {
    
    write_parquet(df[id != root,],"data/validation_dataset_without_root/telegram_crypto_no_root.parquet")

 } else if (i == "youtube_football.csv") {

    write_parquet(df, "data/validation_dataset_without_root/youtube_football_no_root.parquet")

 } else if (i == "reddit_iama.csv") {

    write_parquet(df[comment_code != post_id,],"data/validation_dataset_without_root/reddit_iama_no_root.parquet")

} else if (i == "reddit_movies.csv") {

    write_parquet(df[comment_code != post_id,],"data/validation_dataset_without_root/reddit_movies_no_root.parquet")

} else if (i == "voat_askvoat.csv") {

    write_parquet(df, "data/validation_dataset_without_root/voat_askvoat_no_root.parquet")

} else if (i == "voat_whatever.csv") {

    write_parquet(df, "data/validation_dataset_without_root/voat_whatever_no_root.parquet")

}

}

