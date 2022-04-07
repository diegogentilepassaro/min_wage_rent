clear all
set more off
version 15
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local outstub "../output"

    define_controls
    local controls "`r(economic_controls)'"

    use "`instub'/zipcode_months", clear
    keep if baseline_sample_SFCC

    xtset zipcode_num year_month

    * LEVELS
    estimate_stacked_model, depvar(ln_rents)  ///
        mw_var1(mw_res) mw_var2(mw_wkp_tot_17) controls(`controls') ///
        absorb(year_month zipcode) cluster(statefips) ///
        model_name(levels_model)

    * FD
    reghdfe D.ln_rents D.mw_res D.mw_wkp_tot_17 D.`controls',	///
            absorb(year_month) 	vce(cluster statefips) ///
            nocons residuals(fd_res)

    reg fd_res L.fd_res, cluster(statefips)
    test (L.fd_res = -0.5) 
    local p_val_auto = "`r(p)'"

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(mw_wkp_tot_17) w(0) stat_var(mw_res) ///
        controls(`controls') absorb(year_month) cluster(statefips) ///
        model_name(baseline_model) outfolder("../temp")
        
    use ../temp/estimates_levels_model.dta, clear
    append using ../temp/estimates_baseline_model.dta

    gen     p_val = ""
    replace p_val = "`p_val_auto'" if model == "baseline_model"
        
    export delimited `outstub'/estimates_autocorrelation.csv, replace
end

main
