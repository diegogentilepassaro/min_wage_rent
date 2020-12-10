clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/output"
	local outstub "../temp"
	local logfile "../output/data_file_manifest.log"

	identify_baseline, instub(`instub')
	local mergevars "`r(mergevars)'"

	use zipcode place_code msa countyfips statefips 								///
		year_month calendar_month trend trend_sq trend_cu					 		///
		dactual_mw actual_mw medrentpricepsqft_sfcc							        ///
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010			///
		college_share20105 work_county_share20105 entry*                   ///
		estcount_* avgwwage_* emp_* u1*                                             ///
		using `instub'/unbal_rent_panel.dta, clear 

	merge 1:1 `mergevars' using ../temp/baseline_rent_panel.dta, keep(1 3)
	g basepanel = (_m==3)
	drop _m

	local het_vars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010"
	local het_vars "`het_vars' nonwhite_share2010 work_county_share20105"

	create_vars, 	log_vars(actual_mw medrentpricepsqft_* emp_* estcount_* avgwwage_* u1*) 	///
					heterogeneity_vars(`het_vars')
	
	simplify_varnames

	xtset zipcode year_month
	gen d_ln_mw = D.ln_mw

	local weights_vars "renthouse_share2010 black_share2010 med_hhinc20105 college_share20105"
	make_weights, weights_vars(`weights_vars')

	save_data "`outstub'/unbal_fd_rent_panel.dta", key(zipcode year_month) replace log(`logfile')

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

program identify_baseline, rclass
	syntax, instub(str)
	use zipcode place_code msa countyfips statefips 								///
		year_month calendar_month trend trend_sq trend_cu					 		///
		dactual_mw actual_mw medrentpricepsqft_sfcc							        ///
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010			///
		college_share20105 work_county_share20105                  ///
		estcount_* avgwwage_* emp_* u1*                                             ///
		using `instub'/baseline_rent_panel.dta, clear
		save "../temp/baseline_rent_panel.dta", replace

		local mergevars "zipcode place_code msa countyfips statefips"
		local mergevars `"`mergevars' year_month calendar_month trend trend_sq trend_cu"'
		local mergevars `"`mergevars' dactual_mw actual_mw medrentpricepsqft_sfcc"'
		local mergevars `"`mergevars' med_hhinc20105 renthouse_share2010 white_share2010 black_share2010"'
		local mergevars `"`mergevars' college_share20105 work_county_share20105"'
		unab mergevars2: estcount_* avgwwage_* emp_* u1*
		local mergevars `"`mergevars' `mergevars2'"'

		return local mergevars `mergevars'
end 	

program make_weights
	syntax, weights_vars(str)
	* balancing procedure: add ,in the right order the target average values from analysis/descriptive/output/desc_stats.tex
	preserve
	keep if year_month==tm(2019m12)
	ebalance `weights_vars', manualtargets(.347 .124 62774 .386)
	rename _webal wgt_cbsa100
	keep zipcode wgt_cbsa100
	tempfile cbsa_weights
	save "`cbsa_weights'", replace 
	restore
	merge m:1 zipcode using `cbsa_weights', nogen assert(1 2 3) keep(1 3)
end 


* Execute 
main 
