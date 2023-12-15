log_bin <- function(thread_length, n_bin) {
  # n_bin : the number of intervals, not the edges.
  
  min_thread_length <- log10(min(thread_length))
  max_thread_length <- log10(max(thread_length))
  
  bin_edges <- 10 ^ seq(min_thread_length, max_thread_length,
                        length.out = n_bin + 1)
  cat(bin_edges, "\n")
  
  # Discrete labels to assign to each bin
  
  discretized_bin_labels <- seq(0, 1,
                                length.out = n_bin)
  
  # Assign each thread to its (labelled) bin
  
  bin_positions <- cut(
    thread_length,
    breaks = bin_edges,
    right = T,
    include.lowest = T,
    labels = discretized_bin_labels,
    ordered_result = TRUE
  )
  
  # I'm sure that only the threads having minimum and maximum size are NA
  
  bin_positions[which(thread_length == min(thread_length))] <-
    factor(0)
  bin_positions[which(thread_length == max(thread_length))] <-
    factor(1)
  
  return(bin_positions)
}

linear_bin <- function(x,
                       n_bin = 20) {
  if (length(x) > 1) {
    comment_position <- seq(1, length(x))
    discretized_bin_labels <- seq(0, 1, length.out = n_bin)
    
    bin_positions <- cut(
      comment_position,
      breaks = n_bin,
      labels = discretized_bin_labels,
      right = T,
      ordered_result = TRUE,
      include.lowest = T
    )
  } else {
    warning("The vector has length 1")
    bin_positions <- 1
  }
  
  return(bin_positions)
}

resize_last_bin <-
  function(df,
           n_bin = 21,
           bin_threshold = 50) {
    last_bin <- max(df$discretized_bin_label)
    df$resize_length = df$thread_length
    number_of_conversations_in_last_bin = nrow(df[discretized_bin_label ==
                                                    last_bin])
    
    df$resize_discretized_bin_label <- df$discretized_bin_label
    
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
      
      thread_length <- unique(df$resize_length)
      thread_length <- sort(thread_length)
      
      max_length <- thread_length[length(thread_length)]
      second_max_length <- thread_length[length(thread_length) - 1]
      
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
