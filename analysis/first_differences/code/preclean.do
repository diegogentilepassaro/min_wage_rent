clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	use "../../../drive/derived_large/output/baseline_rent_panel.dta", clear
	keep zipcode place_code msa countyfips statefips year_month calendar_month ///
		actual_mw medrentpricepsqft_sfcc medrentprice_sfcc
	
	foreach var in actual_mw medrentpricepsqft_sfcc medrentprice_sfcc{
		gen ln_`var' = ln(`var')
	}
	
	qui sum year_month
	gen trend = year_month - r(min) + 1
	gen trend_sq = trend^2
	gen trend_cu = trend^3
	
	xtset zipcode year_month
	
	save_data "../temp/fd_rent_panel.dta", key(zipcode year_month) replace
end

main
