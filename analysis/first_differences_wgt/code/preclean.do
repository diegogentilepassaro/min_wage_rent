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
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010			///
		college_share20105 work_county_share20105 walall* welall* halall*
	

	local het_vars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010"
	local het_vars "`het_vars' nonwhite_share2010 work_county_share20105"
	local het_vars "`het_vars' walall_njob_29young_zsh walall_njob_29young_ssh halall_njob_29young_zsh halall_njob_29young_ssh welall_njob_29young_zsh welall_njob_29young_ssh walall_29y_lowinc_zsh walall_29y_lowinc_ssh halall_29y_lowinc_zsh halall_29y_lowinc_ssh"

	local wgtvars "renthouse_share2010 black_share2010 med_hhinc20105 college_share20105"

	create_vars, 	log_vars(actual_mw medrentpricepsqft_sfcc medrentprice_sfcc) 	///
					heterogeneity_vars(`het_vars') weights_vars(`wgtvars')
	
	simplify_varnames

	xtset zipcode year_month
	gen d_ln_mw = D.ln_mw

	save_data "`outstub'/fd_rent_panel.dta", key(zipcode year_month) replace log(`logfile')
end

program create_vars
	syntax, log_vars(str) heterogeneity_vars(str) weights_vars(str)

	foreach var in `log_vars' {
		gen ln_`var' = ln(`var')
	}

	gen nonwhite_share2010 = 1 - white_share2010
	
	gen trend_times2 = 2*trend

	* balancing procedure: add ,in the right order the target average values from analysis/descriptive/output/desc_stats.tex
	ebalance `weights_vars', manualtargets(.347 .124 62774 .386)
	rename _webal wgt_cbsa100
	

	foreach var in `heterogeneity_vars' {
		di "`var'"
		xtile `var'_nat_qtl = `var', nq(4)
		egen `var'_st_qtl = xtile(`var'), by(statefips) nq(4)
	}

end

program simplify_varnames
	
    rename 	(ln_actual_mw 	ln_medrentpricepsqft_sfcc) 		///
    		(ln_mw 			ln_med_rent_psqft)

end

main
