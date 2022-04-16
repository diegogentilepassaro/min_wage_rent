remove(list=ls())

library(data.table)
library(tidyverse)

in_files <- '../drive/raw_data/ahs'

varchar <- c('COUNTY', 'STATE', 'SMSA', 'METRO')

varnum <- c('ZINC', 'ZINC2', 'ZINCN','HHPQSAL', 'RENT',
            'TYPE','NUNITS', 'TENURE', 'UNITSF', 'CONDO', 'BEDRMS')

vars <- c(varchar, varnum)

data <- rbindlist(lapply(
  list(2011, 2013),
  \(yy) fread(
    file.path(in_files, paste('AHS', yy, 'Metropolitan PUF'), 'household.csv'),
    select = vars, quote = "'",
    colClasses = list(character = varchar,
                      numeric   = varnum))[, year := yy]), fill = TRUE)

data_hh <- data %>%
  filter(TENURE == 2,           # Renting (not owner)
         ZINC2  >  0,           # Non missing household income
         TYPE   == 1) %>%       # "House, apartment, flat" -- not mobile or hotel
  mutate(
    ZINC2_res   = resid(lm(ZINC2 ~ 1 + factor(SMSA) , data = .)),
    ZINC2_decil = ntile(ZINC2_res, 10),
    RENT_res    = resid(lm(RENT ~ 1 + factor(SMSA) , data = .)),
    NUNITS_cat  = case_when(
      NUNITS == 1 ~ 'Single Unit',
      NUNITS == 2 ~ '2 apartments',
      NUNITS %in% c(3, 4) ~ '3 to 4 apartments',
      NUNITS > 4 ~ '5+ apartments',
      TRUE ~ '-1') %>%
      factor(levels = c('Single Unit', '2 apartments', '3 to 4 apartments',
                        '5+ apartments')))

inc_by_unit <- data_hh %>%
  group_by(ZINC2_decil, NUNITS_cat) %>%
  summarise(n = n()) %>%
  group_by(NUNITS_cat) %>%
  mutate(prop = n / sum(n))  %>%
  ggplot(aes(x = factor(ZINC2_decil), y = prop, fill = NUNITS_cat)) +
  geom_bar(stat = 'identity') +
  facet_grid(NUNITS_cat ~ .) +
  theme_bw() +
  guides(fill = 'none') +
  xlab('Decile') +
  ylab('Proportion') +
  labs(title = 'Income distribution by unit type')

ggsave('inc_by_unit.png', inc_by_unit, width = 600,
       height=1000, units = 'px', dpi = 150)

inc_by_unit_stack <- data_hh %>%
  group_by(ZINC2_decil, NUNITS_cat) %>%
  summarise(n = n()) %>%
  group_by(NUNITS_cat) %>%
  mutate(prop = n / sum(n))  %>%
  ggplot(aes(x = factor(ZINC2_decil), y = prop, fill = NUNITS_cat)) +
  geom_bar(stat = 'identity', position = 'fill') +
  theme_bw() +
  theme(legend.position = 'bottom') +
  xlab('Decile') +
  ylab('Proportion') +
  labs(title = 'Unit type composition by income decile',
       fill  = 'Unit type')

ggsave('inc_by_unit_stack.png', inc_by_unit_stack, 
       width = 900, height=700, units = 'px', dpi = 140)

avg_rent_psqft <- data_hh %>%
  filter(UNITSF > 1,
         RENT  > 1) %>%
  mutate(RENT_res = resid(lm(RENT ~ 1 + factor(SMSA) , data = .)),
         agrent_psqft = RENT_res / UNITSF,
         mean_rent = mean(RENT / UNITSF)) %>%
  group_by(ZINC2_decil) %>%
  summarise(mean = mean(agrent_psqft),
            mean_rent = unique(mean_rent)) %>%
  mutate(mean = mean + mean_rent) %>%
  ggplot(aes(x = factor(ZINC2_decil), y = mean)) +
  geom_bar(stat = 'identity', fill = "#498467") +
  theme_bw() +
  guides(fill = 'none') +
  xlab('Decile') +
  ylab('Rent / Square foot') +
  labs(title = 'Average Rent/Square Foot by income decile')

ggsave('avg_rent_psqft.png', avg_rent_psqft, 
       width = 900, height=700, units = 'px', dpi = 140)

avg_bdrm <- data_hh %>%
  group_by(ZINC2_decil) %>%
  summarise(mean = mean(BEDRMS)) %>%
  ggplot(aes(x = factor(ZINC2_decil), y = mean)) +
  geom_bar(stat = 'identity', fill = "#B2D3A8") +
  theme_bw() +
  guides(fill = 'none') +
  xlab('Decile') +
  ylab('Average number of bedrooms') +
  labs(title = 'Average number of bedrooms in unit by income decile')

ggsave('avg_bdrm.png', avg_bdrm, 
       width = 900, height=700, units = 'px', dpi = 140)

sh_condo <- data_hh %>%
  mutate(CONDO_dummy = ifelse(CONDO == 1, 1, 0)) %>%
  group_by(ZINC2_decil) %>%
  summarise(mean = mean(CONDO_dummy)) %>%
  ggplot(aes(x = factor(ZINC2_decil), y = mean)) +
  geom_bar(stat = 'identity', fill = "#658E9C") +
  theme_bw() +
  guides(fill = 'none') +
  xlab('Decile') +
  ylab('Share') +
  labs(title = 'Share of households living in a condominium by income decile')

ggsave('sh_condo.png', sh_condo, 
       width = 900, height=700, units = 'px', dpi = 140)

sh_rent <- data %>%
  as_tibble() %>%
  filter(TENURE %in% c(1,2),
         ZINC2 > 0,
         TYPE == 1) %>%
  mutate(OWNER_dummy = ifelse(TENURE == 1, 1, 0),
         ZINC2_decil = ntile(resid(lm(ZINC2~1+factor(SMSA) ,data=.)),10)) %>%
  group_by(ZINC2_decil) %>%
  summarise(mean = mean(OWNER_dummy)) %>%
  ggplot(aes(x = factor(ZINC2_decil), y = mean)) +
  geom_bar(stat = 'identity', fill = "#A64253") +
  theme_bw() +
  guides(fill = 'none') +
  xlab('Decile') +
  ylab('Share') +
  coord_cartesian(ylim=c(0,1)) +
  labs(title = 'Share of households that are owners of their household by income decile')

ggsave('sh_rent.png', sh_rent, 
       width = 900, height=700, units = 'px', dpi = 140)
