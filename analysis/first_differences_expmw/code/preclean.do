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
		college_share20105 work_county_share20105 unemp_share20105 teen_share2010   ///
		sh_treated* exp_mw* ///
		walall_29y_lowinc_ssh halall_29y_lowinc_ssh walall_29y_lowinc_zsh halall_29y_lowinc_zsh

	local het_vars "walall_29y_lowinc_ssh halall_29y_lowinc_ssh walall_29y_lowinc_zsh halall_29y_lowinc_zsh"
 

	create_vars, 	log_vars(actual_mw medrentpricepsqft_sfcc exp_mw*) 	///
					heterogeneity_vars(`het_vars')
	
	xtset zipcode year_month
	simplify_varnames
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
	cap unab bpsvars: u1*
	foreach var in `bpsvars' {
		cap replace `var' = 1 + `var'
	}
	foreach var in `log_vars_expanded' {
		gen ln_`var' = ln(`var')
	}

	gen nonwhite_share2010 = 1 - white_share2010
	
	gen trend_times2 = 2*trend

	foreach var in `heterogeneity_vars' {

		gquantiles `var'_nat_qtl = `var', xtile nq(4)

		gquantiles `var'_st_qtl  = `var', xtile nq(4) by(statefips)
	}

	foreach var in  exp_mw_totjob exp_mw_job_young exp_mw_job_lowinc ln_exp_mw_totjob {
		g D`var' = D.`var'
		order D`var', after(`var')
	}
	g treat_dir = (dactual_mw>0)
	bys zipcode (year_month): gegen ziptreated_dir = max(treat_dir)
end

program simplify_varnames
	
	cap rename ln_actual_mw                  ln_mw 
	cap rename ln_exp_mw_totjob              ln_expmw	
	cap rename ln_medrentpricepsqft_sfcc     ln_med_rent_psqft_sfcc
	cap rename ln_medrentpricepsqft_2br      ln_med_rent_psqft_2br
	cap rename ln_medrentpricepsqft_mfr5plus ln_med_rent_psqft_mfr5plus

end

main
