clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local instub "../../../drive/derived_large/"
    local outstub "../output"

    use "`instub'/zipcode_year/zipcode_year.dta", clear
    xtset zipcode_num year

    add_baseline_zipcodes, instub(`instub')
	
    define_controls
    local controls "`r(economic_controls)'"
    local cluster "statefips"

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(exp_ln_mw_tot_17_avg) controls(" ")            ///
        absorb(zipcode year) cluster(`cluster') model_name(naive)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(exp_ln_mw_tot_17_avg) controls(`controls')     ///
        absorb(zipcode year) cluster(`cluster') model_name(ctrls)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(exp_ln_mw_tot_17_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa10_num) cluster(`cluster') model_name(cbsa_time)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(exp_ln_mw_tot_17_avg) controls(`controls')     ///
        absorb(zipcode year#county_num) cluster(`cluster') model_name(county_time)
    
    estimate_twfe_model if baseline_sample, ///
        yvar(ln_wagebill) xvars(exp_ln_mw_tot_17_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa10_num) cluster(`cluster') model_name(cbsa_time_baseline)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(exp_ln_mw_tot_10_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa10_num) cluster(`cluster') model_name(exp_mw_10)
    
    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(exp_ln_mw_tot_18_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa10_num) cluster(`cluster') model_name(exp_mw_18)
    
    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(exp_ln_mw_tot_avg) controls(`controls')       ///
        absorb(zipcode year#cbsa10_num) cluster(`cluster') model_name(exp_mw_varying)
    
    estimate_twfe_model, ///
        yvar(ln_dividends) xvars(exp_ln_mw_tot_17_avg) controls(`controls')    ///
        absorb(zipcode year#cbsa10_num) cluster(`cluster') model_name(dividends)

    use `outstub'/estimates_naive.dta, clear
    foreach ff in ctrls cbsa_time county_time cbsa_time_baseline ///
                  exp_mw_10 exp_mw_18 exp_mw_varying dividends {
        append using `outstub'/estimates_`ff'.dta
    }
    save             `outstub'/estimates_all.dta, replace
    export delimited `outstub'/estimates_all.csv, replace
end

program add_baseline_zipcodes
    syntax, instub(str)

    preserve
        use `instub'/estimation_samples/baseline_zipcode_months.dta

        keep if !missing(ln_rents)

        keep zipcode year
        bys  zipcode year: keep if _n == 1

        gen baseline_sample = 1

        tempfile zipcode_years_baseline
        save    `zipcode_years_baseline'
    restore

    merge 1:1 zipcode year using `zipcode_years_baseline', assert(1 3) keep(1 3) nogen

    replace baseline_sample = 0 if baseline_sample != 1
end


main
