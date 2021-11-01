clear all
set more off
set maxvar 32000

program main
	local instub  "../output"
	local insizes "../../../derived/zipcode_rent_sqft_income_preds/output"
	local irs     "../../../drive/base_large/irs_soi"
	local geo     "../../../base/geo_master/output"

	
	use "`irs'/irs_zip.dta", clear
	keep if year == 2018
	keep zipcode num_wage_hhlds_irs
	duplicates drop zipcode, force
    save "../temp/n_wage_hhlds.dta", replace
	
	use `instub'/d_ln_rents_cf_predictions.dta, clear
	merge 1:1 zipcode using  `instub'/ln_wagebill_cf_predictions.dta, ///
	    nogen keepusing(ln_wagebill_pre n_hhlds_pre)
	merge 1:1 zipcode using "`insizes'/housing_sqft_per_zipcode.dta", ///
	    nogen keep(1 3) keepusing(sqft_from_listings sqft_from_rents)
	merge 1:1 zipcode using "../temp/n_wage_hhlds.dta", nogen keep(1 3)
	merge 1:1 zipcode using "`geo'/zip_county_place_usps_master.dta", ///
	   nogen keep(1 3) keepusing(rural)
	compute_vars
	
	foreach var in d_ln_mw d_exp_ln_mw_17 ///
	               d_ln_rents d_rents  ///
				   d_ln_rents_zillow d_rents_zillow ///
				   d_ln_wagebill d_wagebill d_wagebill_per_hhld ///
				   d_wagebill_per_wage_hhld d_ln_wagebill_zillow d_wagebill_zillow ///
				   d_wagebill_per_hhld_zillow d_wagebill_per_wage_hhld_zillow {
		
		get_xlabel, var(`var')
		local x_lab = r(x_lab)
		
		unique zipcode if !missing(`var')
		local n_zip = r(unique)
	
		hist `var', percent bin(20) ///
			xtitle("`x_lab'") ytitle("Percentage") note("ZIP codes: `n_zip'") ///
			xlabel(, labsize(small)) ylabel(, labsize(small)) ///
			graphregion(color(white)) bgcolor(white)
		
		graph export "../output/`var'.png", replace
		graph export "../output/`var'.eps", replace
	}
end

program compute_vars
	local exp_ln_mw_on_ln_wagebill = 0.1588706
	local exp_ln_mw_on_ln_rents = 0.064464323
	local ln_mw_on_ln_rents = -0.030246906
	
	gen d_ln_rents = `exp_ln_mw_on_ln_rents'*d_exp_ln_mw_17 + `ln_mw_on_ln_rents'*d_ln_mw
	gen ln_rents_post = d_ln_rents + ln_rents_pre 
    gen d_rents    = exp(ln_rents_post) - exp(ln_rents_pre)
	
	gen d_ln_rents_zillow = d_ln_rents if !missing(ln_rents_pre)
    gen d_rents_zillow    = d_rents if !missing(ln_rents_pre)

	gen ln_wagebill_post = ln_wagebill_pre + `exp_ln_mw_on_ln_wagebill'*d_exp_ln_mw_17
	gen d_ln_wagebill = ln_wagebill_post - ln_wagebill_pre
	gen d_wagebill = exp(ln_wagebill_post) - exp(ln_wagebill_pre)
	gen d_wagebill_per_hhld = d_wagebill/n_hhlds_pre
	gen d_wagebill_per_wage_hhld = d_wagebill/num_wage_hhlds_irs
	
	gen d_ln_wagebill_zillow = d_ln_wagebill if !missing(ln_rents_pre)
	gen d_wagebill_zillow = d_wagebill if !missing(ln_rents_pre)
	gen d_wagebill_per_hhld_zillow = d_wagebill_per_hhld if !missing(ln_rents_pre)
	gen d_wagebill_per_wage_hhld_zillow =d_wagebill_per_wage_hhld if !missing(ln_rents_pre)
end

program get_xlabel, rclass
    syntax, var(str)
	
	if inlist("`var'", "p_d_ln_rents", "p_d_ln_rents_with_fe", ///
	          "p_d_ln_rents_zillow", "p_d_ln_rents_with_fe_zillow") {
	    return local x_lab "Change in log rents"
	}
	
	if "`var'"=="d_ln_mw"           return local x_lab "Change in residence log MW"
	if "`var'"=="d_exp_ln_mw_17"    return local x_lab "Change in workplace log MW"
	
	if "`var'"=="d_ln_rents"           return local x_lab "Change in log rents per sq. foot"
	if "`var'"=="d_ln_rents_zillow"    return local x_lab "Change in log rents per sq. foot"

	if "`var'"=="d_rents"              return local x_lab "Change in rents per sq. foot"
	if "`var'"=="d_rents_zillow"       return local x_lab "Change in rents per sq. foot"

	if "`var'"=="d_ln_wagebill"        return local x_lab "Change in log wage bill"
	if "`var'"=="d_ln_wagebill_zillow" return local x_lab "Change in log wage bill"

	if "`var'"=="d_wagebill"          return local x_lab "Change in wage bill ($)"
	if "`var'"=="d_wagebill_zillow"   return local x_lab "Change in wage bill ($)"

	if "`var'"=="d_wagebill_per_hhld"         return local x_lab "Change in wage bill per household ($)"
	if "`var'"=="d_wagebill_per_hhld_zillow"  return local x_lab "Change in wage bill per household ($)"	

    if "`var'"=="d_wagebill_per_wage_hhld"    return local x_lab "Change in wage bill per household with wages ($)"
	if "`var'"=="d_wagebill_per_wage_hhld_zillow"  return local x_lab "Change in wage bill per household with wages ($)"	
end


main
