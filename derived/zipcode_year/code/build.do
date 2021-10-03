set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local in_der_large  "../../../drive/derived_large"
    local in_base_large "../../../drive/base_large"
    local outstub       "../../../drive/derived_large/zipcode_year"
    local logfile       "../output/data_file_manifest.log"

    define_controls
    local controls "`r(economic_controls)'"

    use zipcode statefips countyfips cbsa10 year month zcta ln_mw actual_mw ///
        exp_ln_mw* ln_med_rent_var acs_pop `controls' using  ///
        "`in_der_large'/estimation_samples/all_zipcode_months.dta", clear

    collapse_to_year

    merge_irs_data, instub(`in_base_large') controls(`controls')
    
    merge_lodes_shares, instub(`in_base_large')
    
    use "../temp/workplace_shares.dta" , clear
    merge 1:1 zipcode year using "../temp/residence_shares.dta", nogen
    merge 1:1 zipcode year using "../temp/irs_data.dta", nogen

    save_data "`outstub'/zipcode_year.dta", key(zipcode year) ///
        log(`logfile') replace
end

program collapse_to_year

    describe exp*, varlist
    local vars = r(varlist)
    local vars = "ln_mw `vars'"

    foreach var of local vars {
        bys zipcode year: egen `var'_avg = mean(`var')
    }

    bysort zipcode year: keep if _n == 1
    drop month
end

program merge_irs_data
    syntax, instub(str) controls(str)
    
    merge 1:1 zipcode statefips year ///
        using  "`instub'/irs_soi/irs_zip.dta", nogen keep(1 3)
    
    gen ln_agi_per_cap            = log(agi_per_cap)
    gen ln_wage_per_cap           = log(wage_per_cap)
    gen ln_wage_per_wage_hhld     = log(wage_per_wage_hhld)
    gen ln_bussines_rev_per_owner = log(bussines_rev_per_owner)
    
    save "../temp/irs_data.dta", replace
end

program merge_lodes_shares
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


main
