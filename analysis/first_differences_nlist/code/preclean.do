clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/output"
	local outstub "../temp"
	local logfile "../output/data_file_manifest.log"

	use "`instub'/baseline_rent_panel.dta", clear 
	keep zipcode place_code msa countyfips statefips 								         ///
		year_month calendar_month trend trend_sq trend_cu					 		         ///
		dactual_mw actual_mw medrentpricepsqft_* 							                 ///
		medlistingpricepsqft_sfcc monthlylistings_nsa_sfcc newmonthlylistings_nsa_sfcc       ///
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010 housing_units2010 ///
		college_share20105 work_county_share20105 unemp_share20105 teen_share2010            ///
		estcount_* avgwwage_* emp_* u1*												

	
	local het_vars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010"
	local het_vars "`het_vars' unemp_share20105 teen_share2010" 

	create_vars, log_vars(actual_mw medrentpricepsqft_sfcc ///
						  medlistingpricepsqft_sfcc monthlylistings_nsa_sfcc newmonthlylistings_nsa_sfcc ///
						  emp_* estcount_* avgwwage_* u1*) 	///
				 heterogeneity_vars(`het_vars')
	
	simplify_varnames

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

	foreach var in `heterogeneity_vars' {

		gquantiles `var'_nat_qtl = `var', xtile nq(4)

		gquantiles `var'_st_qtl  = `var', xtile nq(4) by(statefips)
	}

	gen nonwhite_share2010 = 1 - white_share2010
	gen trend_times2       = 2*trend
	gen listwgt            =  housing_units2010 / monthlylistings_nsa_sfcc

	local rent_var "medrentpricepsqft_sfcc"
	gen indicator = (missing(`rent_var') & !missing(L.`rent_var')) | ///
					(!missing(`rent_var') & missing(L.`rent_var')) | ///
					(zipcode != zipcode[_n-1]) // Indicates start of missing group
	gen miss_group_id = sum(indicator)
	bysort zipcode (year_month): egen first_missing_group = min(miss_group_id)

	gen in_panel = (miss_group_id != first_missing_group)
	gen miss_in_panel = (in_panel & missing(`rent_var'))
	replace miss_in_panel = . if !in_panel

	drop indicator miss_group_id first_missing_group

	gen enter_panel = (in_panel == 1 & in_panel[_n-1]==0)
	gen mw_event = dactual_mw > 0	
end

program simplify_varnames
	
	cap rename ln_actual_mw                   ln_mw 
	cap rename ln_medrentpricepsqft_sfcc      ln_med_rent_psqft_sfcc
	cap rename ln_medrentpricepsqft_2br       ln_med_rent_psqft_2br
	cap rename ln_medrentpricepsqft_mfr5plus  ln_med_rent_psqft_mfr5plus
	cap rename ln_medlistingpricepsqft_sfcc   ln_med_list_psqft_sfcc
	cap rename monthlylistings_nsa_sfcc		  n_listings_sfcc
	cap rename ln_monthlylistings_nsa_sfcc    ln_n_listings_sfcc
	cap rename newmonthlylistings_nsa_sfcc    n_newlistings_sfcc
	cap rename ln_newmonthlylistings_nsa_sfcc ln_n_newlistings_sfcc

	xtset zipcode year_month
	gen d_ln_mw = D.ln_mw
end

main
