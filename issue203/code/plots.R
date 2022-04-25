remove(list=ls())

library(data.table)
library(tidyverse)

in_data <- '../../drive/base_large/ahs'

data <- fread(file.path(in_data, 'household_2011_2013.csv'),
              colClasses = list(character = 'smsa'))

sh_rent <- data %>%
  filter((is_owner + is_tenant) == 1,
         !is.na(hh_income),
         house_apartment_unit == 1) %>%
  group_by(smsa) %>%
  mutate(hh_income_decile = ntile(hh_income, 10)) %>%
  ungroup %>%
  group_by(hh_income_decile) %>%
  summarise(pr_tenant = mean(is_tenant)) %>%
  ggplot(aes(x = factor(hh_income_decile), y = pr_tenant)) +
  geom_bar(stat = 'identity', fill = "#A64253") +
  theme_bw() +
  guides(fill = 'none') +
  xlab('Household income decile (within SMSA)') +
  ylab('Probability housing is rented') +
  coord_cartesian(ylim = c(0, 0.8)) +
  theme(panel.grid.major.x = element_blank())

ggsave('../output/share_renters.png', sh_rent, width = 2221, height = 1615, dpi=300, 
       units = 'px')
