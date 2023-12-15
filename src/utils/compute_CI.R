compute_CI <- function(x) {
  
  result = t.test(x)
  return(as.numeric(result$conf.int))
  
}