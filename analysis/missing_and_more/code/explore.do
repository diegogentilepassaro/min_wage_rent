clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
	use "../temp/fd_rent_panel.dta", clear

	bysort zipcode: egen enter_date = min(year_month) if !missing(medrentpricepsqft_sfcc)
	gen first_obs = (year_month == enter_date)

	preserve
	keep if first_obs == 1 & enter_date > tm(2010m1) /*the second condition doesn't do anything*/
    unique zipcode
	local nbr_late_zipcodes = r(N)
	collapse (sum) nbr_zipocde_entries = first_obs, by(calendar_month)
	gen share_entries = nbr_zipocde_entries/`nbr_late_zipcodes'
		
	line share_entries calendar_month, ///
	    graphregion(color(white)) bgcolor(white)
	graph export "../output/share_of_zipcode_entries_by_month.png", replace
	restore
    
	local w = 5
	eststo clear
	
	preserve
	keep if year_month >= tm(2015m7)
	eststo: reghdfe D.medrentpricepsqft_sfcc L(-`w'/`w').D.ln_mw, ///
	    absorb(year_month) vce(cluster statefip) nocons
	restore
	
	preserve
	keep if enter_date <= tm(2010m12)
	collapse (count) year_month, by(zipcode)
	keep zipcode 
	save "../temp/early_zipcodes.dta", replace
	restore
	
	preserve
	merge m:1 zipcode using "../temp/early_zipcodes.dta", keep(3)
	xtset zipcode year_month
	eststo: reghdfe D.medrentpricepsqft_sfcc L(-`w'/`w').D.ln_mw, ///
	    absorb(year_month) vce(cluster statefip) nocons
	restore

    esttab * using "../output/balanced_samples.tex", compress se replace ///
		b(%9.4f) se(%9.4f) ///
		stats(r2 N, fmt(%9.3f %9.0gc) ///
		labels("R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) ///
		nonote mtitles("Fully balanced (July 2015 and on)" "Early zipcodes only") 
end



main
