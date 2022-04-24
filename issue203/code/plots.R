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
  mutate(hh_income_decile = ntile(resid(lm(hh_income ~ 1 + factor(smsa), data = .)), 10)) %>%
  group_by(hh_income_decile) %>%
  summarise(mean = mean(is_tenant)) %>%
  ggplot(aes(x = factor(hh_income_decile), y = mean)) +
  geom_bar(stat = 'identity', fill = "#A64253") +
  theme_bw() +
  guides(fill = 'none') +
  xlab('Household income decile') +
  ylab('Share renter households') +
  coord_cartesian(ylim = c(0, 1)) +
  theme(panel.grid.major.x = element_blank()) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))

ggsave('../output/share_renters.png', sh_rent, width = 2221, height = 1615, dpi=300, 
       units = 'px')
