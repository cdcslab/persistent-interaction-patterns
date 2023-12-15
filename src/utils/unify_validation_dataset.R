unify_validation_dataset <- function(df,i) {
    
    # This script unify and preprocess the validation dataset
    # We use the following names:
    # thread identifier: root_submission
    # id of the user: user
    # date identifier: date
    # likes/upvotes identifier : like_count
    # comment identifier: comment_id

    if (i == "reddit_askreddit_no_root.parquet") {

        df = df %>% 
            rename("user" = "user_id",
            "root_submission" = "post_id",
            "comment_id" = "comment_code",
            "date" = "comment_date",
            "text" = "comment_text") %>%
            mutate(social = "Reddit",
                   topic = "Askreddit")

    } else if (i == "youtube_carbonara_no_root.parquet") {

        df = df %>% 
            rename("user" = "user_channel_url",
            "root_submission" = "video_id",
            "date" = "published_at",
            "text" = "comment_text_original") %>%
            mutate(social = "YouTube",
                   topic = "Carbonara")
    
    } else if (i == "facebook_film_no_root.parquet") {

        df = df %>% 
            rename("user" = "from_id",
            "root_submission" = "post_id",
            "date" = "created_time",
            "like_count" = "likes_count",
            "text" = "message_y") %>%
            mutate(social = "Facebook",
                   topic = "Film")        
        
    } else if (i == "facebook_sports_no_root.parquet") {

        df = df %>% 
            rename("user" = "from_id",
            "root_submission" = "post_id",
            "date" = "created_time",
            "like_count" = "likes_count",
            "text" = "message_y") %>%
            mutate(social = "Facebook",
                   topic = "Sports")        
        
    } else if (i == "twitter_got_no_root.parquet") {

        df = df %>% 
            rename("user" = "author_id",
            "root_submission" = "conversation_id",
            "date" = "created_at",
            "comment_id" = "id") %>%
            mutate(social = "Twitter",
                   topic = "Got")   

    } else if (i == "twitter_nasa_no_root.parquet") {

        df = df %>% 
            rename("user" = "author_id",
            "root_submission" = "conversation_id",
            "date" = "created_at",
            "comment_id" = "id") %>%
            mutate(social = "Twitter",
                   topic = "Nasa")   

    } else if (i == "telegram_crypto_no_root.parquet") {

        df = df %>% 
            rename("user" = "from_id",
            "root_submission" = "root",
            "date" = "date",
            "comment_id" = "id") %>%
            mutate(social = "Telegram",
                   topic = "Crypto")   

    } else if (i == "youtube_football_no_root.parquet") {

        df = df %>% 
            rename("user" = "user_id",
            "root_submission" = "video_id",
            "date" = "created_at_comment",
            "like_count" = "like_count_comment",
            "video_text" = "text") %>%
            rename("text" = "comment_text_original") %>%
            mutate(social = "YouTube",
                   topic = "Football")  


    } else if (i == "reddit_iama_no_root.parquet") {

        df = df %>% 
             rename("user" = "user_id",
             "root_submission" = "post_id",
             "comment_id" = "comment_code",
             "date" = "comment_date",
             "text" = "comment_text") %>%
             mutate(social = "Reddit",
                   topic = "Iama")
        
    } else if (i == "reddit_movies_no_root.parquet") {

        df = df %>% 
             rename("user" = "user_id",
             "root_submission" = "post_id",
             "comment_id" = "comment_code",
             "date" = "comment_date",
             "text" = "comment_text") %>%
             mutate(social = "Reddit",
                   topic = "Movies")

    } else if (i == "voat_askvoat_no_root.parquet") {

        df = df %>% 
            rename("user" = "user",
            "root_submission" = "root_submission",
            "date" = "date",
            "like_count" = "upvotes",
            "text" = "body") %>%
             mutate(social = "Voat",
                   topic = "Askvoat")

    } else if (i == "voat_whatever_no_root.parquet") {

        df = df %>% 
            rename("user" = "user",
            "root_submission" = "root_submission",
            "date" = "date",
            "like_count" = "upvotes",
            "text" = "body") %>%
             mutate(social = "Voat",
                   topic = "Whatever")

    }
    
    return(df)
    
}
