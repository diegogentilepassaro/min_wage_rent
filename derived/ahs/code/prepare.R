remove(list = ls())

library(dplyr)
library(readr)

main <- function() {
  in_data <- '../../../drive/base_large/ahs'
  varchar <- c('smsa', 'county', 'state', 'household_id')
  
  hh_data     <- read_csv(file.path(in_data, 'household_2011_2013.csv'))
  person_data <- read_csv(file.path(in_data, 'person_2011_2013.csv'))
  
  sh_renters <- hh_data %>%
    filter((is_owner + is_tenant) == 1, 
           !is.na(hh_income),
           house_apartment_unit == 1) %>%
    group_by(smsa) %>%
    mutate(hh_income_decile = ntile(hh_income, 10)) %>%
    group_by(hh_income_decile) %>%
    summarise(pr_tenant = mean(is_tenant))
  
  sh_unit_types <- hh_data %>%
    filter(is_tenant == 1,
           !is.na(hh_income),
      house_apartment_unit == 1) %>%
    group_by(smsa) %>%
    mutate(hh_income_decile = ntile(hh_income, 10)) %>%
    group_by(hh_income_decile, n_units_cat) %>%
    summarise(count_unit_type = n()) %>%
    group_by(hh_income_decile) %>%
    mutate(sh_unit_type = count_unit_type / sum(count_unit_type)) %>% 
    select(-count_unit_type)
  
  sh_condo <- hh_data %>%
    filter(is_tenant == 1,
      hh_income > 0,
      house_apartment_unit == 1) %>%
    group_by(smsa) %>%
    mutate(hh_income_decile = ntile(hh_income, 10)) %>%
    group_by(hh_income_decile) %>%
    summarise(sh_condo = mean(is_condo_coop))
  
  sh_hh_head <- person_data %>%
    left_join(hh_data[, c('household_id', 'is_tenant', 'hh_income')], by = 'household_id') %>%
    filter(is_tenant == 1,
      person_salary > 0) %>% # Está bien hacer esto?
    group_by(household_id) %>%
    mutate(max_income   =  max(person_salary),
           hh_head_max  =  1 * (person_salary == max_income)) %>%
    group_by(smsa) %>%
    mutate(person_salary_decile = ntile(person_salary, 10)) %>%
    group_by(person_salary_decile) %>%
    summarise(sh_hh_head_max = mean(hh_head_max))
  
  plots <- c('sh_renters', 'sh_unit_types', 'sh_condo', 'sh_hh_head')
  for (pp in plots) {
    write_csv(get(pp), paste0('../output/', pp, '.csv'))
  }
  
}

main()
