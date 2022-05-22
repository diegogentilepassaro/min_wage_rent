clear all
set more off
set maxvar 32000
set matsize 10000

program main
    local in_zipcode  "../../../drive/derived_large/zipcode"
    local in_zip_yr   "../../../drive/derived_large/zipcode_year"
    local outstub     "../../../drive/analysis_large/expenditure_shares"

    use "`in_zip_yr'/zipcode_year.dta", clear
    keep if year == 2018
    keep zipcode statefips countyfips cbsa agi_per_hhld wage_per_wage_hhld       ///
        wage_per_hhld bussines_rev_per_owner safmr1br safmr2br safmr3br
    save "../temp/irs_safmr_2018.dta", replace

    use zipcode countyfips statefips cbsa ///
        place_code *_cens2010 *_acs2014 sh_residents_* sh_workers_* ///
        using "`in_zipcode'/zipcode_cross.dta", clear
    merge 1:1 zipcode using "../temp/irs_safmr_2018.dta", ///
        nogen keep(1 3)
    
    gen wage_per_whhld_monthly = wage_per_wage_hhld/12
    gen s = safmr2br/wage_per_whhld_monthly
    
    foreach var in statefips cbsa countyfips place_code {
        replace `var' = "missing" if missing(`var')
    }
    egen geo_group = group(statefips cbsa countyfips place_code)

    impute_var, var(safmr2br)
    impute_var, var(wage_per_whhld_monthly)
    impute_var, var(s)
        
    keep zipcode s safmr2br wage_per_whhld_monthly *imputed
    save_data "`outstub'/s_by_zip.dta", key(zipcode) ///
        log(../output/data_file_manifest.log) replace
end

program impute_var
    syntax, var(str)
    reghdfe `var' n_workers_acs2014 med_hhld_inc_acs2014 c.med_hhld_inc_acs2014#c.med_hhld_inc_acs2014 ///
        sh_white_cens2010 c.sh_white_cens2010#c.sh_white_cens2010 sh_black_cens2010 ///
        sh_male_cens2010 sh_urb_pop_cens2010 sh_hhlds_urban_cens2010 sh_hhlds_renteroccup_cens2010 ///
        population_cens2010 n_male_cens2010 n_white_cens2010 n_black_cens2010 urb_pop_cens2010 ///
        n_hhlds_cens2010 n_hhlds_urban_cens2010 n_hhlds_renteroccup_cens2010 population_acs2014 ///
        sh_residents* sh_workers*, absorb(FE = geo_group) savefe resid

    bys geo_group (FE): replace FE = FE[1]
    replace FE = 0 if missing(FE)
    predict xb, xb
    gen `var'_pred = xb + FE
    gen `var'_imputed = `var'
    replace `var'_imputed = `var'_pred if (missing(`var') & !missing(`var'_pred))
	drop FE xb
end



main
