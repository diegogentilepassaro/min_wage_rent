set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_geo       "../../../drive/base_large/zipcode_master"
    local in_mw_meas  "../../../drive/derived_large/min_wage_measures"
    local in_zillow   "../../../drive/base_large/zillow"
    local in_qcew     "../../../base/qcew/output"
    local outstub     "../../../drive/derived_large/zipcode_month"
    local logfile     "../output/data_file_manifest.log"

    use zipcode place_code countyfips statefips cbsa ///
        using `in_geo'/zipcode_master.dta, clear

    merge 1:m zipcode using "`in_mw_meas'/zipcode_mw_res.dta",   ///
       nogen assert(1 3)

    merge_morkplace_mw, instub(`in_mw_meas')
    merge_zillow_data,  instub(`in_zillow')    
    
    make_date_variables

    merge m:1 statefips countyfips year month                                ///
        using "`in_qcew'/ind_emp_wage_countymonth.dta", nogen keep(1 3)
    drop qmon end_month
	drop if (missing(zipcode) | missing(year_month))

    strcompress
    save_data "`outstub'/zipcode_month_panel.dta", replace ///
        key(zipcode year month) log(`logfile')
    export delimited "`outstub'/zipcode_month_panel.csv", replace
end

program merge_morkplace_mw
    syntax, instub(str)

    local instub  "../../../drive/derived_large/min_wage_measures"
    merge 1:1 zipcode year month using "`instub'/zipcode_mw_wkp_2009.dta", ///
        nogen keep(1 3)
    foreach var of varlist mw_wkp* {
        local mw_vars "`mw_vars' `var'"

        rename `var' `var'_09
    }
    
    forvalues yy = 10(1)18 {
        merge 1:1 zipcode year month using "`instub'/zipcode_mw_wkp_20`yy'.dta", ///
            nogen keep(1 3)

        foreach var of local mw_vars {
            rename `var' `var'_`yy'
        }
    }

    foreach var of local mw_vars {
        gen `var'_timevary = `var'_09 if year == 2009
        forvalues yy = 10(1)18 {
            replace `var'_timevary = `var'_`yy' if year == 2000 + `yy'
        }
    }
end

program merge_zillow_data
    syntax, instub(str)
    
    merge 1:1 zipcode year month using "`instub'/zillow_zipcode_clean.dta"

    sum medrentpricepsqft_SFCC if _merge == 2 & inrange(year, 2010, 2019)    
    *assert r(N) == 0
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


main
