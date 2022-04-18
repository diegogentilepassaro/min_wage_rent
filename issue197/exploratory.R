remove(list=ls())

library(data.table)
library(tidyverse)

in_data <- '../drive/base_large/ahs'

data <- fread(file.path(in_data, 'ahs_household_2011_2013.csv'),
              colClasses = list(character='SMSA'))

data[, NUNITS_cat := factor(NUNITS_cat, 
                            levels = c('1 unit', '2 units',
                                       '3 to 4 units','5+ units'))]

data_hh <- data %>%
  filter(TENURE == 2,           # Renting (not owner)
         ZINC2  >  0,           # Non missing household income
         TYPE   == 1) %>%       # "House, apartment, flat" -- not mobile or hotel
  mutate(
    ZINC2_res   = resid(lm(ZINC2 ~ factor(SMSA) , data = .)),
    ZINC2_decil = ntile(ZINC2_res, 10),
    BEDRMS_res  = resid(lm(BEDRMS ~ factor(SMSA) , data = .)))

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
  mutate(RENT_UNITSF=RENT/UNITSF,
    RENT_UNITSF_res = resid(lm(RENT_UNITSF ~ factor(SMSA) , data = .)),
    mean_all = mean(RENT_UNITSF)) %>%
  group_by(ZINC2_decil) %>%
  summarise(mean = mean(RENT_UNITSF_res),
            mean_all = unique(mean_all)) %>%
  mutate(mean = mean + mean_all) %>%
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
  mutate(BEDRMS_mean=mean(BEDRMS)) %>% 
  group_by(ZINC2_decil) %>%
  summarise(mean = mean(BEDRMS_res),
            BEDRMS_mean=unique(BEDRMS_mean),
            mean=mean + BEDRMS_mean) %>%
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
  labs(title = 'Share of households that are owners of their living unit by income decile')

ggsave('sh_rent.png', sh_rent, 
       width = 900, height=700, units = 'px', dpi = 140)

# Person section

data <- fread(file.path(in_data, 'ahs_person_2011_2013.csv'),
              colClasses = list(character='SMSA'))

data[, NUNITS_cat := factor(NUNITS_cat, 
                            levels = c('1 unit', '2 units',
                                       '3 to 4 units','5+ units'))]

data_per <- data %>%
  filter(TENURE == 2,           # Renting (not owner)
         ZINC2  >  0,           # Non missing household income
         TYPE   == 1) %>%       # "House, apartment, flat" -- not mobile or hotel
  mutate(SAL_res  = ifelse(SAL>0, 
                       resid(lm(SAL ~ factor(SMSA), data= .)),
                       NA),
         SAL_cat  = ntile(SAL_res,10),
         HEAD_ind = if_else(REL==1, 1, 0))

hh_members <- data_per %>% 
  group_by(SAL_cat) %>% 
  summarise(mean = mean(PER, na.rm=T)) %>% 
  filter(!is.na(SAL_cat)) %>% 
  ggplot(aes(x=factor(SAL_cat), y=mean)) +
  geom_bar(stat='identity', fill="#5C5D8D") +
  theme_bw() +
  xlab('Person salary decile') +
  ylab('Household members') +
  labs(title = 'Average households members by individual income decile')

ggsave('hh_members.png', hh_members, 
       width = 1000, height=700, units = 'px', dpi = 140)

p_nothead <- data_per %>% 
  group_by(SAL_cat) %>% 
  summarise(mean=mean(HEAD_ind)) %>% 
  filter(!is.na(SAL_cat)) %>% 
  ggplot(aes(x=factor(SAL_cat), y=1-mean)) +
  geom_bar(stat='identity', fill="#FF934F") +
  theme_bw() +
  xlab('Person salary decile') +
  ylab('Probability ind. is not HH head') +
  labs(title = 'Probability individual is not HH head by individual income decile')

ggsave('p_nothead.png', p_nothead, 
       width = 1000, height=700, units = 'px', dpi = 140)


data_per %>% 
  group_by(CONTROL, year) %>% 
  mutate(SAL = ifelse(SAL>0, SAL, NA),
         SAL_mean_hh = mean(SAL, na.rm=T),
         n = sum(!is.na(SAL))) %>% 
  filter(n > 0) %>% 
  mutate(SAL_rest=(n/(n-1))*(SAL_mean_hh - SAL/n),
         SAL_rest_res = ifelse(SAL_rest>0, 
                              resid(lm(SAL_rest ~ factor(SMSA), data= .)),
                              NA),
         SAL_rest_mean = mean(SAL_rest, na.rm=T))
