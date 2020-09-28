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
		dactual_mw actual_mw medrentpricepsqft_* 							///
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010			///
		college_share20105 work_county_share20105
	

	local het_vars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010"
	local het_vars "`het_vars' nonwhite_share2010 work_county_share20105"

	create_vars, 	log_vars(actual_mw medrentpricepsqft_sfcc medrentpricepsqft_2br medrentpricepsqft_mfr5plus) 	///
					heterogeneity_vars(`het_vars')
	
	simplify_varnames

	xtset zipcode year_month
	gen d_ln_mw = D.ln_mw

	save_data "`outstub'/fd_rent_panel.dta", key(zipcode year_month) replace log(`logfile')

	use zipcode place_code msa countyfips statefips 								///
		year_month calendar_month trend trend_sq trend_cu					 		///
		dactual_mw actual_mw medrentpricepsqft_*							///
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010			///
		college_share20105 work_county_share20105 entry* ///
		using `instub'/unbal_rent_panel.dta, clear 

	local het_vars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010"
	local het_vars "`het_vars' nonwhite_share2010 work_county_share20105"

	create_vars, 	log_vars(actual_mw medrentpricepsqft_sfcc medrentpricepsqft_2br medrentpricepsqft_mfr5plus) 	///
					heterogeneity_vars(`het_vars')
	
	simplify_varnames

	xtset zipcode year_month
	gen d_ln_mw = D.ln_mw

	save_data "`outstub'/unbal_fd_rent_panel.dta", key(zipcode year_month) replace log(`logfile')



end

program create_vars
	syntax, log_vars(str) heterogeneity_vars(str)

	foreach var in `log_vars' {
		gen ln_`var' = ln(`var')
	}

	gen nonwhite_share2010 = 1 - white_share2010
	
	gen trend_times2 = 2*trend

	if "`heterogeneity_vars'"!="no" {
		foreach var in `heterogeneity_vars' {
			*xtile `var'_nat_dec = `var', nq(10)
			xtile `var'_nat_qtl = `var', nq(4)
			levelsof statefips, local(states)

			foreach state in `states'{
				*xtile deciles_`state'_`var' = `var' if statefips == `state', nq(10)
				xtile qtiles_`state'_`var' = `var' if statefips == `state', nq(4)
			}
			*egen `var'_st_dec = rowtotal(deciles_*)
			egen `var'_st_qtl = rowtotal(qtiles_*)
			replace `var'_st_qtl = . if `var'_st_qtl==0
			
			*drop deciles_* qtiles_*
			drop qtiles_*
		}		
	} 
end

program simplify_varnames
	
    rename 	(ln_actual_mw 	ln_medrentpricepsqft_sfcc ln_medrentpricepsqft_2br ln_medrentpricepsqft_mfr5plus) 		///
    		(ln_mw 			ln_med_rent_psqft_sfcc ln_med_rent_psqft_2br ln_med_rent_psqft_mfr5plus)

end

main
