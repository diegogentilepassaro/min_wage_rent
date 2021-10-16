set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
    local in_der_large  "../../../drive/derived_large"
    local in_geo        "../../../base/geo_master/output"
    local in_base_large "../../../drive/base_large"
    local in_qcew       "../../../base/qcew/output"
    local outstub       "../../../drive/derived_large/zipcode_month"
    local logfile       "../output/data_file_manifest.log"

    use zipcode place_code countyfips cbsa10 zcta statefips rural             ///
        using "`in_geo'/zip_county_place_usps_master.dta", clear

    merge 1:m zipcode using "`in_der_large'/min_wage/zip_statutory_mw.dta",   ///
       nogen assert(3) keepusing(year month actual* binding*)
    
    merge_zillow, instub("`in_base_large'/zillow")
    
    merge_exp_mw, instub("`in_der_large'/min_wage")
    
    make_date_variables

    merge m:1 statefips countyfips year month                                ///
        using "`in_qcew'/ind_emp_wage_countymonth.dta", nogen keep(1 3)
    drop qmon end_month

    strcompress
    save_data "`outstub'/zipcode_month_panel.dta", replace ///
        key(zipcode year month) log(`logfile')
    export delimited "`outstub'/zipcode_month_panel.csv", replace
end

program merge_zillow
    syntax, instub(str)
    
    merge 1:1 zipcode year month using "`instub'/zillow_zipcode_clean.dta"

    qui sum medrentpricepsqft_SFCC if _merge == 2 & inrange(year, 2010, 2019)    
    assert r(N) == 0
    keep if inlist(_merge, 1, 3)
    drop _merge
end

program merge_exp_mw
    syntax, instub(str)

    merge 1:1 zipcode year month using "`instub'/zipcode_experienced_mw_2010.dta", ///
        nogen keep(1 3) keepusing(exp*)
    describe exp*, varlist
    local vars = r(varlist)
    foreach var of local vars {
        rename `var' `var'_10
    }
    drop *mean_10
    
    merge 1:1 zipcode year month using "`instub'/zipcode_experienced_mw_2014.dta", ///
        nogen keep(1 3) keepusing(exp*)
    foreach var of local vars {
        rename `var' `var'_14
    }
    drop *mean_14
    
    merge 1:1 zipcode year month using "`instub'/zipcode_experienced_mw_2017.dta", ///
        nogen keep(1 3) keepusing(exp*)
    foreach var of local vars {
        rename `var' `var'_17
    }
    drop *mean_17
    
    merge 1:1 zipcode year month using "`instub'/zipcode_experienced_mw_2018.dta", ///
        nogen keep(1 3) keepusing(exp*)
    foreach var of local vars {
        rename `var' `var'_18
    }
    drop *mean_18
    
    qui sum medrentpricepsqft_SFCC if !missing(medrentpricepsqft_SFCC)
    local observations_with_rents = r(N)

    foreach year in 10 14 17 18 {
        sum exp_ln_mw_tot_`year' if !missing(medrentpricepsqft_SFCC)
        assert r(N) == `observations_with_rents'
    }
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


main
