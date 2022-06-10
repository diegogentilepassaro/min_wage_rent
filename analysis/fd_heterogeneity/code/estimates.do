clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 
	
program main
    local instub  "../temp"
    local outstub "../output"

    define_controls
    local controls     "`r(economic_controls)'"
    local cluster_vars "statefips"
    local absorb "year_month"

    use "`instub'/fullbal_sample_with_vars_for_het.dta", clear
    xtset zipcode_num year_month

    estimate_dist_lag_model, depvar(ln_rents)                         ///
        dyn_var(mw_wkp_tot_17) w(0) stat_var(mw_res)                  ///
        controls(`controls') absorb(`absorb') cluster(`cluster_vars') ///
        model_name(static_both)
        
    reghdfe D.ln_rents c.D.mw_res c.D.mw_res#c.pc_mw_wkrs_statutory_diff_med                    ///
        c.D.mw_wkp_tot_17 c.D.mw_wkp_tot_17#c.pc_mw_wkrs_statutory_diff_med                              ///
        D.(`controls'), nocons                                        ///
        absorb(`absorb')                   ///
        cluster(`cluster_vars')
    
    process_estimates, res_var(mw_res_high_st_work_mw)                   ///
        wkp_var(mw_wkp_high_st_res_mw) model(het_mw_shares)

	reghdfe D.ln_rents c.D.mw_res c.D.mw_res#1.public_housing                  ///
        c.D.mw_wkp_tot_17 c.D.mw_wkp_tot_17#1.public_housing                          ///
        D.(`controls'), nocons                                        ///
        absorb(year_month##public_housing) cluster(`cluster_vars')
    
    process_estimates, res_var(mw_res_high_public_hous)               ///
        wkp_var(mw_wkp_high_public_hous) model(het_public_hous)

    use "../temp/estimates_static_both.dta", clear
    append using "../temp/estimates_het_mw_shares.dta"
    append using "../temp/estimates_het_public_hous.dta"
    export delimited "../output/estimates_het.csv", replace
end

program process_estimates
    syntax, res_var(str) wkp_var(str) model(str)

    preserve
        local N = e(N)
        local r2 = e(r2)

        qui coefplot, vertical base gen
        keep __at __b __se
        rename (__at __b __se) (at b se)
        keep if _n <= 4
        keep if !missing(at)

        replace at = 0
        replace at = 1 if inlist(_n, 2, 4)

        gen     var = "`res_var'"  
        replace var = "`wkp_var'" if _n >= 3

        gen N = `N'
        gen r2 = `r2'
        gen model = "`model'"

        save "../temp/estimates_`model'.dta", replace
    restore
end

main
