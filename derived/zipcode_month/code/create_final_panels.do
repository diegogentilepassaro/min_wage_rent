set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado


program main
	local instub "../temp"
	local indemo "../../../drive/base_large/output"
	local inqcew "../../../base/qcew/output"
	local inbps "../../../base/bps/output"
	local outstub "../../../drive/derived_large/output"
	local logfile "../output/data_file_manifest.log"

	import delim using "`indemo'/zip_demo.csv", clear
	save_data "`instub'/zip_ready.dta", replace key(zipcode) log(none)

	* Unbalanced rents
	unbalanced_panel, instub(`instub') inqcew(`inqcew') inbps(`inbps') ///
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
		create_baseline_panel, instub(`instub') var(`var')					///
			balance_date(01jul2015) start_date(01jan2010) end_date(01dec2019)
	}

	use "`instub'/baseline_medrentprice_sfcc.dta", clear
	foreach var in `rent_vars' {
		merge 1:1 zipcode year_month using "`instub'/baseline_`var'.dta", 	///
		    nogen keep(1 3)
	}
	add_covars, demo(yes) indemo(`instub') qcew(yes) inqcew(`inqcew') bps(yes) inbps(`inbps')
	save_data "`outstub'/baseline_rent_panel.dta", key(zipcode year_month) 	///
		log(`logfile') replace


	* Baseline listings
	local listing_vars "medlistingprice_low_tier" 
	foreach name in _top_tier psqft_sfcc psqft_low_tier psqft_top_tier {
		local listing_vars "`listing_vars' medlistingprice`name'"
	}

	foreach var in medlistingprice_sfcc `listing_vars' {
		create_baseline_panel, instub(`instub') var(`var') 					///
			balance_date(01jul2015) start_date(01jan2010) end_date(01dec2019)
	}

	use "`instub'/baseline_medlistingprice_sfcc.dta", clear
	foreach var in `listing_vars' {
		merge 1:1 zipcode year_month using "`instub'/baseline_`var'.dta", 	///
			nogen keep(1 3)
	}
	add_covars, demo(yes) indemo(`instub') qcew(yes) inqcew(`inqcew') bps(yes) inbps(`inbps')
	save_data "`outstub'/baseline_listing_panel.dta", key(zipcode year_month) ///
		log(`logfile') replace


	* Baseline all
	use "`instub'/zipcode_yearmonth_panel.dta", clear
	add_covars, demo(yes) indemo(`instub') qcew(no) inqcew(`inqcew') bps(no) inbps(`inbps')
	save_data "`outstub'/zipcode_yearmonth_panel_all.dta", key(zipcode year_month) ///
		log(`logfile') replace
end


program add_covars 
	syntax, demo(str) indemo(str) qcew(str) inqcew(str) bps(str) inbps(str)

	if "`demo'" == "yes" {
		merge m:1 zipcode using `indemo'/zip_ready.dta, nogen assert(1 2 3) keep(1 3) force
	}
	if "`qcew'" == "yes" {
		merge m:1 countyfips statefips year_month using `inqcew'/ind_emp_wage_countymonth.dta, nogen assert(1 2 3) keep(1 3)
	}
	if "`bps'" == "yes" {
		merge m:1 countyfips statefips year_month using `inbps'/bps_sf_cty_mon.dta, nogen assert(1 2 3) keep(1 3)
	}
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

program unbalanced_panel
	syntax, instub(str) inqcew(str) inbps(str) vars(str) start_date(str) end_date(str)

	local varnames ""
	foreach stub in `vars' {
		local varnames `"`varnames' medrentpricepsqft`stub'"'
	}

	use zipcode place_code placetype statefips msa countyfips county 	///
		year_month calendar_month `varnames' 								///
		actual_mw dactual_mw mw_event 									///
		local_abovestate_mw county_abovestate_mw local_mw 				///
		county_mw state_mw fed_mw                                       ///  
		which_mw fed_event state_event county_event local_event			///
		sal_mw_event mw_event025 mw_event075 							///
		trend trend_sq trend_cu                                         ///
		using "`instub'/zipcode_yearmonth_panel.dta", clear

	gen date = dofm(year_month)
	format date %d
		
	gen year  = year(date)
	gen month = month(date)

	drop date

	local allmissing_tot ""	
	foreach stub in `vars' {
		bys zipcode (year_month) : gen long obsno = _n
		bys zipcode (year_month) : gen countnonmissing = sum(!missing(medrentpricepsqft`stub')) if !missing(medrentpricepsqft`stub')
		bys zipcode (year_month) : gegen allmissing`stub' = min(countnonmissing)
		g miss`stub' =  (!missing(allmissing`stub'))
		bys zipcode (countnonmissing year_month) : gen entry`stub' = year_month[1] if miss`stub'==1
		format entry`stub' %tm
		drop allmissing`stub' obsno countnonmissing
		local allmissing_tot `"`allmissing_tot' miss`stub'"'
	}
	gegen miss_sum = rowtotal(`allmissing_tot')
	drop if miss_sum==0
	drop miss_sum `allmissing_tot'
	gsort zipcode year_month

	keep if (year_month >= `=mofd(td(`start_date'))' & 					///
			 year_month <= `=mofd(td(`end_date'))')
	xtset zipcode year_month

	add_covars, demo(yes) indemo(`instub') qcew(yes) inqcew(`inqcew') bps(yes) inbps(`inbps')
end 


*Execute
main
