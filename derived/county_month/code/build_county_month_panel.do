set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
    local instub_derived  "../../../drive/derived_large"
    local instub_geo  "../../../base/geo_master/output"
    local instub_base  "../../../drive/base_large"
    local instub_qcew "../../../base/qcew/output"
    local outstub "../../../drive/derived_large/county_month"
    local logfile "../output/data_file_manifest.log"

    use countyfips statefips cbsa10 ///
        using "`instub_geo'/zip_county_place_usps_all.dta", clear
    duplicates drop
    isid countyfips
   
    merge 1:m countyfips using "`instub_derived'/min_wage/county_statutory_mw.dta", ///
       nogen assert(3) keepusing(year month actual_mw_wg_mean ///
       actual_mw_ignore_local_wg_mean local_mw county_mw fed_mw state_mw ///
       actual_mw binding_mw actual_mw_ignore_local binding_mw_ignore_local)
    
    merge 1:1 countyfips year month using "`instub_derived'/min_wage/countyfips_experienced_mw.dta", ///
        assert(1 2 3) nogen keepusing(exp_ln_mw_lowinc exp_ln_mw_lowinc_max exp_ln_mw_lowinc_wg_mean ///
                                exp_mw_lowinc exp_mw_lowinc_max exp_mw_lowinc_wg_mean ///
                                exp_ln_mw_tot exp_ln_mw_tot_max exp_ln_mw_tot_wg_mean          ///
                                exp_mw_tot exp_mw_tot_max exp_mw_tot_wg_mean         ///
                                exp_ln_mw_young exp_ln_mw_young_max exp_ln_mw_young_wg_mean ///
                                exp_mw_young exp_mw_young_max exp_mw_young_wg_mean)   
    
    merge 1:1 countyfips year month using "`instub_base'/zillow/zillow_county_clean.dta"
    qui sum medrentpricepsqft_SFCC if _merge == 2 & inrange(year, 2010, 2019)    
    assert r(N)==0
    keep if inlist(_merge, 1, 3)
    drop _merge
    
    /* Should we build ACS population by county-year? Probably we should! */

    merge m:1 statefips countyfips month year ///
        using "`instub_qcew'/ind_emp_wage_countymonth.dta", ///
        nogen keep(3) assert(1 2 3)
    add_dates

    strcompress
    
    save_data "`outstub'/county_month_panel.dta", replace ///
        key(countyfips year month) log(`logfile')
end

program add_dates
    gen day = 1
    gen date = mdy(month, day, year)
    gen year_month = mofd(date)
    format year_month %tm
    gen year_quarter = qofd(date)
    format year_quarter %tq
    drop day date
end

main
