clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	use "../../../drive/derived_large/output/baseline_rent_panel.dta", clear
	keep zipcode place_code msa countyfips statefips year_month calendar_month ///
		actual_mw medrentpricepsqft_sfcc medrentprice_sfcc trend trend_sq trend_cu
	
	foreach var in actual_mw medrentpricepsqft_sfcc medrentprice_sfcc{
		gen ln_`var' = ln(`var')
	}

	xtset zipcode year_month
	
    rename (ln_actual_mw ln_medrentpricepsqft_sfcc) (ln_mw ln_med_rent_psqft)
	
	
	save_data "../temp/fd_rent_panel.dta", key(zipcode year_month) replace
end

main
