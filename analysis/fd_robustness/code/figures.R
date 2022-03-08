remove(list=ls())
library(dplyr)
library(readr)
library(ggplot2)

main <- function() {
  instub  <- "../output"
  outstub <- "../output"
  
  df <- read_csv(file.path(instub, "estimates_static.csv"))
  
  t = 1.96
  df <- df %>%
    filter(var != "cumsum_from0") %>%
    mutate(b_lb = b - t*se,
           b_ub = b + t*se)
  
  df.geotrends <- df %>% filter(model %in% c("baseline", 'county_timefe', "cbsa_timefe", "state_timefe"))
  
  ggplot(df.geotrends, aes(y = var)) +
    geom_point(aes(x = b), size = 2.5) +
    geom_errorbar(aes(xmin = b_lb, xmax = b_ub), width = 0.1) +
    facet_column(~model, strip.position = "left") +
    theme_bw() 
}

main()
