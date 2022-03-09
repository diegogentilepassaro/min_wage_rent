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
  
  ggplot(df.geotrends, 
         aes(y = var, color = model)) +
    geom_point(aes(x = b), size = 2.5, 
               position = position_dodge(0.3)) +
    geom_errorbar(aes(xmin = b_lb, xmax = b_ub), width = 0.1,
                   position = position_dodge(0.3)) +
    labs(x = "Coefficient", y = "") +
    theme_bw() 

  ggsave('../output/geotrends.png', dpi = 300,
         width = 7, height = 5)
}

main()
