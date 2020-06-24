clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local reps = 200
	local seed = 8
	local ZFE_trend "zipcode year_month c.trend#i.countyfips c.trend_sq#i.countyfips"
	local cluster_se "statefips"

	use "`instub'/baseline_rent_panel_6.dta", clear

	xtset, clear
	eststo clear
	foreach event_var in mw_event025 sal_mw_event mw_event075 {
		eststo: bootstrap effect_per_sqft = r(effect_per_sqft) 					///
			total_rent_increase1000 = r(total_rent_increase1000) 				///
			total_rent_increase1500 = r(total_rent_increase1500) 				///
			total_rent_increase2000 = r(total_rent_increase2000) 				///
			incr_sf_monthly_income = r(incr_sf_monthly_income) 					///
			passthrough1000 = r(passthrough1000) 								///
			passthrough1500 = r(passthrough1500) 								///
			passthrough2000 = r(passthrough2000), rep(`reps') seed(`seed') 		///
			cluster(zipcode): thing_to_bootstrap, depvar(medrentpricepsqft_sfcc) ///
			event_var(`event_var') window(6) 									///
			fe(`ZFE_trend') cluster(`cluster_se')
			
		sum dactual_mw if (last_`event_var'_rel_months6 == 7 & !missing(medrentpricepsqft_sfcc))
		estadd local avg_mw_change = round(r(mean),0.01)
}

	esttab * using "`outstub'/bootstrap_rent.tex", ci replace 							///
		mtitle("MW changes of at least \\$0.25" "MW changes of at least \\$0.5" "MW changes of at least \\$0.75") ///
		coeflabels(effect_per_sqft "Rent $ \\Delta$ per square foot" 						///
		total_rent_increase1000 "Total $ \\Delta$ in rent (1000 sq feet)" 			///
		total_rent_increase1500 "Total $ \\Delta$ in rent (1500 sq feet)" 			///
		total_rent_increase2000 "Total $ \\Delta$ in rent (2000 sq feet)" 			///
		incr_sf_monthly_income "$ \\Delta$ in income for a hh with 2 full time MW earners" ///
		passthrough1000 "Implied passthrough from MW to rents (1000 sq feet)" 	///
		passthrough1500 "Implied passthrough from MW to rents (1500 sq feet)" 	///
		passthrough2000 "Implied passthrough from MW to rents (2000 sq feet)") ///
		stats(avg_mw_change N N_clust N_reps, 											///
		fmt(%9.0g %9.0g %9.0g %9.0g %9.0g %9.0g) 										///
		labels("Average MW change" "Number of zipcode-months" 							///
		"Number of Zipcodes" "Number of bootstrap repetitions")) nonotes
end

program thing_to_bootstrap, rclass
	syntax, depvar(str) event_var(str) window(int) fe(str) cluster(str)

	local people_per_hh = 2
	local hs_per_week   = 40
	local weeks_per_month = 4.35

	local window_plus1 = `window' + 1
	local window_span = 2*`window' + 1
	
	local rel_time_dummies "i0.last_`event_var'_rel_months`window'#1.treated"
	forvalues i = 1(1)`window_span' {
		if `i' != `window' {
			local rel_time_dummies "`rel_time_dummies' i`i'.last_`event_var'_rel_months`window'#1.treated"
		}
	}
	local rel_time_dummies "`rel_time_dummies' i1000.last_`event_var'_rel_months`window'#1.treated"

	reghdfe `depvar' `rel_time_dummies' `controls' `if', nocons 	///
		absorb(`absorb') vce(cluster `cluster')		

	local sum_coeffs = 0
	forval i = `window_plus1'(1)`window_span' {
		local sum_coeffs = `sum_coeffs' + _b[`i'.last_`event_var'_rel_months`window'#1.treated]
		local effect_per_sqft = `sum_coeffs'/`window_plus1'
	}
	
	sum dactual_mw if (last_`event_var'_rel_months6 == `window_plus1' & !missing(`depvar'))
	local used_mw_change = round(r(mean),0.01)
	local incr_sf_monthly_income = (`people_per_hh'*`hs_per_week'*`weeks_per_month')*`used_mw_change'
	
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
