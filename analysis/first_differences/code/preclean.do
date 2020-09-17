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
		college_share20105 work_county_share20105 trend_sq poor_share20105          ///
		lo_hhinc_share20105 hi_hhinc_share20105 unemp_share20105                    ///
		employee_share20105 teen_share2010 youngadult_share2010                     ///
		sh_mww_all1 sh_mww_all2 sh_mww_wmean1 sh_mww_wmean2 mww_shsub25_all1        ///
		mww_shsub25_all2 mww_shblack_all1 mww_shblack_all2 sh_mww_renter_all1       ///
		sh_mww_renter_all2 sh_mww_renter_wmean1 sh_mww_renter_wmean2                ///
		mww_shrenter_all1 mww_shrenter_all2 mww_shrenter_wmean1 mww_shrenter_wmean2 ///
	

	local het_vars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010"
	local het_vars "`het_vars' poor_share20105 lo_hhinc_share20105 hi_hhinc_share20105 unemp_share20105" 
	local het_vars "`het_vars' employee_share20105 teen_share2010 youngadult_share2010"
	local het_vars "`het_vars' sh_mww_all1 sh_mww_all2 sh_mww_wmean1 sh_mww_wmean2"
	local het_vars "`het_vars' sh_mww_renter_all2 sh_mww_renter_wmean1 sh_mww_renter_wmean2"
	local het_vars "`het_vars' mww_shrenter_all1 mww_shrenter_all2 mww_shrenter_wmean1 mww_shrenter_wmean2" 

	create_vars, 	log_vars(actual_mw medrentpricepsqft_sfcc medrentprice_sfcc) 	///
					heterogeneity_vars(`het_vars')
	
	simplify_varnames

	xtset zipcode year_month
	gen d_ln_mw = D.ln_mw

	save_data "`outstub'/fd_rent_panel.dta", key(zipcode year_month) replace log(`logfile')
end

program create_vars
	syntax, log_vars(str) heterogeneity_vars(str)

	foreach var in `log_vars' {
		gen ln_`var' = ln(`var')
	}

	gen nonwhite_share2010 = 1 - white_share2010
	
	gen trend_times2 = 2*trend

	foreach var in `heterogeneity_vars' {
		cap destring `var', replace
		*xtile `var'_nat_dec = `var', nq(10)
		xtile `var'_nat_qtl = `var', nq(5)
		levelsof statefips, local(states)

		foreach state in `states'{
			*xtile deciles_`state'_`var' = `var' if statefips == `state', nq(10)
			xtile qtiles_`state'_`var' = `var' if statefips == `state', nq(5)
		}
		*egen `var'_st_dec = rowtotal(deciles_*)
		egen `var'_st_qtl = rowtotal(qtiles_*)
		
		*drop deciles_* qtiles_*
		drop qtiles_*
	}
end

program simplify_varnames
	
    rename 	(ln_actual_mw 	ln_medrentpricepsqft_sfcc) 		///
    		(ln_mw 			ln_med_rent_psqft)

end

main
