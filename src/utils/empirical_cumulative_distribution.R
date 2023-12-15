empirical_cumulative_distribution <- function(x) {
  
  x = sort(x)
  l_x = length(x)
  f = table(x)
  l_f = length(f)
  ccdf = rep(0,l_f)

  for (i in 1:l_f) {

    ccdf[i] = sum(f[i:l_f])/l_x

  }

  result <- tibble(toxicity_values = unique(x), 
                   ccdf = ccdf)
  return(result)
}

empirical_cumulative_distribution_all <- function(x) {
  
  x = sort(x)
  ccdf = rep(0,length(x))
  
  for (i in 1:length(ccdf)) {
    
    ccdf[i] = sum(x >= x[i])/length(x)
    
  }
  
  return(ccdf)
  
}
