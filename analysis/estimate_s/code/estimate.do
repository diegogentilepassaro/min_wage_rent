clear all
set more off
set maxvar 32000

program main
    local in_zipcode    "../../../drive/derived_large/zipcode"
    local instub_irs       "../../../drive/base_large/irs_soi"
    local instub_safmr     "../../../base/safmr/output"
    
    clean_irs, instub(`instub_irs')
    save_data "../temp/irs_2014_clean.dta",  log(none)      ///
        key(zipcode) replace
    
    clean_safmr, instub(`instub_safmr')
    save_data "../temp/safmr_2014_clean.dta",     log(none)      ///
        key(zipcode) replace 

    use zipcode countyfips statefips cbsa place_code n_workers_acs2014 med_hhld_inc_acs2014 ///
        sh_white_cens2010 sh_black_cens2010 sh_male_cens2010 sh_urb_pop_cens2010 ///
        sh_rural_pop_cens2010 sh_hhlds_urban_cens2010 sh_hhlds_renteroccup_cens2010 ///
        population_cens2010 n_male_cens2010 n_white_cens2010 n_black_cens2010 urb_pop_cens2010 ///
        n_hhlds_cens2010 n_hhlds_urban_cens2010 n_hhlds_renteroccup_cens2010 ///
        rural_pop_cens2010 population_acs2014 sh_residents_under29_2014 sh_residents_30to54_2014 ///
        sh_residents_under1250_2014 sh_residents_1250_3333_2014 sh_residents_underHS_2014 ///
        sh_residents_HS_noColl_2014 sh_residents_manuf_2014 sh_residents_accomm_food_2014 ///
        sh_residents_retail_2014 sh_residents_finance_2014 sh_workers_under29_2014 sh_workers_30to54_2014 ///
        sh_workers_under1250_2014 sh_workers_1250_3333_2014 sh_workers_underHS_2014 ///
        sh_workers_HS_noColl_2014 sh_workers_manuf_2014 sh_workers_accomm_food_2014 ///
        sh_workers_retail_2014 sh_workers_finance_2014 using "`in_zipcode'/zipcode_cross.dta", clear
    merge 1:1 zipcode using "../temp/irs_2014_clean.dta", ///
        nogen keep(1 3)
    merge 1:1 zipcode using "../temp/safmr_2014_clean.dta", ///
        nogen keep(1 3)
    gen s = safmr2br/(wage_per_wage_hhld/12)
    
    foreach var in safmr1br safmr2br safmr3br {
        bysort statefips:  egen state_avg_`var' = mean(`var')
        bysort cbsa:       egen cbsa_avg_`var' = mean(`var')
        bysort countyfips: egen county_avg_`var' = mean(`var')
        bysort place_code: egen place_avg_`var' = mean(`var')
    }
    
    impute_var, var(safmr2br)
    impute_var, var(wage_per_wage_hhld)
    
	gen s_imputed = safmr2br_imputed/(wage_per_wage_hhld_imputed/12)
	
    keep zipcode s safmr2br wage_per_wage_hhld *imputed
    save_data "../output/s_by_zip.dta", key(zipcode) replace
end



program clean_irs 
    syntax, instub(str)
    
    use "`instub'/irs_zip.dta", clear

    drop if inlist(zipcode, "0", "00000", "99999")    
    keep if year == 2014
    
    keep zipcode statefips share_wage_hhlds share_bussiness_hhlds /// 
         share_farmer_hhlds agi_per_hhld wage_per_wage_hhld       ///
         wage_per_hhld bussines_rev_per_owner
end

program clean_safmr 
    syntax, instub(str)
    
    use "`instub'/safmr_2012_2016_by_zipcode_county_cbsa.dta", clear
    keep zipcode countyfips cbsa year safmr1br safmr2br safmr3br
    keep if year == 2014
    drop year
    collapse (mean) safmr*, by(zipcode)
end

program impute_var
    syntax, var(str)
    reg `var' n_workers_acs2014 med_hhld_inc_acs2014 c.med_hhld_inc_acs2014#c.med_hhld_inc_acs2014 ///
        sh_white_cens2010 c.sh_white_cens2010#c.sh_white_cens2010 sh_black_cens2010 ///
        sh_male_cens2010 sh_urb_pop_cens2010 sh_hhlds_urban_cens2010 sh_hhlds_renteroccup_cens2010 ///
        population_cens2010 n_male_cens2010 n_white_cens2010 n_black_cens2010 urb_pop_cens2010 ///
        n_hhlds_cens2010 n_hhlds_urban_cens2010 n_hhlds_renteroccup_cens2010 population_acs2014 ///
        sh_residents* sh_workers* state_avg* cbsa_avg*
    predict `var'_pred, xb
    gen `var'_imputed = `var'
    replace `var'_imputed = `var'_pred if (missing(`var') & !missing(`var'_pred))
end



main
