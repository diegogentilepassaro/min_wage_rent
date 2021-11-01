clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local in_cf_mw    "../../../drive/derived_large/min_wage"
    
    define_controls
    local controls "`r(economic_controls)'"
    local cluster = "statefips"
    local absorb  = "year_month"
    
    process_counterfactual_data, in_cf_mw(`in_cf_mw') ///
        instub(`instub') controls(`controls')
    
    local exp_ln_mw_var "exp_ln_mw_17"
    
    use zipcode zipcode_num statefips year_month year month ///
        ln_rents ln_mw `exp_ln_mw_var' `controls' ///
        using "`instub'/all_zipcode_months.dta", clear
    add_baseline_zipcodes, instub(`instub')
    xtset zipcode_num `absorb'
    
    foreach var of local controls {
        bys zipcode_num (year_month): gen d_`var' = `var'[_n] - `var'[_n-1]
    }
    gen d_ln_rents = ln_rents[_n] - ln_rents[_n-1]
    gen d_ln_mw = ln_mw[_n] - ln_mw[_n-1]
    gen d_`exp_ln_mw_var' = `exp_ln_mw_var'[_n] - `exp_ln_mw_var'[_n-1]
    
     reghdfe d_ln_rents d_`exp_ln_mw_var' d_ln_mw ///
        d_ln_emp* d_ln_estcount* d_ln_avgwwage* if baseline_sample == 1, ///
        absorb(`absorb', savefe) vce(cluster `cluster') ///
        nocons residuals(residuals)
    append using "../temp/counterfactual_fed_9usd.dta"
    
    replace d_ln_mw = d_ln_mw_cf if (year == 2020 & month == 1)
    replace d_exp_ln_mw_17 = d_exp_ln_mw_cf if (year == 2020 & month == 1)
    
    foreach var of local controls {
        bysort zipcode (year_month): replace d_`var' = ///
            `var'[_n-1] if (year == 2020 & month == 1)
    }
    bysort zipcode (year month): gen ln_rents_pre = ///
            ln_rents[_n-1] if (year == 2020 & month == 1)
    gen counterfactual = 0
    replace counterfactual = 1 if (year == 2020 & month == 1) 
    replace year_month = `=tm(2019m12)' if year_month == 2020
    preserve 
        collapse __hdfe1__, by(year_month)
        save "../temp/fes.dta", replace
    restore
    drop __hdfe1__
    merge m:1 year_month using "../temp/fes.dta"
    predict p_d_ln_rents, xb
    gen p_d_ln_rents_with_fe = p_d_ln_rents + __hdfe1__
    
    keep if counterfactual == 1
        
    keep zipcode year month d_ln_mw d_exp_ln_mw_17 ///
        ln_rents_pre p_d_ln_rents p_d_ln_rents_with_fe
	order zipcode year month d_ln_mw d_exp_ln_mw_17 ///
        ln_rents_pre p_d_ln_rents p_d_ln_rents_with_fe
    save_data "../output/d_ln_rents_cf_predictions.dta", ///
        key(zipcode year month) replace
end

program process_counterfactual_data
    syntax, in_cf_mw(str) instub(str) controls(str)
    
    use zipcode year_month year month counterfactual exp_ln_mw_tot using ///
        "`in_cf_mw'/zipcode_experienced_mw_cfs.dta", clear
    
    bysort zipcode counterfactual (year month): ///
    gen d_exp_ln_mw_cf = exp_ln_mw_tot[_n] - exp_ln_mw_tot[_n - 1]
    keep if (year == 2020 & month == 1)
    rename exp_ln_mw_tot exp_ln_mw_tot_18_cf
    gen fed_mw_cf = 7.25*1.1 if counterfactual == "fed_10pc"
    replace fed_mw_cf = 15 if counterfactual == "fed_15usd"
    replace fed_mw_cf = 9 if counterfactual == "fed_9usd"
    save "../temp/counterfactual.dta", replace
    
    use "`instub'/all_zipcode_months.dta", clear
    keep if (year == 2019 & month == 12)
    keep zipcode actual_mw
    expand 3
    bysort zipcode: gen counterfactual = "fed_10pc" if _n == 1
    bysort zipcode: replace counterfactual = "fed_15usd" if _n == 2
    bysort zipcode: replace counterfactual = "fed_9usd" if _n == 3
    merge 1:1 zipcode counterfactual using "../temp/counterfactual.dta", ///
        nogen keep(3)
    egen actual_mw_cf = rowmax(actual_mw fed_mw_cf)
    gen d_ln_mw_cf = log(actual_mw_cf) - log(actual_mw)
    drop fed_mw_cf actual_mw_cf exp_ln_mw_tot_18_cf
    preserve
        keep if counterfactual == "fed_10pc"
        drop counterfactual
        save "../temp/counterfactual_fed_10pc.dta", replace
    restore
    preserve
        keep if counterfactual == "fed_15usd"
        drop counterfactual
        save "../temp/counterfactual_fed_15usd.dta", replace
    restore
    preserve
        keep if counterfactual == "fed_9usd"
        drop counterfactual
        save "../temp/counterfactual_fed_9usd.dta", replace
    restore
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
