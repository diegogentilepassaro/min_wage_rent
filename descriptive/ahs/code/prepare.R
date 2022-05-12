remove(list = ls())

library(dplyr)
library(readr)

main <- function() {
  in_data <- '../../../drive/base_large/ahs'
  varchar <- c('smsa', 'county', 'state', 'household_id')
  
  hh_data <- read_csv(file.path(in_data, 'household_2011_2013.csv'))
  
  hh_data <- hh_data %>% 
    filter(is_owner == 1 | is_tenant == 1, 
           hh_income > 0,
           house_apartment_unit == 1) %>% 
    mutate(hh_income_res      = resid(lm(hh_income ~ factor(smsa) , data = .)),
           hh_income_decile   = ntile(hh_income_res, 10))
  
  hh_data_renters <- hh_data %>% 
    filter(is_tenant ==1) %>% 
    mutate(hh_income_res      = resid(lm(hh_income ~ factor(smsa) , data = .)),
           hh_income_decile   = ntile(hh_income_res, 10))
  
  person_data <- read_csv(file.path(in_data, 'person_2011_2013.csv'))
  
  sh_renters <- hh_data %>%
    mutate(pr_tenant_res      = resid(lm(is_tenant ~ factor(smsa) , data = .)),
           pr_tenant          = pr_tenant_res + mean(is_tenant)) %>%
    group_by(hh_income_decile) %>%
    summarise(pr_tenant = mean(pr_tenant))
  
  sh_unit_types <- hh_data_renters %>%
    group_by(hh_income_decile, n_units_cat) %>%
    summarise(count_unit_type = n()) %>%
    group_by(hh_income_decile) %>%
    mutate(sh_unit_type = count_unit_type / sum(count_unit_type)) %>% 
    select(-count_unit_type)
  
  sh_condo <- hh_data_renters %>%
    mutate(sh_condo_res       = resid(lm(is_condo_coop ~ factor(smsa) , data = .)),
           sh_condo           = sh_condo_res + mean(is_condo_coop)) %>%
    group_by(hh_income_decile) %>%
    summarise(sh_condo = mean(sh_condo))
  
  avg_sqft <- hh_data_renters %>%
    mutate(unit_sqft_res      = resid(lm(unit_sqft ~ factor(smsa) , data = ., na.action=na.exclude)),
           unit_sqft          = unit_sqft_res + mean(unit_sqft, na.rm=T)) %>%
    group_by(hh_income_decile) %>%
    summarise(avg_sqft = mean(unit_sqft, na.rm=T))
  
  avg_rent <- hh_data_renters %>%
    mutate(monthly_hh_rent_res = resid(lm(monthly_hh_rent ~ factor(smsa) , data = ., na.action=na.exclude)),
           monthly_hh_rent     = monthly_hh_rent_res + mean(monthly_hh_rent, na.rm=T)) %>%
    group_by(hh_income_decile) %>%
    summarise(avg_rent = mean(monthly_hh_rent, na.rm=T))
  
  avg_rent_psqft <- hh_data_renters %>%
    mutate(rent_psqft     = monthly_hh_rent / unit_sqft, 
           rent_psqft_res = resid(lm(rent_psqft ~ factor(smsa) , data = ., na.action=na.exclude)),
           rent_psqft     = rent_psqft_res + mean(rent_psqft, na.rm=T)) %>%
    group_by(hh_income_decile) %>%
    summarise(avg_rent_psqft = mean(rent_psqft, na.rm=T))
  
  sh_hh_head <- person_data %>%
    left_join(hh_data[, c('household_id', 'is_tenant', 'house_apartment_unit', 'smsa')], 
              by = 'household_id') %>%
    filter(is_tenant             == 1,
           house_apartment_unit  == 1,
           person_salary         >  0) %>% 
    group_by(household_id) %>%
    mutate(max_income   =  max(person_salary),
           hh_head_max  =  1 * (person_salary == max_income)) %>%
    ungroup %>% 
    mutate(person_salary_res      = resid(lm(person_salary ~ factor(smsa) , data = .)),
           person_salary_decile   = ntile(person_salary_res, 10),
           hh_head_max_res        = resid(lm(hh_head_max ~ factor(smsa) , data = .)),
           hh_head_max            = hh_head_max_res + mean(hh_head_max)) %>%
    group_by(person_salary_decile) %>%
    summarise(sh_hh_head_max = mean(hh_head_max))
  
  plots <- c('sh_renters', 'sh_unit_types', 'sh_condo', 'sh_hh_head', 'avg_rent',
             'avg_sqft', 'avg_rent_psqft')
  for (pp in plots) {
    write_csv(get(pp), paste0('../output/', pp, '.csv'))
  }
  
}

main()
