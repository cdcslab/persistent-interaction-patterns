# Use this function to unify columns of data

# We use the following names:
# thread identifier: root_submission
# id of the user: user
# date identifier: date
# likes/upvotes identifier : like_count
# comment identifier: comment_id
# text of the comment: text

unify_dataset_columns = function(df, social) {
  if (social == "youtube") {
    df <- df %>%
      rename("date" = "created_at",
             "root_submission" = "post_id",
             "user" = "user_name")
    
  } else if (social == "gab") {
    df <- df %>%
      rename("date" = "created_at",
             "root_submission" = "post_id",
             "user" = "user") %>%
      mutate(topic = "Feed")
    
  } else if (social == "usenet") {
    df <- df %>%
      rename("user" = "author_id",
             "root_submission" = "thread_id",
             "date" = "created_at")
    
  } else if (social == "twitter") {
    df <- df %>%
      rename("user" = "author_id",
             "root_submission" = "post_id",
             "date" = "created_at") %>%
      mutate(like_count = unlist(like_count))
    
  } else if (social == "reddit") {
    df <- df %>%
      rename(
        "user" = "user_id",
        "root_submission" = "post_id",
        "comment_id" = "id",
        "text" = "comment_text"
      )
    
  } else if (social == "telegram") {
    df <- df %>%
      rename("user" = "user_id",
             "root_submission" = "post_id",
             "date" = "date")
    
  } else if (social == "voat") {
    df <- df %>%
      mutate(date = NULL, time = NULL) %>%
      rename(
        "user" = "user",
        "root_submission" = "root_submission",
        "date" = "created_at",
        "like_count" = "upvotes"
      )
    
    
  } else if (social == "facebook") {
    df <- df %>%
      rename("user" = "user_id",
             "root_submission" = "post_id",
             "date" = "created_at")
    
  } else if (social == "facebook_news") {
    df <- df %>%
      rename(
        "user" = "user_id",
        "root_submission" = "post_id",
        "date" = "created_at",
        "like_count" = "likes_count"
      ) %>%
      mutate(social = "Facebook", topic = "News")
    
  }
  
}
