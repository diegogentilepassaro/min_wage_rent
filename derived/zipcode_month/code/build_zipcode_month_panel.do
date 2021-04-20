set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
    local instub_derived  "../../../drive/derived_large"
    local instub_geo  "../../../base/geo_master/output"
    local instub_base  "../../../drive/base_large"
    local instub_qcew "../../../base/qcew/output"
    local outstub "../../../drive/derived_large/zipcode_month"
    local logfile "../output/data_file_manifest.log"

    use zipcode place_code countyfips cbsa10 zcta statefips rural ///
        using "`instub_geo'/zip_county_place_usps_master.dta", clear
    destring zipcode, replace
    merge 1:m zipcode using "`instub_derived'/min_wage/zip_statutory_mw.dta", ///
       nogen assert(3) keepusing(year month actual_mw_wg_mean ///
       actual_mw_ignore_local_wg_mean local_mw county_mw fed_mw state_mw ///
       actual_mw binding_mw actual_mw_ignore_local binding_mw_ignore_local)
       
    merge 1:1 zipcode year month using "`instub_base'/zillow/zillow_zipcode_clean.dta"
    qui sum medrentpricepsqft_SFCC if _merge == 2 & inrange(year, 2010, 2019)    
    assert r(N) == 0
    keep if inlist(_merge, 1, 3)
    drop _merge
    
    merge 1:1 zipcode year month using "`instub_derived'/min_wage/zip_experienced_mw.dta", ///
        nogen keep(1 3) keepusing(exp_mw_tot exp_mw_young exp_mw_lowinc exp_ln_mw_tot ///
        exp_ln_mw_young exp_ln_mw_lowinc exp_mw_tot_wg_mean exp_mw_young_wg_mean ///
        exp_mw_lowinc_wg_mean exp_ln_mw_tot_wg_mean exp_ln_mw_young_wg_mean exp_ln_mw_lowinc_wg_mean)
    qui sum medrentpricepsqft_SFCC if !missing(medrentpricepsqft_SFCC)
    local observations_with_rents = r(N)
    sum exp_ln_mw_tot if !missing(medrentpricepsqft_SFCC)
    assert `observations_with_rents' == r(N)
    
    merge m:1 zipcode year using "`instub_base'/demographics/acs_population_zipyear.dta", ///
        nogen keep(1 3)
    qui sum acs_pop if !missing(medrentpricepsqft_SFCC)
    assert `observations_with_rents' == r(N)
    
    add_dates
    merge m:1 statefips countyfips year_month ///
        using "`instub_qcew'/ind_emp_wage_countymonth.dta", nogen keep(1 3)

    strcompress
    save_data "`outstub'/zipcode_month_panel.dta", replace ///
        key(zipcode year month) log(`logfile')
end

program add_dates
    gen day = 1
    gen date = mdy(month, day, year)
    gen year_month = mofd(date)
    format year_month %tm
    gen quarter = quarter(dofm(year_month))
    gen year_quarter = qofd(date)
    format year_quarter %tq
    drop day date
end

main
