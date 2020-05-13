set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado

program main 
    import delim "../temp/data_clean.csv", delim(",")

    clean_vars
    gen_vars

    compress
    save_data "../temp/zipcode_yearmonth_panel.dta", key(zipcode year_month) ///
        log(none) replace
end  

program clean_vars
    *clean date
    gen     year_month = date(date, "YMD")
    gen calendar_month = month(year_month)
    drop date
    replace year_month = mofd(year_month)
    format  year_month %tm

    drop if missing(year_month)
    drop if missing(zipcode)

    * Remove obs with no data on minimum wage
    bys zipcode (year_month): egen no_mw_data = min(actual_mw)
    bys zipcode (year_month): egen no_mw_data_smallb = min(actual_mw_smallbusiness)
    drop if missing(no_mw_data)  
    drop if missing(no_mw_data) & missing(no_mw_data_smallb)
    drop no_mw_data no_mw_data_smallb 
end

program gen_vars
    bysort zipcode (year_month): gen trend = _n

    local mw_type `" "" "_smallbusiness" "'
    foreach var_type in `mw_type' {
        bysort zipcode (year_month): gen dpct_actual_mw`var_type' = dactual_mw`var_type'/actual_mw`var_type'[_n-1]

        gen event_month`var_type' = mw_event`var_type' == 1
        replace event_month`var_type' = 1 if year_month != year_month[_n-1] + 1  // zipcode changes

        gen event_month`var_type'_id = sum(event_month`var_type')

        bysort event_month`var_type'_id: gen months_since`var_type' = _n - 1
        bysort event_month`var_type'_id: gen months_until`var_type' = _N - months_since`var_type'

        bysort event_month`var_type'_id: replace months_until`var_type' = 0 if _N == months_until`var_type'

        drop event_month`var_type'_id event_month`var_type'        
    }
	
    gen sal_mw_event = (dactual_mw >= 0.5)
	gen mw_event025 = (dactual_mw >= 0.25)
	gen mw_event075 = (dactual_mw >= 0.75)

end

main
