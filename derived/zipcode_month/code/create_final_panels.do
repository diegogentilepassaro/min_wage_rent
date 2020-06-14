set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
	local instub "../temp"
	local indemo "../../../base/demographics/output/"
	local outstub "../../../drive/derived_large/output"
	local logfile "../output/data_file_manifest.log"

	local add_demo = "yes"

	if "`add_demo'" == "yes" {
		import delim using "`indemo'zip_demo.csv", clear
		save_data "`instub'/zip_ready.dta", replace key(zipcode) log(`logfile')
	} 


	* Baseline rents
	local rent_vars "medrentprice_mfr5plus" 
	foreach name in _2br psqft_sfcc psqft_2br psqft_mfr5plus {
		local rent_vars "`rent_vars' medrentprice`name'"
	}

	foreach var in medrentprice_sfcc `rent_vars' {
		create_baseline_panel, instub(`instub') var(`var')					///
			balance_date(01jan2015) start_date(01jan2010) end_date(12dec2019)
	}

	use "`instub'/baseline_medrentprice_sfcc.dta", clear
	foreach var in `rent_vars' {
		merge 1:1 zipcode year_month using "`instub'/baseline_`var'.dta", 	///
		    nogen keep(1 3)
	}
	if "`add_demo'" == "yes" {
		merge m:1 zipcode using `instub'/zip_ready.dta, nogen assert(1 2 3) keep(1 3)	
	}

	save_data "`outstub'/baseline_rent_panel.dta", key(zipcode year_month) 	///
		log(`logfile') replace


	* Baseline listings
	local listing_vars "medlistingprice_low_tier" 
	foreach name in _top_tier psqft_sfcc psqft_low_tier psqft_top_tier {
		local listing_vars "`listing_vars' medlistingprice`name'"
	}

	foreach var in medlistingprice_sfcc `listing_vars' {
		create_baseline_panel, instub(`instub') var(`var') 					///
			balance_date(01jan2015) start_date(01jan2010) end_date(12dec2019)
	}

	use "`instub'/baseline_medlistingprice_sfcc.dta", clear
	foreach var in `listing_vars' {
		merge 1:1 zipcode year_month using "`instub'/baseline_`var'.dta", 	///
			nogen keep(1 3)
	}
	if "`add_demo'" == "yes" {
		merge m:1 zipcode using `instub'/zip_ready.dta, nogen assert(1 2 3) keep(1 3)	
	}


	save_data "`outstub'/baseline_listing_panel.dta", key(zipcode year_month) ///
		log(`logfile') replace


	* Baseline all
	use "`instub'/zipcode_yearmonth_panel.dta", clear
	if "`add_demo'" == "yes" {
		merge m:1 zipcode using `instub'/zip_ready.dta, nogen assert(1 2 3) keep(1 3)	
	}
	save_data "`outstub'/zipcode_yearmonth_panel_all.dta", key(zipcode year_month) ///
		log(`logfile') replace
end

program create_baseline_panel
	syntax, instub(str) var(str) balance_date(str) start_date(str) end_date(str)
	
	use zipcode place_code placetype statefips msa countyfips county 	///
		year_month calendar_month `var' 								///
		actual_mw dactual_mw mw_event 									///
		local_abovestate_mw county_abovestate_mw local_mw 				///
		county_mw state_mw fed_mw which_mw										///
		sal_mw_event mw_event025 mw_event075 							///
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

main
