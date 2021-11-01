clear all
set more off
set maxvar 32000

program main
	local instub "../output"
	
	use `instub'/d_ln_rents_cf_predictions.dta, clear
	merge 1:1 zipcode using  `instub'/ln_wagebill_cf_predictions.dta, nogen
	
	compute_vars
	
	foreach var in d_ln_mw d_exp_ln_mw_17 ///
	               d_rents p_d_ln_rents p_d_ln_rents_with_fe ///
				   p_d_ln_rents_zillow p_d_ln_rents_with_fe_zillow {
		
		get_xlabel, var(`var')
		local x_lab = r(x_lab)
		
		unique zipcode if !missing(`var')
		local n_zip = r(unique)
	
		hist `var', percent bin(15) ///
			xtitle("`x_lab'") ytitle("Percentage") note("ZIP codes: `n_zip'") ///
			xlabel(, labsize(small)) ylabel(, labsize(small)) ///
			graphregion(color(white)) bgcolor(white)
		
		graph export "../output/`var'.png", replace
		graph export "../output/`var'.eps", replace
	}

end

program compute_vars

	gen p_d_ln_rents_zillow         = p_d_ln_rents         if !missing(ln_rents_pre)
	gen p_d_ln_rents_with_fe_zillow = p_d_ln_rents_with_fe if !missing(ln_rents_pre)
	
	gen rents_pre  = exp(ln_rents_pre)
	gen rents_post = exp(p_d_ln_rents + ln_rents_pre)
    gen d_rents    = rents_post - rents_pre
end

program get_xlabel, rclass
    syntax, var(str)
	
	if inlist("`var'", "p_d_ln_rents", "p_d_ln_rents_with_fe", ///
	          "p_d_ln_rents_zillow", "p_d_ln_rents_with_fe_zillow") {
	    return local x_lab "Change in log rents"
	}
	
	if "`var'"=="d_rents"             return local x_lab "Change in rents per sq. foot"
	if "`var'"=="d_ln_wagebill"       return local x_lab "Change in log wage bill"
	if "`var'"=="d_wagebill"          return local x_lab "Change in wage bill ($)"
	if "`var'"=="d_wagebill_per_hhld" return local x_lab "Change in wage bill per household ($)"
	
end


main
