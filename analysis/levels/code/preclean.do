clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/output"
	local outstub "../temp"
	local logfile "../output/data_file_manifest.log"

	use "`instub'/baseline_rent_panel.dta", clear 
	keep zipcode place_code msa countyfips statefips 								///
		year_month calendar_month trend trend_sq trend_cu					 		///
		dactual_mw actual_mw medrentpricepsqft_*
		
	gen ln_med_rent_psqft_sfcc = log(medrentpricepsqft_sfcc)
	gen ln_mw = log(actual_mw)
	
	simplify_varnames

	xtset zipcode year_month

	save_data "`outstub'/rent_panel.dta", key(zipcode year_month) replace log(`logfile')
end

program simplify_varnames
	
	cap rename ln_actual_mw                  ln_mw 
	cap rename ln_medrentpricepsqft_sfcc     ln_med_rent_psqft_sfcc
	cap rename ln_medrentpricepsqft_2br      ln_med_rent_psqft_2br
	cap rename ln_medrentpricepsqft_mfr5plus ln_med_rent_psqft_mfr5plus
end

main
