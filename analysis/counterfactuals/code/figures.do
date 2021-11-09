clear all
set more off
set maxvar 32000

program main
	local instub      "../output"
	local insizes     "../../../derived/zipcode_rent_sqft_income_preds/output"
    local in_baseline "../../fd_baseline/output"
    local in_wages    "../../twfe_wages/output"
	local geo         "../../../base/geo_master/output"
    use "`geo'/zip_county_place_usps_master.dta", clear

    load_parameters, in_baseline(`in_baseline') in_wages(`in_wages')
    local beta    = r(beta)
    local gamma   = r(gamma)
    local epsilon = r(epsilon)

	di "Beta, Gamma, and Epsilon: `beta', `gamma', `epsilon'"
	
	use `instub'/d_ln_rents_cf_predictions.dta, clear
	merge 1:1 zipcode using  `instub'/ln_wagebill_cf_predictions.dta, ///
	    nogen keepusing(ln_wagebill_pre n_hhlds_pre)
	merge 1:1 zipcode using "`insizes'/housing_sqft_per_zipcode.dta", ///
	    nogen keep(1 3) keepusing(sqft_from_listings sqft_from_rents)
	merge 1:1 zipcode using "`geo'/zip_county_place_usps_master.dta", ///
	   nogen keep(1 3) keepusing(cbsa10 rural)
	
	compute_vars, beta(`beta') gamma(`gamma') epsilon(`epsilon')
	preserve
	    keep zipcode cbsa10 d_ln_mw d_exp_ln_mw_17 change_ln_rents
        save_data "../output/predicted_changes_in_rents.dta", ///
		    key(zipcode) replace log(none)
		export delimited "../output/predicted_changes_in_rents.csv", replace
	restore
	foreach var in d_ln_mw d_exp_ln_mw_17 ///
	               perc_incr_rent perc_incr_wagebill ///
				   ratio_increases rho {
		
		get_xlabel, var(`var')
		local x_lab = r(x_lab)
		
		unique zipcode if !missing(`var')
		local n_zip = r(unique)
	
		hist `var', percent bin(20)                                           ///
			xtitle("`x_lab'") ytitle("Percentage") note("ZIP codes: `n_zip'") ///
			graphregion(color(white)) bgcolor(white)
		
		graph export "../output/`var'.png", replace
		graph export "../output/`var'.eps", replace
	}

    save             "../output/data_counterfactuals.dta", replace
    export delimited "../output/data_counterfactuals.csv", replace

	collapse (mean) rho_lb rho rho_ub, by(diff_qts)
	
    twoway (line     rho           diff_qts, lcol(navy))                      ///
           (scatter  rho           diff_qts, mcol(navy)),                     ///
        xtitle("Difference between change in wrk. and res. MW (deciles)")     ///
        ytitle("Mean share accruing to landlord on each dollar")              ///
        xlabel(1(1)10) ylabel(0.02(0.02)0.14)                                 ///
        graphregion(color(white)) bgcolor(white) legend(off) 
		
         /*(rcap     rho_lb rho_ub diff_qts, col(navy))                      /// */
		
	graph export "../output/deciles_diff.png", replace
	graph export "../output/deciles_diff.eps", replace
end


program load_parameters, rclass
	syntax, in_baseline(str) in_wages(str)

	use `in_baseline'/estimates_static.dta, clear
	keep if model == "static_both"

	qui sum b if var == "ln_mw"
	return local gamma = r(mean)
	qui sum b if var == "exp_ln_mw_17"
	return local beta = r(mean)

	use `in_wages'/estimates_cbsa_time_baseline.dta, clear
	qui sum b
	return local epsilon = r(mean)
end

program compute_vars
    syntax, beta(str) gamma(str) epsilon(str) [alpha(real 0.35)]

	keep if rural == 0

	* Predictions with parameters
	gen diff_mw    = d_exp_ln_mw_17 - d_ln_mw
	xtile diff_qts = diff_mw, nquantiles(10)

	egen max_d_ln_mw = max(d_ln_mw)
	gen no_direct_treatment       = d_ln_mw == 0
	gen fully_affected            = !no_direct_treatment

    gen change_ln_rents    = `beta'*d_exp_ln_mw_17 + `gamma'*d_ln_mw
    gen change_ln_wagebill = `epsilon'*d_exp_ln_mw_17

	gen perc_incr_rent     = exp(change_ln_rents)    - 1
	gen perc_incr_wagebill = exp(change_ln_wagebill) - 1
	gen ratio_increases    = perc_incr_rent/perc_incr_wagebill

    local alpha_lb = `alpha' - 0.1
    local alpha_ub = `alpha' + 0.1

    gen rho    = `alpha'*ratio_increases
	gen rho_lb = `alpha_lb'*ratio_increases
	gen rho_ub = `alpha_ub'*ratio_increases
end

program get_xlabel, rclass
    syntax, var(str)
	
	if inlist("`var'", "p_d_ln_rents", "p_d_ln_rents_with_fe", ///
	          "p_d_ln_rents_zillow", "p_d_ln_rents_with_fe_zillow") {
	    return local x_lab "Change in log rents"
	}
	
	if "`var'"=="d_ln_mw"            return local x_lab "Change in residence log MW"
	if "`var'"=="d_exp_ln_mw_17"     return local x_lab "Change in workplace log MW"
	
	if "`var'"=="perc_incr_rent"     return local x_lab "Percent increase in rents per sq. foot"
	if "`var'"=="perc_incr_wagebill" return local x_lab "Percent increase in wage bill"

	if "`var'"=="ratio_increases"    return local x_lab "Ratio of percent increases"
	if "`var'"=="rho"                return local x_lab "Share accruing to landlord on each dollar"	

end


main