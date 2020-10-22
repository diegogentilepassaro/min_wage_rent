clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 


program main 
	local instub "../../../drive/derived_large/output"
	local outstub "../temp"

	use zipcode place_code msa countyfips statefips 								   ///
		year_month calendar_month trend trend_sq trend_cu					 		   ///
		actual_mw medrentpricepsqft_sfcc medrentprice_sfcc 							   ///
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010			   ///
		college_share20105 unemp_share20105 housing_units2010 			       ///
		medlistingpricepsqft_sfcc monthlylistings_nsa_sfcc newmonthlylistings_nsa_sfcc ///
		using "`instub'/baseline_rent_panel.dta", clear

	local het_vars "med_hhinc20105 unemp_share20105 college_share20105 black_share2010"


	create_vars, 	log_vars(actual_mw medrentpricepsqft_sfcc medrentprice_sfcc medlistingpricepsqft_sfcc monthlylistings_nsa_sfcc newmonthlylistings_nsa_sfcc) 	///
					heterogeneity_vars(`het_vars')
	
	simplify_varnames
	xtset zipcode year_month
	gen d_ln_mw = D.ln_mw

	save_data "`outstub'/fd_rent_panel_listrent.dta", key(zipcode year_month) replace log(`logfile')
end

program create_vars
	syntax, log_vars(str) heterogeneity_vars(str) 

	foreach var in `log_vars' {
		gen ln_`var' = ln(`var')
	}
	gen nonwhite_share2010 = 1 - white_share2010
	
	gen trend_times2 = 2*trend

	g listwgt =  housing_units2010 / monthlylistings_nsa_sfcc


	foreach var in `heterogeneity_vars' {

		gquantiles `var'_nat_qtl = `var', xtile nq(4)

		gquantiles `var'_st_qtl  = `var', xtile nq(4) by(statefips)
	}

end

program simplify_varnames
	
    rename 	(ln_actual_mw 	ln_medrentpricepsqft_sfcc) 		///
    		(ln_mw 			ln_med_rent_psqft)

end

main
