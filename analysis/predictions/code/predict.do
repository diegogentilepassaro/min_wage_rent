clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
    local instub   "../../../drive/derived_large/estimation_samples"
    local outstub  "../output"
    
    define_controls
    local controls      "`r(economic_controls)'"
    local cluster       "statefips"
    local absorb        "year_month"
    local exp_ln_mw_var "exp_ln_mw_17"
    
    
    use zipcode zipcode_num statefips cbsa10 year_month year month ///
        ln_rents ln_mw `exp_ln_mw_var' `controls' ///
        using "`instub'/all_zipcode_months.dta", clear

    add_baseline_zipcodes, instub(`instub')
    xtset zipcode_num year_month
    
    gen d_ln_rents        = D.ln_rents
    gen d_ln_mw           = D.ln_mw
    gen d_`exp_ln_mw_var' = D.`exp_ln_mw_var'
    
    reghdfe d_`exp_ln_mw_var' d_ln_mw `controls' ///
        if baseline_sample, absorb(`absorb', savefe) ///
        vce(cluster `cluster') nocons residuals(resid_wkpl_on_res_MW)
		
    save             "`outstub'/residualswkpl_on_res_MW_.dta", replace
	
    reghdfe d_ln_rents d_ln_mw `controls' ///
        if baseline_sample, absorb(`absorb', savefe) ///
        vce(cluster `cluster') nocons residuals(resid_resMWonly)
    
    predict hat_d_ln_rents_resMWonly   if year >= 2018, xb
    predict hatfe_d_ln_rents_resMWonly if year >= 2018, xbd
    
    reghdfe d_ln_rents d_`exp_ln_mw_var' d_ln_mw `controls' ///
        if baseline_sample, absorb(`absorb', savefe) ///
        vce(cluster `cluster') nocons residuals(resid_baseline)
    
    keep if year >= 2018

    predict hat_d_ln_rents_baseline,   xb
    predict hatfe_d_ln_rents_baseline, xbd

    keep zipcode cbsa10 year month year_month d_* resid_* hat*
    
    save             "`outstub'/predictions.dta", replace
    export delimited "`outstub'/predictions.csv", replace
end


program add_baseline_zipcodes
    syntax, instub(str)

    preserve
        use `instub'/baseline_zipcode_months.dta, clear

        keep if !missing(ln_rents)

        bys  zipcode: keep if _n == 1
        
        keep zipcode
        gen baseline_sample = 1

        tempfile zipcode_years_baseline
        save    `zipcode_years_baseline'
    restore

    merge m:1 zipcode using `zipcode_years_baseline', keep(1 3) nogen

    replace baseline_sample = 0 if baseline_sample != 1
end



main
