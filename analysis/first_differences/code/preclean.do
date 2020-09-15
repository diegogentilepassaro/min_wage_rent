clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/output"
	local outstub "../temp"
	local logfile "../output/data_file_manifest.log"


	use "`instub'/baseline_rent_panel.dta", clear
	STOP 
	keep zipcode place_code msa countyfips statefips 								///
		year_month calendar_month trend trend_sq trend_cu					 		///
		actual_mw medrentpricepsqft_sfcc medrentprice_sfcc 							///
		med_hhinc20105 renthouse_share2010 white_share2010 black_share2010			///
		college_share20105 work_county_share20105 trend_sq poor_share20105          ///
		lo_hhinc_share20105 hi_hhinc_share20105 unemp_share20105                    ///
		employee_share20105 teen_share2010 youngadult_share2010                     ///
		sh_mww_all2 mww_shsub25_all2 mww_shsub25_all1 mww_shblack_all2              ///
		mww_sub25_shblack_all1 sh_mww_renter_all2 mww_shrenter_all2 sh_mww_wmean    ///
		mww_shrenter_wmean
	

	local het_vars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010 poor_share20105 lo_hhinc_share20105 hi_hhinc_share20105 unemp_share20105 employee_share20105 teen_share2010 youngadult_share2010 sh_mww_all2 sh_mww_renter_all2 mww_shrenter_all2 sh_mww_wmean mww_shrenter_wmean mww_shblack_all2 mww_shsub25_all2 mww_shsub25_all1"
	

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
		*xtile `var'_nat_dec = `var', nq(10)
		xtile `var'_nat_qtl = `var', nq(4)
		levelsof statefips, local(states)

		foreach state in `states'{
			*xtile deciles_`state'_`var' = `var' if statefips == `state', nq(10)
			xtile qtiles_`state'_`var' = `var' if statefips == `state', nq(4)
		}
		*egen `var'_st_dec = rowtotal(deciles_*)
		egen `var'_st_qtl = rowtotal(qtiles_*)
		*drop deciles_* qtiles_*
		drop qtiles_*
	}

	*Option A: first non missing rent observation for each unit
	g missing_rent = missing(medrentprice_sfcc)
	//bys zipcode (missing year_month): g first_rent = medrentprice_sfcc[1]

	*Option b: Date for rent 2014m1 (90 percent of zipcode has nonmissing values)
	g temp = medrentprice_sfcc if year_month==tm(2014m1)
	bys zipcode (year_month): egen first_rent = min(temp)
	drop temp missing_rent
	

	gsort zipcode year_month
	g med_hhinc20105_mon = med_hhinc20105 / 12
	g rent_inc_ratio = first_rent / med_hhinc20105_mon 

	xtile rent_inc_ratio_qtl = rent_inc_ratio, nq(4)

end

program simplify_varnames
	
    rename 	(ln_actual_mw 	ln_medrentpricepsqft_sfcc) 		///
    		(ln_mw 			ln_med_rent_psqft)

end

main
