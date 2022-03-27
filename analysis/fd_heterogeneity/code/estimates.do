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

	use "`instub'/baseline_sample_with_vars_for_het.dta", clear
	xtset zipcode_num year_month
	
	/*reghdfe D.ln_rents c.D.mw_res#i.public_housing ///
	    c.D.mw_wkp_tot_17#i.public_housing ///
	    D.(`controls'), nocons ///
		absorb(year_month##public_housing) cluster(`cluster_vars')*/
	
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(mw_wkp_tot_17) w(0) stat_var(mw_res) ///
        controls(`controls') absorb(`absorb') cluster(`cluster_vars') ///
        model_name(static_both)
		
    reghdfe D.ln_rents c.D.mw_res#i.high_work_mw ///
	    c.D.mw_wkp_tot_17#i.high_res_mw ///
	    D.(`controls'), nocons ///
		absorb(`absorb'##high_work_mw##high_res_mw) ///
		cluster(`cluster_vars')
    process_estimates
	save "../temp/estimates_het.dta", replace
	
	use "../temp/estimates_static_both.dta", clear
	append using "../temp/estimates_het.dta"
	export delimited "../temp/estimates.csv", replace
end

program process_estimates
	local N = e(N)
	local r2 = e(r2)
	
	qui coefplot, vertical base gen
	keep __at __b __se
	rename (__at __b __se) (at b se)
	keep if _n <= 4
	keep if !missing(at)
	replace at = 0
	replace at = 1 if inlist(_n, 2, 4)
	gen var     = "mw_res_high_work_mw"    
	replace var = "mw_wkp_high_res_mw" if _n >= 3
	gen N = `N'
	gen r2 = `r2'
	gen model = "heterogeneity"
end

main
