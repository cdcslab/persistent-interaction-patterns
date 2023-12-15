participation <- function(x) {
  return(length(unique(x)) / length(x))
  
}

regression_coefficient <- function(participation) {
  x = seq(0, 1, length.out = length(participation))
  model = lm(participation ~ x)
  
  # Get only the slope value
  return(as.numeric(model$coefficients[2]))
  
}