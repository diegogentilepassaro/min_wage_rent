set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado


program main
	local logfile "../output/data_file_manifest.log"

    use "../output/zipcode_yearmonth_panel.dta", clear
    gen_vars
sabelo

	* Unbalanced rents
	unbalanced_panel, instub(`temp') inqcew(`inqcew') inbps(`inbps') inlodes(`inlodes') ///
					  vars(_sfcc _2br _mfr5plus) ///
					  start_date(01jan2010) end_date(01dec2019)
  	save_data `outstub'/unbal_rent_panel.dta, key(zipcode year_month) 	///
		log(`logfile') replace 

	* Baseline rents
	local rent_vars "medrentprice_mfr5plus" 
	foreach name in _2br psqft_sfcc psqft_2br psqft_mfr5plus {
		local rent_vars "`rent_vars' medrentprice`name'"
	}

	foreach var in medrentprice_sfcc `rent_vars' {
		create_baseline_panel, instub(`temp') var(`var')					///
			balance_date(01jul2015) start_date(01jan2010) end_date(01dec2019)
	}

	use "`temp'/baseline_medrentprice_sfcc.dta", clear
	foreach var in `rent_vars' {
		merge 1:1 zipcode year_month using "`temp'/baseline_`var'.dta", 	///
		    nogen keep(1 3)
	}
	add_covars, demo(yes) indemo(`temp') qcew(yes) inqcew(`inqcew') bps(yes) inbps(`inbps') lodes(yes) inlodes(`inlodes')
	save_data "`outstub'/baseline_rent_panel.dta", key(zipcode year_month) 	///
		log(`logfile') replace

	/* * Baseline listings
	local listing_vars "medlistingprice_low_tier" 
	foreach name in _top_tier psqft_sfcc psqft_low_tier psqft_top_tier {
		local listing_vars "`listing_vars' medlistingprice`name'"
	}

	foreach var in medlistingprice_sfcc `listing_vars' {
		create_baseline_panel, instub(`temp') var(`var') 					///
			balance_date(01jul2015) start_date(01jan2010) end_date(01dec2019)
	}

	use "`temp'/baseline_medlistingprice_sfcc.dta", clear
	foreach var in `listing_vars' {
		merge 1:1 zipcode year_month using "`temp'/baseline_`var'.dta", 	///
			nogen keep(1 3)
	}
	add_covars, demo(yes) indemo(`temp') qcew(yes) inqcew(`inqcew') bps(yes) inbps(`inbps') lodes(yes) inlodes(`inlodes') 
	save_data "`outstub'/baseline_listing_panel.dta", key(zipcode year_month) ///
		log(`logfile') replace */


	* Baseline all
	use "`temp'/zipcode_yearmonth_panel.dta", clear
	add_covars, demo(yes) indemo(`temp') qcew(no) inqcew(`inqcew') bps(no) inbps(`inbps') lodes(no) inlodes(`inlodes')
	save_data "`outstub'/zipcode_yearmonth_panel_all.dta", key(zipcode year_month) ///
		log(`logfile') replace
end

program gen_vars
	qui sum year_month
	gen trend = year_month - r(min) + 1
	gen trend_sq = trend^2
	gen trend_cu = trend^3

	xtset zipcode year_month
	gen d_actual_mw = D.actual_mw
	gen mw_event = (d_actual_mw > 0)
	
	gen event_month = mw_event == 1
	replace event_month = 1 if year_month != year_month[_n-1] + 1  // zipcode changes
	gen event_month_id = sum(event_month)

	bysort event_month_id: gen months_since = _n - 1
	bysort event_month_id: gen months_until = _N - months_since
	bysort event_month_id: replace months_until = 0 if _N == months_until
	drop event_month_id event_month        
	
	gen sal_mw_event = (d_actual_mw >= 0.5)
	gen mw_event025  = (d_actual_mw >= 0.25)
	gen mw_event075  = (d_actual_mw >= 0.75)
end

program create_baseline_panel
	syntax, instub(str) var(str) balance_date(str) start_date(str) end_date(str)
	
	use zipcode place_code placetype statefips msa countyfips county 	///
		year_month calendar_month `var' 								///
		actual_mw dactual_mw mw_event 									///
		local_abovestate_mw county_abovestate_mw local_mw 				///
		county_mw state_mw fed_mw                                       ///  
		which_mw fed_event state_event county_event local_event			///
		sal_mw_event mw_event025 mw_event075 							///
		trend trend_sq trend_cu                                         ///
		medlistingpricepsqft_sfcc monthlylistings_nsa_sfcc              ///
		newmonthlylistings_nsa_sfcc 									///
		using "`instub'/zipcode_yearmonth_panel.dta", clear

	keep if (year_month >= `=mofd(td(`start_date'))' & 					///
			 year_month <= `=mofd(td(`end_date'))')

	preserve
		keep if year_month == `=mofd(td(`balance_date'))'
		keep if !missing(`var')
		keep zipcode
		save_data "../temp/`var'_nonmiss_zipcodes.dta", replace 		///
			key(zipcode) log(none)
	restore
	
	merge m:1 zipcode using "../temp/`var'_nonmiss_zipcodes.dta", 		///
		keep(3) nogen
		
	xtset zipcode year_month
	assert r(balanced) == "strongly balanced"

	save_data "../temp/baseline_`var'.dta", key(zipcode year_month) 	///
		replace log(none)
end

*Execute
main
