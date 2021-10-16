set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_base_large "../../../drive/base_large"
    local in_der_large  "../../../drive/derived_large"
    local in_qcew       "../../../base/qcew/output"
    local outstub       "../../../drive/derived_large/zipcode_year"
    local logfile       "../output/data_file_manifest.log"

    use zipcode statefips countyfips cbsa10 year month zcta            ///
        actual_mw exp_ln_mw* medrent* medlisting* Sale_Counts Monthly* ///
        using  "`in_der_large'/zipcode_month/zipcode_month_panel.dta"

    make_yearly_data

    clean_irs_data,    instub(`in_base_large')
    clean_area_shares, instub(`in_base_large')
    clean_od_shares,   instub(`in_der_large')
    clean_qcew,        instub(`in_qcew')
    
    clear
    use "../temp/mw_rents_data.dta"
    merge 1:1 zipcode    year using "../temp/irs_data.dta",         nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/workplace_shares.dta", nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/residence_shares.dta", nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/od_shares.dta",        nogen keep(1 3)
    merge m:1 countyfips year using "../temp/qcew_data.dta",        nogen keep(1 3)

    merge_acs_pop, instub(`in_base_large')

    save_data "`outstub'/zipcode_year.dta", key(zipcode year) ///
        log(`logfile') replace
end

program make_yearly_data

    gen ln_mw           = log(actual_mw)
    gen ln_med_rent_var = log(medrentprice_SFCC)
    gen ln_sale_counts  = log(Sale_Counts)
    gen ln_monthly_listings = log(Monthlylistings_NSA_SFCC)

    qui describe exp*, varlist
    local exp_mw_vars = r(varlist)

    local vars ln_mw ln_med_rent_var `exp_mw_vars' ln_sale_counts ln_monthly_listings

    keep zipcode year zcta countyfips cbsa10 statefips month `vars'

    foreach var of local vars {
        bys zipcode year: egen `var'_avg = mean(`var')
    }

    bysort zipcode year (month): keep if _n == 1
    drop month
    
    save "../temp/mw_rents_data.dta", replace
end

program clean_irs_data
    syntax, instub(str)
    
    use "`instub'/irs_soi/irs_zip.dta", clear
    
    gen ln_agi_per_cap            = log(agi_per_cap)
    gen ln_wage_per_cap           = log(wage_per_cap)
    gen ln_wage_per_wage_hhld     = log(wage_per_wage_hhld)
    gen ln_bussines_rev_per_owner = log(bussines_rev_per_owner)

    gen ln_agi_per_cap_avg            = ln_agi_per_cap/12
    gen ln_wage_per_cap_avg           = ln_wage_per_cap/12
    gen ln_wage_per_wage_hhld_avg     = ln_wage_per_wage_hhld/12
    gen ln_bussines_rev_per_owner_avg = ln_bussines_rev_per_owner/12
    
    drop if inlist(zipcode, "0", "00000", "99999") /* I guess these are "other zipcodes". 
                                                      There is one per state, which generates dups */ 

    save "../temp/irs_data.dta", replace
end

program clean_area_shares
    syntax, instub(str)

    use "`instub'/lodes_zipcodes/jobs.dta", clear
    preserve
        keep if jobs_by == "residence"
        
        keep zipcode year share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_* sh_residents_*
        rename share_earn_* sh_residents_*
        rename share_naics_* sh_residents_*
        rename share_sch_* sh_residents_*
        
        save "../temp/residence_shares.dta", replace
    restore
    
    preserve
        keep if jobs_by == "workplace"
        
        keep zipcode year share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_* sh_workers_*
        rename share_earn_* sh_workers_*
        rename share_naics_* sh_workers_*
        rename share_sch_* sh_workers_*
        
        save "../temp/workplace_shares.dta", replace
    restore
end

program clean_od_shares
    syntax, instub(str)

    clear
    import delimited "`instub'/shares/zipcode_shares.csv", stringcols(1)

    keep zipcode year share_*
    rename share_workers_*      sh_workers_od_*
    rename share_residents_*    sh_residents_od_*
    rename share_work_samegeo   sh_work_samegeo_od
    rename share_work_samegeo_* sh_work_samegeo_od_*

    save "../temp/od_shares.dta"
end

program clean_qcew
    syntax, instub(str)
    
    use countyfips year estcount* avgwwage* emp*            ///
       using `instub'/ind_emp_wage_countymonth.dta, clear

    foreach var of varlist estcount* avgwwage* emp* {
        gen ln_`var' = log(`var')
        drop `var'
    }

    collapse (mean) ln_*, by(countyfips year)

    save "../temp/qcew_data.dta"
end

program merge_acs_pop
    syntax, instub(str)

    merge m:1 zipcode year using "`instub'/demographics/acs_population_zipyear.dta", ///
        nogen keep(1 3)

    qui sum ln_med_rent_var if !missing(ln_med_rent_var)
    local observations_with_rents = r(N)

    qui sum acs_pop if !missing(ln_med_rent_var)
    assert r(N) == `observations_with_rents'
end


main
