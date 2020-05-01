clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    use "../temp/baseline_rent_panel_24.dta", clear

    xtset, clear
	eststo clear
    eststo: bootstrap effect_per_sqft = r(effect_per_sqft) ///
	    total_rent_increase = r(total_rent_increase) ///
		incr_sf_monthly_income = r(incr_sf_monthly_income) ///
		passthrough = r(passthrough), rep(200) seed(8) ///
	    cluster(zipcode): thing_to_bootstrap
	esttab * using "../output/bootstrap.tex", mtitle("Bootstrap") ci replace ///
	    coeflabels(effect_per_sqft "Rent increase per square feet" ///
		total_rent_increase "Total rent increase (assuming 1500 square feet)" ///
		incr_sf_monthly_income "Increase in income of a household with 2 full time minimum wages" ///
		passthrough "Implied passthrough from MW to rents") ///
		stats(N N_clust N_reps, fmt(%9.0g %9.0g %9.0g) ///
	    labels("Number of zipcode-months" "Number of Zipcodes" "Number of bootstrap repetitions"))
end

program thing_to_bootstrap, rclass

    reghdfe medrentpricepsqft_sfcc ib24.last_sal_mw_event_rel_months24, nocons ///
		absorb(zipcode calendar_month year_month)
	local sum_coeffs = 0
	forval i = 25(1)49 {
        local sum_coeffs = `sum_coeffs' + _b[`i'.last_sal_mw_event_rel_months24]
		local effect_per_sqft = `sum_coeffs'/25
	}
	
	reghdfe dactual_mw ib24.last_sal_mw_event_rel_months24, nocons ///
		absorb(zipcode calendar_month year_month)
	local used_mw_change = _b[25.last_sal_mw_event_rel_months24]
	local incr_sf_monthly_income = (2*40*4.35)*`used_mw_change'
	
	local avg_sf_home_size = 1500
	
	return scalar effect_per_sqft = `effect_per_sqft'
	return scalar total_rent_increase = `avg_sf_home_size'*`effect_per_sqft'
	return scalar incr_sf_monthly_income = `incr_sf_monthly_income'
    return scalar passthrough = (`avg_sf_home_size'*`effect_per_sqft')/`incr_sf_monthly_income'
end

main
