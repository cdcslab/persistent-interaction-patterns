library(RPostgreSQL)

connect_to_database <- function()
{
  dsn_database = "postgres" #Specify the name of your Database
  dsn_hostname = "localhost"
  dsn_port = 5432                # Specify your port number. e.g. 98939
  dsn_uid = "postgres"         # Specify your username. e.g. "admin"
  dsn_pwd = ""        # Specify your password. e.g. "xxx"
  
  tryCatch({
    drv <- dbDriver("PostgreSQL")
    print("Connecting to Database…")
    db_connection <- dbConnect(
      drv,
      dbname = dsn_database,
      host = dsn_hostname,
      port = dsn_port,
      user = dsn_uid,
      password = dsn_pwd
    )
    print("Database Connected!")
  },
  error = function(cond) {
    print(cond)
  })
  
  return(db_connection)
}

get_comments_columns <- function(data_type_lower)
{
  columns <-
    "(from_id, comment_id, post_id, created_at, likes_count, toxicity_score)"
  return(columns)
}


get_posts_columns <- function(data_type_lower)
{
  columns <-
    "(post_id,from_id,from_name,page_id,created_time,type,link,likes_count,comments_count,shares_count,toxicity_score)"
  return(columns)
}


create_comments_tables <-
  function(database,
           table_name,
           stage_table_name)
  {
    columns <-
      "(from_id, comment_id, post_id, created_at, likes_count, toxicity_score)"
    query_stage_comments_table_creation <-
      paste(
        'CREATE TABLE IF NOT EXISTS',
        stage_table_name,
        '(
    from_id text,
    comment_id text,
    post_id text,
    created_at timestamp,
    likes_count integer,
    toxicity_score real)'
      )
    
    query_comments_table_creation <-
      paste(
        'CREATE TABLE IF NOT EXISTS',
        table_name,
        '(
    from_id text,
    comment_id text PRIMARY KEY,
    post_id text,
    created_at timestamp,
    likes_count integer,
    toxicity_score real)'
      )
    
    dbExecute(database,
              query_stage_comments_table_creation)
    
    dbExecute(database,
              query_comments_table_creation)
    
    dbExecute(database,
              paste("DELETE FROM", stage_table_name, sep = " "))
  }

create_posts_tables <-
  function(database,
           table_name,
           stage_table_name)
  {
    columns <-
      "(post_id,from_id,from_name,page_id,created_time,type,link,likes_count,comments_count,shares_count,toxicity_score)"
    
    query_stage_posts_table_creation <-
      paste(
        'CREATE TABLE IF NOT EXISTS',
        stage_table_name,
        '(
    post_id text PRIMARY KEY,
    from_id text,
    from_name text,
    page_id text,
    created_time timestamp,
    type text,
    link text,
    likes_count integer,
    comments_count integer,
    shares_count integer,
    toxicity_score real)'
      )
    
    query_posts_table_creation <-
      paste(
        'CREATE TABLE IF NOT EXISTS',
        table_name,
        '(
    post_id text PRIMARY KEY,
    from_id text,
    from_name text,
    page_id text,
    created_time timestamp,
    type text,
    link text,
    likes_count integer,
    comments_count integer,
    shares_count integer,
    toxicity_score real)'
      )
    
    dbExecute(database,
              query_stage_posts_table_creation)
    
    dbExecute(database,
              query_posts_table_creation)
    
    dbExecute(database,
              paste("DELETE FROM", stage_table_name, sep = " "))
  }

create_likes_tables <- function(database)
{
  query_table_creation <-
    paste(
      'CREATE TABLE IF NOT EXISTS user_likes
    (
    from_id text,
    post_id text,
    page_id text,
    page_leaning real,
    PRIMARY KEY(from_id, post_id))'
    )
  
  dbExecute(database,
            query_table_creation)
  
  
  query_table_creation <-
    paste(
      'CREATE TABLE IF NOT EXISTS user_likes_tmp
    (
    from_id text,
    post_id text,
    page_id text,
    page_leaning real)'
    )
  
  dbExecute(database,
            query_table_creation)
}

disconnect_from_database <- function(database_connection)
{
  dbDisconnect(database_connection)
}
