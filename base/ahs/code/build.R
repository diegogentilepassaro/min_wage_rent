remove(list = ls())

library(data.table)

source('../../../lib/R/save_data.R')

main <- function() {
  in_raw   <- '../../../drive/raw_data/ahs'
  out_data <- '../../../drive/base_large/ahs'
  
  varchar <- c('COUNTY', 'STATE', 'SMSA', 'METRO', 'CONTROL')
  
  # Household section
  
  varnum <- c('ZINC', 'ZINC2', 'HHPQSAL', 'RENT', 'TYPE', 'NUNITS', 'TENURE',
              'UNITSF', 'CONDO', 'BEDRMS', 'PER', 'HHPLINE')

  data <- load_data('household', varchar, varnum, in_raw)
  
  names_new <- c('fam_income', 'hh_income', 'hh_wageincome_ind', 'monthly_hh_rent', 'type',
                 'n_units', 'tenure', 'unit_sqft', 'is_condo_coop', 'n_bedrms', 
                 'n_persons', 'head_person_num')
  
  setnames(data, varnum, names_new)
  
  data[, n_units_cat := fcase(
    n_units == 1         , '1 unit',
    n_units == 2         , '2 units',
    n_units %in% c(3, 4) , '3 to 4 units',
    n_units > 4          , '5+ units')]
  
  data[,`:=`(house_apartment_unit    = 1 * (type == 1),
             mobile_unit             = 1 * (type %in% c(2,3)),
             hotel_unit              = 1 * (type %in% c(4,5)),
             rooming_unit            = 1 * (type == 6),
             boat_other_unit         = 1 * (type %in% c(7,8,9)),
             is_condo_coop           = 1 * (is_condo_coop == 1),
             is_tenant               = 1 * (tenure == 2),
             is_owner                = 1 * (tenure == 1))]
  
  set(data, j=c('type', 'tenure'), value=NULL)
  
  save_data(data, 'household_id',
            file.path(out_data, 'household_2011_2013.csv'),
            logfile = '../output/data_file_manifest.log')
  
  hh_id_smsa <- unique(data[,c('smsa', 'household_id')])
  
  setkey(hh_id_smsa, 'household_id')
  
  # Person section
  
  varnum <- c('REL', 'SAL', 'PLINE', 'AGE', 'GRAD', 'SEX')

  data  <- load_data('person', varchar, varnum, in_raw)
  
  names_new <- c('relation_to_hh_head', 'person_salary', 'person_num',
                 'age', 'educ_level', 'sex')
  
  setnames(data, varnum, names_new)
  
  set(data, j='smsa', value=NULL)
  
  data[, hh_head := 1 * (relation_to_hh_head == 1 | relation_to_hh_head == 2)]
  
  setkey(data, 'household_id')

  data <- data[hh_id_smsa, nomatch=NULL]
  
  save_data(data, c('household_id', 'person_num'),
            file.path(out_data, 'person_2011_2013.csv'),
            logfile = '../output/data_file_manifest.log')
  
}

load_data <- function(survey, varchar, varnum, in_raw) {
  
  vars <- c(varchar, varnum)
  
  data <- lapply(list(2011, 2013),
                 \(yy) fread(file.path(in_raw, 
                                       paste('AHS', yy, 'Metropolitan PUF'),
                                       paste0(survey, '.csv')), 
                             select = vars, quote = "'", 
                             colClasses = list(character = varchar, 
                                               numeric   = varnum))[, year := yy])
  
  data <- rbindlist(data, fill=TRUE)
  
  names_old <- c('CONTROL', 'COUNTY', 'STATE', 'SMSA', 'METRO')
  
  names_new <- c('household_id', 'county', 'state', 'smsa', 'metro')
  
  setnames(data, names_old, names_new, skip_absent = T)
  
  # Set all negative values to NA. These can be -6 and -9, which mean not applicable
  # or didn't answer.
  
  data <- data[, (varnum) := lapply(.SD, \(x) fifelse(x<0, NA_real_, x)), 
               .SDcols = varnum] 

  return(data)
}

main()
