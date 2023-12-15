resize_last_bin_lifetime <-
  function(df,
           n_bin = 21,
           bin_threshold = 50) {
    last_bin = max(df$discretized_bin_label)
    df$resize_length = df$lifetime
    number_of_conversations_in_last_bin = nrow(df[discretized_bin_label ==
                                                    last_bin])
    
    df$resize_discretized_bin_label = df$discretized_bin_label
    
    while (number_of_conversations_in_last_bin < bin_threshold) {
      cat(
        paste(
          "In the bin containing the longest conversations (bin:",
          last_bin,
          "), there are only",
          number_of_conversations_in_last_bin,
          "conversations instead of",
          bin_threshold,
          ".\nPerforming resizing.\n"
        )
      )
      
      # Update the largest size of the thread with the second one
      lifetime_length <- unique(df$resize_length)
      lifetime_length <- sort(lifetime_length)
      
      max_length <- lifetime_length[length(lifetime_length)]
      second_max_length <-
        lifetime_length[length(lifetime_length) - 1]
      
      df$resize_length[df$resize_length == max_length] <-
        second_max_length
      
      df$resize_discretized_bin_label <-
        log_bin(df$resize_length, n_bin)
      
      last_bin <- max(df$resize_discretized_bin_label)
      number_of_conversations_in_last_bin <-
        nrow(df[resize_discretized_bin_label == last_bin])
      
      cat(
        paste(
          "The largest bin is now",
          last_bin,
          "with",
          number_of_conversations_in_last_bin,
          "conversations.\n"
        )
      )
      
    }
    
    return(df)
    
  }
