clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	use "../temp/fd_rent_panel.dta", clear
	
	eststo clear
	eststo: reghdfe D.ln_medrentpricepsqft_sfcc D.ln_actual_mw, ///
	    absorb(year_month) vce(cluster statefips) nocons
	estadd local zs_trend "No"	
	estadd local zs_trend_sq "No"
	estadd local zs_trend_cu "No"

	eststo: reghdfe D.ln_medrentpricepsqft_sfcc D.ln_actual_mw, ///
	    absorb(year_month c.trend#i.zipcode) vce(cluster statefips) nocons
	estadd local zs_trend "Yes"	
	estadd local zs_trend_sq "No"
	estadd local zs_trend_cu "No"

	
	eststo: reghdfe D.ln_medrentpricepsqft_sfcc D.ln_actual_mw, ///
	    absorb(year_month c.trend#i.zipcode c.trend_sq#i.zipcode) ///
		vce(cluster statefips) nocons
	estadd local zs_trend "Yes"	
	estadd local zs_trend_sq "Yes"
	estadd local zs_trend_cu "No"

	eststo: reghdfe D.ln_medrentpricepsqft_sfcc D.ln_actual_mw, ///
	    absorb(year_month c.trend#i.zipcode c.trend_sq#i.zipcode c.trend_cu#i.zipcode) ///
		vce(cluster statefips) nocons
	estadd local zs_trend "Yes"	
	estadd local zs_trend_sq "Yes"
	estadd local zs_trend_cu "Yes"
	
 	esttab * using "../output/fd_table.tex", keep(D.ln_actual_mw) compress se replace ///
        stats(zs_trend zs_trend_sq zs_trend_cu r2 N, fmt(%9.3f %9.0g) ///
		labels("Zipcode-specifc linear trend" ///
	    "Zipcode-specific linear and square trend" ///
		"Zipcode-specific linear, square and cubic trend" ///
	    "R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) ///
		nonote
end

main
