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
		actual_mw medrentpricepsqft_sfcc medrentprice_sfcc 							///
		med_hhinc20105 renthouse_share2010
	
	create_vars, 	log_vars(actual_mw medrentpricepsqft_sfcc medrentprice_sfcc) 	///
					heterogeneity_vars(med_hhinc20105 renthouse_share2010)
	
	simplify_varnames

	xtset zipcode year_month
	
	save_data "`outstub'/fd_rent_panel.dta", key(zipcode year_month) replace log(`logfile')
end

program create_vars
	syntax, log_vars(str) heterogeneity_vars(str)

	foreach var in `log_vars' {
		gen ln_`var' = ln(`var')
	}

	foreach var in `heterogeneity_vars' {
		xtile `var'_nat_dec = `var', nq(10)
		levelsof statefips, local(states)

		foreach state in `states'{
			xtile deciles_`state'_`var' = `var' if statefips == `state', nq(10)
		}
		egen `var'_st_dec = rowtotal(deciles_*)
		drop deciles_*
	}
end

program simplify_varnames
	
    rename 	(ln_actual_mw 	ln_medrentpricepsqft_sfcc) 		///
    		(ln_mw 			ln_med_rent_psqft)

end

main
