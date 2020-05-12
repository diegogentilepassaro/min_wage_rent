clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    use "../temp/baseline_rent_panel_24.dta", clear
    
	local reps = 30
	local seed = 8
	
    xtset, clear
	eststo clear
    eststo: bootstrap effect_per_sqft = r(effect_per_sqft) ///
	    total_rent_increase1000 = r(total_rent_increase1000) ///
		total_rent_increase1500 = r(total_rent_increase1500) ///
		total_rent_increase2000 = r(total_rent_increase2000) ///
		incr_sf_monthly_income = r(incr_sf_monthly_income) ///
		passthrough1000 = r(passthrough1000) ///
		passthrough1500 = r(passthrough1500) ///
		passthrough2000 = r(passthrough2000), rep(`reps') seed(`seed') ///
	    cluster(zipcode): thing_to_bootstrap, event_var(sal_mw_event)
    eststo: bootstrap effect_per_sqft = r(effect_per_sqft) ///
	    total_rent_increase1000 = r(total_rent_increase1000) ///
		total_rent_increase1500 = r(total_rent_increase1500) ///
		total_rent_increase2000 = r(total_rent_increase2000) ///
		incr_sf_monthly_income = r(incr_sf_monthly_income) ///
		passthrough1000 = r(passthrough1000) ///
		passthrough1500 = r(passthrough1500) ///
		passthrough2000 = r(passthrough2000), rep(`reps') seed(`seed') ///
	    cluster(zipcode): thing_to_bootstrap, event_var(mw_event025)
    eststo: bootstrap effect_per_sqft = r(effect_per_sqft) ///
	    total_rent_increase1000 = r(total_rent_increase1000) ///
		total_rent_increase1500 = r(total_rent_increase1500) ///
		total_rent_increase2000 = r(total_rent_increase2000) ///
		incr_sf_monthly_income = r(incr_sf_monthly_income) ///
		passthrough1000 = r(passthrough1000) ///
		passthrough1500 = r(passthrough1500) ///
		passthrough2000 = r(passthrough2000), rep(`reps') seed(`seed') ///
	    cluster(zipcode): thing_to_bootstrap, event_var(mw_event075)

	esttab * using "../output/bootstrap.tex", ci replace ///
	    mtitle("MW changes of at least \$0.5" "MW changes of at least \$0.25" "MW changes of at least \$0.75") ///
	    coeflabels(effect_per_sqft "Rent increase per square feet" ///
		total_rent_increase1000 "Total rent increase (assuming 1000 square feet)" ///
		total_rent_increase1500 "Total rent increase (assuming 1500 square feet)" ///
		total_rent_increase2000 "Total rent increase (assuming 2000 square feet)" ///
		incr_sf_monthly_income "Increase in income of a household with 2 full time minimum wages" ///
		passthrough1000 "Implied passthrough from MW incrtease to rents (assuming 1000 square feet)" ///
	    passthrough1500 "Implied passthrough from MW incrtease to rents (assuming 1500 square feet)" ///
		passthrough2000 "Implied passthrough from MW incrtease to rents (assuming 2000 square feet)") ///
		stats(N N_clust N_reps, fmt(%9.0g %9.0g %9.0g) ///
	    labels("Number of zipcode-months" "Number of Zipcodes" "Number of bootstrap repetitions"))
		
end

program thing_to_bootstrap, rclass
    syntax, event_var(str)
	
    reghdfe medrentpricepsqft_sfcc ib24.last_`event_var'_rel_months24, nocons ///
		absorb(zipcode calendar_month year_month)
	local sum_coeffs = 0
	forval i = 25(1)49 {
        local sum_coeffs = `sum_coeffs' + _b[`i'.last_`event_var'_rel_months24]
		local effect_per_sqft = `sum_coeffs'/25
	}
	
	reghdfe dactual_mw ib24.last_`event_var'_rel_months24, nocons ///
		absorb(zipcode calendar_month year_month)
	local used_mw_change = _b[25.last_`event_var'_rel_months24]
	local incr_sf_monthly_income = (2*40*4.35)*`used_mw_change'
	
	local home_size1000 = 1000
	local home_size1500 = 1500
	local home_size2000 = 2000
	
	return scalar effect_per_sqft = `effect_per_sqft'
	
	return scalar total_rent_increase1000 = `home_size1000'*`effect_per_sqft'
	return scalar total_rent_increase1500 = `home_size1500'*`effect_per_sqft'
	return scalar total_rent_increase2000 = `home_size2000'*`effect_per_sqft'

	return scalar incr_sf_monthly_income = `incr_sf_monthly_income'
	
    return scalar passthrough1000 = (`home_size1000'*`effect_per_sqft')/`incr_sf_monthly_income'
    return scalar passthrough1500 = (`home_size1500'*`effect_per_sqft')/`incr_sf_monthly_income'
    return scalar passthrough2000 = (`home_size2000'*`effect_per_sqft')/`incr_sf_monthly_income'

end

main
