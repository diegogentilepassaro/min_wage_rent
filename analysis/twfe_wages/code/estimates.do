clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local in_est     "../../../drive/derived_large/estimation_samples"
    local in_zip_yr  "../../../drive/derived_large/zipcode_year"
    local outstub "../output"
	
    local mw_wkp_var "mw_wkp_tot_17"

    use "`in_zip_yr'/zipcode_year.dta", clear
    xtset zipcode_num year

    add_baseline_zipcodes, instub(`in_est')
	destring cbsa, gen(cbsa_num)
	
    define_controls
    local controls "`r(economic_controls)'"
    local cluster "statefips"

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(`mw_wkp_var'_avg) controls(" ")            ///
        absorb(zipcode year) cluster(`cluster') model_name(naive)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(`mw_wkp_var'_avg) controls(`controls')     ///
        absorb(zipcode year) cluster(`cluster') model_name(ctrls)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(`mw_wkp_var'_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(cbsa_time)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(`mw_wkp_var'_avg) controls(`controls')     ///
        absorb(zipcode year#county_num) cluster(`cluster') model_name(county_time)
    
    estimate_twfe_model if baseline_sample, ///
        yvar(ln_wagebill) xvars(`mw_wkp_var'_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(cbsa_time_baseline)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(mw_wkp_tot_10_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(mw_wkp_tot_10)
    
    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(mw_wkp_tot_18_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(mw_wkp_tot_18)
    
    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(mw_wkp_tot_tvar_avg) controls(`controls')       ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(mw_wkp_tot_timvar)
    
    estimate_twfe_model, ///
        yvar(ln_dividends) xvars(`mw_wkp_var'_avg) controls(`controls')    ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(dividends)

    use `outstub'/estimates_naive.dta, clear
    foreach ff in ctrls cbsa_time county_time cbsa_time_baseline ///
                  mw_wkp_tot_10 mw_wkp_tot_18 mw_wkp_tot_timvar dividends {
        append using `outstub'/estimates_`ff'.dta
    }
    save             `outstub'/estimates_all.dta, replace
    export delimited `outstub'/estimates_all.csv, replace
end

program add_baseline_zipcodes
    syntax, instub(str)

    preserve
        use `instub'/zipcode_months.dta, clear

        keep if baseline_sample == 1
        bys  zipcode: keep if _n == 1
        keep zipcode baseline_sample

        tempfile zipcode_years_baseline
        save    `zipcode_years_baseline'
    restore

    merge m:1 zipcode using `zipcode_years_baseline', keep(1 3) nogen

    replace baseline_sample = 0 if baseline_sample != 1
end


main
