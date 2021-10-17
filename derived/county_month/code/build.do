set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
    local in_derived_large  "../../../drive/derived_large"
    local in_geo            "../../../base/geo_master/output"
    local in_base_large     "../../../drive/base_large"
    local in_qcew           "../../../base/qcew/output"
    local outstub           "../../../drive/derived_large/county_month"
    local logfile           "../output/data_file_manifest.log"

    use countyfips statefips cbsa10 using "`in_geo'/zip_county_place_usps_all.dta", clear
    duplicates drop
    isid countyfips
   
    merge 1:m countyfips using "`in_derived_large'/min_wage/county_statutory_mw.dta", ///
       nogen assert(3) keepusing(year month actual_mw* binding_mw*)
    
    merge_exp_mw, instub(`in_derived_large') yy("10")
    merge_exp_mw, instub(`in_derived_large') yy("14")
    merge_exp_mw, instub(`in_derived_large') yy("17")
    merge_exp_mw, instub(`in_derived_large') yy("18")
    merge_zillow, instub(`in_base_large')

    /* Should we build ACS population by county-year? Probably we should! */

    make_date_variables
    merge_qcew, instub(`in_qcew')

    strcompress
    rename countyfips county
    save_data "`outstub'/county_month_panel.dta", replace ///
        key(county year month) log(`logfile')
end

program merge_exp_mw
    syntax, instub(str) yy(str)

    preserve
        use "`instub'/min_wage/countyfips_experienced_mw_20`yy'.dta", clear

        drop *mean
        rename exp_ln_* exp_ln_*_`yy'

        tempfile exp_mw
        save    `exp_mw'
    restore
    merge 1:1 countyfips year month using `exp_mw', ///
        assert(1 2 3) keep(1 3) nogen keepusing(exp*)
end

program merge_zillow
    syntax, instub(str)
    
    merge 1:1 countyfips year month using "`instub'/zillow/zillow_county_clean.dta"
    
    qui sum medrentpricepsqft_SFCC if _merge == 2 & inrange(year, 2010, 2019)    
    assert r(N) == 0
    keep if inlist(_merge, 1, 3)
    drop _merge
end

program make_date_variables
    gen day = 1
    gen date = mdy(month, day, year)

    gen    year_month = mofd(date)
    format year_month %tm

    gen    quarter      = quarter(dofm(year_month))
    gen    year_quarter = qofd(date)
    format year_quarter %tq

    drop day date
end

program merge_qcew
    syntax, instub(str)
    
    merge m:1 statefips countyfips year month           ///
        using "`instub'/ind_emp_wage_countymonth.dta", ///
        nogen keep(3)
end


main
