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
		dactual_mw actual_mw medrentpricepsqft_* 							        ///
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010			///
		college_share20105 work_county_share20105 unemp_share20105 teen_share2010   ///
		urb_share2010 youngadult_share2010 worktravel_10_share20105 worker_foodservice20105 ///
		estcount_* avgwwage_* emp_* u1*                                             ///
		walall_29y_lowinc_ssh halall_29y_lowinc_ssh

	

	local het_vars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010"
	local het_vars "`het_vars' unemp_share20105 teen_share2010"
	local het_vars "`het_vars' urb_share2010 youngadult_share2010 worktravel_10_share20105 worker_foodservice20105"
	local het_vars "`het_vars' walall_29y_lowinc_ssh halall_29y_lowinc_ssh" 

	create_vars, 	log_vars(actual_mw medrentpricepsqft_sfcc emp_* estcount_* avgwwage_* u1*) 	///
					heterogeneity_vars(`het_vars')
	
	simplify_varnames

	xtset zipcode year_month
	gen d_ln_mw = D.ln_mw


	save_data "`outstub'/fd_rent_panel.dta", key(zipcode year_month) replace log(`logfile')
end

program create_vars
	syntax, log_vars(str) heterogeneity_vars(str)

	local log_vars_expanded "" 
	foreach v in `log_vars' {
		unab this_var: `v'
		local log_vars_expanded `"`log_vars_expanded' `this_var'"'
	}
	unab bpsvars: u1*
	foreach var in `bpsvars' {
		replace `var' = 1 + `var'
	}
	foreach var in `log_vars_expanded' {
		gen ln_`var' = ln(`var')
	}
	gen nonwhite_share2010 = 1 - white_share2010
	
	gen trend_times2 = 2*trend

	cap destring mww_shrenter_wmean2, replace 

	foreach var in `heterogeneity_vars' {

		gquantiles `var'_nat_qtl = `var', xtile nq(4)

		gquantiles `var'_st_qtl  = `var', xtile nq(4) by(statefips)
	}
	
end

program simplify_varnames
	
	cap rename ln_actual_mw                  ln_mw 
	cap rename ln_medrentpricepsqft_sfcc     ln_med_rent_psqft_sfcc
	cap rename ln_medrentpricepsqft_2br      ln_med_rent_psqft_2br
	cap rename ln_medrentpricepsqft_mfr5plus ln_med_rent_psqft_mfr5plus

end

main
