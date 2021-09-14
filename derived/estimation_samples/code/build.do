set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
	local in_derived_large "../../../drive/derived_large"
	local outstub          "../../../drive/derived_large/estimation_samples"
	local logfile          "../output/data_file_manifest.log"
	
	local rent_var          "medrentpricepsqft_SFCC"
	local start_year_month  "2010m1"
	local end_year_month    "2019m12"
	local target_year_month "2015m1"
	local target_vars       "renthouse_share2010 black_share2010 med_hhinc20105 college_share20105"
	local targets           ".347 .124 62774 .386"

	foreach geo in zipcode county {
		create_baseline_panel, instub(`in_derived_large') geo(`geo') ///
			rent_var(`rent_var') target_year_month(`target_year_month') ///
			start_year_month(`start_year_month') end_year_month(`end_year_month')
		gen_vars, rent_var(`rent_var')
		add_weights, geo(`geo') target_vars(`target_vars') ///
			targets(`targets') target_year_month(`target_year_month')
			
		save_data "`outstub'/baseline_`geo'_months.dta", key(`geo' year_month) ///
			replace log(`logfile')
		
		create_full_panel, instub(`in_derived_large') geo(`geo') ///
			start_year_month(`start_year_month') end_year_month(`end_year_month')
		gen_vars, rent_var(`rent_var')
		add_weights, geo(`geo') target_vars(`target_vars') ///
			targets(`targets') target_year_month(`target_year_month')

		save_data "`outstub'/all_`geo'_months.dta", key(`geo' year_month) ///
			replace log(`logfile')
		
		create_balanced_panel, instub(`in_derived_large') geo(`geo') ///
			target_year_month(`target_year_month')
		add_weights, geo(`geo') target_vars(`target_vars') ///
			targets(`targets') target_year_month(`target_year_month')

		save_data "`outstub'/balanced_`geo'_months.dta", key(`geo' year_month) ///
			replace log(`logfile')
	}
end

program create_baseline_panel
	syntax, instub(str) geo(str) ///
		rent_var(str) target_year_month(str) ///
		start_year_month(str) end_year_month(str)

	use year_month `geo' medrentpricepsqft_SFCC using ///
	    "`instub'/`geo'_month/`geo'_month_panel.dta", clear
	keep if !missing(`rent_var')

	gcollapse (min) min_year_month = year_month, by(`geo')
	keep if min_year_month <= `=tm(`target_year_month')'

	save_data "../temp/baseline_`geo's.dta", key(`geo') ///
		replace log(none)
	
	use "`instub'/`geo'_month/`geo'_month_panel.dta", clear
	merge m:1 `geo' using "`instub'/`geo'/`geo'_cross.dta", ///
		nogen assert(2 3) keep(3)
	merge m:1 `geo' using "../temp/baseline_`geo's.dta", nogen ///
		assert(1 3) keep(3)
	
	keep if inrange(year_month, `=tm(`start_year_month')', `=tm(`end_year_month')')
	
	drop exp_mw_young exp_mw_lowinc exp_ln_mw_young ///
	exp_ln_mw_lowinc exp_mw_young_wg_mean exp_mw_lowinc_wg_mean ///
	exp_ln_mw_young_wg_mean exp_ln_mw_lowinc_wg_mean exp_mw_young_max ///
	exp_mw_lowinc_max exp_ln_mw_young_max exp_ln_mw_lowinc_max
	
	foreach var in medlistingprice_SFCC medlistingprice_low_tier ///
	medlistingprice_top_tier medpctpricereduction_SFCC ///
	medrentprice_1BR medrentprice_2BR medrentprice_3BR ///
	medrentprice_4BR medrentprice_5BR medrentprice_SFCC ///
	medrentprice_CC medrentprice_MFdxtx medrentprice_Mfr5Plus ///
	medrentprice_SF medrentprice_Studio medrentpricepsqft_1BR ///
	medrentpricepsqft_4BR medrentpricepsqft_5BR medrentpricepsqft_CC ///
	medrentpricepsqft_MFdxtx medrentpricepsqft_Mfr5Plus ///
	medrentpricepsqft_SF medrentpricepsqft_Studio ///
	pctlistings_pricedown_SFCC SalesPrevForeclosed_Share ///
	zhvi_2BR zhvi_SFCC zhvi_C zhvi_SF zri_SFCCMF zri_MF {
	    cap drop `var'
	}

	destring `geo', gen(`geo'_num)
	xtset `geo'_num year_month
end

program gen_vars
	syntax, rent_var(str)

	gen ln_med_rent_var = log(`rent_var')
	gen ln_mw           = log(actual_mw)
	rename exp_ln_mw_tot exp_ln_mw
	
	foreach ctrl_type in emp estcount avgwwage {
		gen ln_`ctrl_type'_bizserv = log(`ctrl_type'_bizserv)
		gen ln_`ctrl_type'_info    = log(`ctrl_type'_info)
		gen ln_`ctrl_type'_fin     = log(`ctrl_type'_fin)
	}
end
program add_weights
	syntax, geo(str) target_vars(str) ///
		targets(str) target_year_month(str)
	* balancing procedure: add ,in the right order the target average values from analysis/descriptive/output/desc_stats.tex
	
	preserve
		keep if year_month == `=tm(`target_year_month')'
		ebalance `target_vars', manualtargets(`targets')
		rename _webal wgt_cbsa100
		keep `geo' wgt_cbsa100
		tempfile cbsa_weights
		save "`cbsa_weights'", replace 
	restore
	merge m:1 `geo' using `cbsa_weights', ///
		nogen assert(1 3) keep(1 3)
end 

program create_full_panel
	syntax, instub(str) geo(str) ///
		start_year_month(str) end_year_month(str)
		
	use "`instub'/`geo'_month/`geo'_month_panel.dta", clear
	merge m:1 `geo' using "`instub'/`geo'/`geo'_cross.dta", ///
		nogen assert(2 3) keep(3)
	keep if inrange(year_month, `=tm(`start_year_month')', `=tm(`end_year_month')')
	
	drop exp_mw_young exp_mw_lowinc exp_ln_mw_young ///
	exp_ln_mw_lowinc exp_mw_young_wg_mean exp_mw_lowinc_wg_mean ///
	exp_ln_mw_young_wg_mean exp_ln_mw_lowinc_wg_mean exp_mw_young_max ///
	exp_mw_lowinc_max exp_ln_mw_young_max exp_ln_mw_lowinc_max
	
	foreach var in medlistingprice_SFCC medlistingprice_low_tier ///
	medlistingprice_top_tier medpctpricereduction_SFCC ///
	medrentprice_1BR medrentprice_2BR medrentprice_3BR ///
	medrentprice_4BR medrentprice_5BR medrentprice_SFCC ///
	medrentprice_CC medrentprice_MFdxtx medrentprice_Mfr5Plus ///
	medrentprice_SF medrentprice_Studio medrentpricepsqft_1BR ///
	medrentpricepsqft_4BR medrentpricepsqft_5BR medrentpricepsqft_CC ///
	medrentpricepsqft_MFdxtx medrentpricepsqft_Mfr5Plus ///
	medrentpricepsqft_SF medrentpricepsqft_Studio ///
	pctlistings_pricedown_SFCC SalesPrevForeclosed_Share ///
	zhvi_2BR zhvi_SFCC zhvi_C zhvi_SF zri_SFCCMF zri_MF {
	    cap drop `var'
	}

	destring `geo', gen(`geo'_num)
	xtset `geo'_num year_month
end

program create_balanced_panel
	syntax, instub(str) geo(str) ///
		target_year_month(str)
		
	use "`instub'/estimation_samples/baseline_`geo'_months.dta", clear
	drop wgt_cbsa100
	merge m:1 `geo' using "`instub'/`geo'/`geo'_cross.dta", ///
		nogen assert(2 3) keep(3)
	keep if year_month >= `=tm(`target_year_month')'
end

main
