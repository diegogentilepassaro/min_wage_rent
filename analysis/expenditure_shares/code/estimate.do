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
    
    create_vars

    gen wage_per_whhld_monthly = wage_per_wage_hhld/12
    gen s = safmr2br/wage_per_whhld_monthly
    
    impute_var, var(safmr2br)
    impute_var, var(wage_per_whhld_monthly)
    impute_var, var(s)
        
    keep zipcode s safmr2br wage_per_whhld_monthly *imputed
    save_data "`outstub'/s_by_zip.dta", key(zipcode) ///
        log(../output/data_file_manifest.log) replace
end

program create_vars

    rename *hhlds_renteroccup* *hhl_ro*
    rename *hhlds_urban*       *hhld_ur*

    gen med_hhld_inc    = med_hhld_inc_acs2014
    gen med_hhld_inc_sq = med_hhld_inc_acs2014^2
    gen n_workers       = n_workers_acs2014
    gen inc_x_n_workers = med_hhld_inc*n_workers_acs2014

    foreach var in population n_male n_white n_black n_hhlds n_hhld_ur n_hhl_ro {
        gen inc_x_`var' = med_hhld_inc*`var'_cens2010
    }

    foreach var in white black male urb_pop hhl_ro hhld_ur {
        foreach var in white black male urb_pop hhl_ro hhld_ur {
            cap gen sh_`var'_x_sh_`var' = sh_`var'_cens2010*sh_`var'_cens2010
        }
    }
    
    foreach var in statefips cbsa countyfips place_code {
        replace `var' = "missing" if missing(`var')
    }
    egen geo_group = group(statefips cbsa countyfips) //place_code
end

program impute_var
    syntax, var(str)
    reghdfe `var' med_hhld_inc n_workers inc_x* ///
        population_cens2010 n_male_cens2010 n_white_cens2010 n_black_cens2010 urb_pop_cens2010 ///
        n_hhlds_cens2010 n_hhld_ur_cens2010 n_hhl_ro_cens2010 ///
        sh_white* sh_black* sh_male* sh_urb_pop* sh_hhld* ///
        sh_residents* sh_workers*, absorb(FE = geo_group) savefe resid

    bys geo_group (FE): replace FE = FE[1]
    replace FE = 0 if missing(FE)
    predict xb, xb
    gen `var'_pred = xb + FE
	drop FE xb

    gen     `var'_imputed = `var'
    replace `var'_imputed = `var'_pred if (missing(`var') & !missing(`var'_pred))

    qui sum `var'_imputed, d
    replace `var'_imputed = r(p1) if `var'_imputed  < r(p1)
    replace `var'_imputed = r(p99) if `var'_imputed > r(p99)
end



main
