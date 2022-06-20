clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local in_est     "../../../drive/derived_large/estimation_samples"
    local in_zip_yr  "../../../drive/derived_large/zipcode_year"
    local incross    "../../../drive/derived_large/zipcode"
    local outstub    "../output"
	
    local mw_wkp_var "mw_wkp_tot_17"

    use "`in_zip_yr'/zipcode_year.dta", clear
    xtset zipcode_num year

    keep if year >= 2014    // To be consistent with baseline

    add_baseline_zipcodes, instub(`in_est')
    add_share_mw_workers,  instub(`incross')

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
        yvar(ln_wagebill) xvars(`mw_wkp_var'_avg c.`mw_wkp_var'_avg##c.std_sh_mw_wkrs_statutory) ///
        controls(`controls') absorb(zipcode year#cbsa_num) cluster(`cluster') ///
        model_name(cbsa_time_het)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(`mw_wkp_var'_avg) controls(`controls')     ///
        absorb(zipcode year#county_num) cluster(`cluster') model_name(county_time)
    
    estimate_twfe_model if fullbal_sample_SFCC, ///
        yvar(ln_wagebill) xvars(`mw_wkp_var'_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(cbsa_time_baseline)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(mw_wkp_tot_14_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(mw_wkp_tot_14)
    
    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(mw_wkp_tot_18_avg) controls(`controls')     ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(mw_wkp_tot_18)
    
    estimate_twfe_model, ///
        yvar(ln_wagebill) xvars(mw_wkp_tot_tvar_avg) controls(`controls')       ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(mw_wkp_tot_timvar)
    
    estimate_twfe_model, ///
        yvar(ln_dividends) xvars(`mw_wkp_var'_avg) controls(`controls')    ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(dividends)

    use ../temp/estimates_naive.dta, clear
    foreach ff in ctrls cbsa_time cbsa_time_het cbsa_time_baseline ///
                  county_time mw_wkp_tot_14 mw_wkp_tot_18 mw_wkp_tot_timvar dividends {
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_all.dta, replace
    export delimited `outstub'/estimates_all.csv, replace
end

program add_baseline_zipcodes
    syntax, instub(str)

    preserve
        use `instub'/zipcode_months.dta, clear

        keep if fullbal_sample_SFCC == 1
        bys  zipcode: keep if _n == 1
        keep zipcode fullbal_sample_SFCC

        tempfile zipcode_years_baseline
        save    `zipcode_years_baseline'
    restore

    merge m:1 zipcode using `zipcode_years_baseline', keep(1 3) nogen

    replace fullbal_sample_SFCC = 0 if fullbal_sample_SFCC != 1
    
    destring cbsa, gen(cbsa_num)
end

program add_share_mw_workers
    syntax, instub(str)

    merge m:1 zipcode using "`instub'/zipcode_cross.dta", nogen       ///
        keep(3) keepusing(sh_mw_wkrs_statutory)

    foreach var in sh_mw_wkrs_statutory {
        qui sum `var'
        local avg_`var' = r(mean)
        local sd_`var' = r(sd)
        gen std_`var' = (`var' - `avg_`var'')/`sd_`var''
    }
end



main
