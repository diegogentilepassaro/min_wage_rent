set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
	local instub  "../../../drive/derived_large/output"
	local outstub "../../../drive/derived_large/output"
	local logfile "../output/data_file_manifest.log"

	local rent_var1 		"medrentprice_sfcc"
	local other_rent_vars	"medrentpricepsqft_sfcc"

	local listing_var1 		 "medlistingprice_sfcc"
	local other_listing_vars "medlistingpricepsqft_sfcc"


	use "`instub'/zipcode_yearmonth_panel_all.dta", clear

	* Build all panel
	collapse_to_county_quarter, rent_vars(`rent_var1' `other_rent_vars') 			///
							 listing_vars(`listing_var1' `other_listing_vars')
	
	add_employment_wages
	add_other_vars
	
	save_data "`outstub'/county_quarter_panel_all.dta", 							///
	    key(countyfips year_quarter) replace
	
	* Build baseline panels
	build_baseline_panel, outstub(`outstub') logfile(`logfile') name(rent)	 		///
		var1(`rent_var1') other_vars(`other_rent_vars') 							///
		balance_date(01jan2013) start_date(01jan2010) end_date(12dec2019)

	build_baseline_panel, outstub(`outstub') logfile(`logfile') name(listing)		///
		var1(`listing_var1') other_vars(`other_listing_vars') 						///
		balance_date(01jan2013) start_date(01jan2010) end_date(12dec2019)
end

program add_employment_wages

	tostring countyfips, replace
	replace countyfips  = string(real(countyfips),"%05.0f")
	
	tostring statefips, replace
	replace statefips  = string(real(statefips),"%02.0f")
	
	merge 1:1 year_quarter countyfips using "../temp/county_quarter_emp_wage.dta", ///
		nogen keep(1 3) 
end

program add_other_vars

	qui sum year_quarter
	gen trend = year_quarter - r(min) + 1
	gen trend_sq = trend^2
	gen trend_cu = trend^3

	egen avg_quarter_employment = rowmean(employment_month*)
end

program collapse_to_county_quarter
	syntax, rent_vars(str) listing_vars(str)
	
	gen year_quarter = qofd(dofm(year_month))
	format %tq year_quarter
	
	collapse (mean) `rent_vars' `listing_vars' 									///
		(max) mw_event actual_mw dactual_mw sal_mw_event mw_event025 mw_event075 ///
		calendar_quarter = calendar_month houses10_zip_county, 					///
		by(zipcode year_quarter placename placetype city msa countyfips county 	///
			statefips stateabb)
		
	xtset zipcode year_quarter /* to assert is keyed on zipcode year_quarter */
	
	collapse (mean) `rent_vars' `listing_vars' 									///
		(max) mw_event actual_mw dactual_mw sal_mw_event mw_event025 mw_event075 ///
		[aweight = houses10_zip_county], by(countyfips year_quarter 			///
											calendar_quarter county statefips stateabb)
end

program build_baseline_panel
	syntax, outstub(str) logfile(str) name(str) var1(str) other_vars(str) 		///
			balance_date(str) start_date(str) end_date(str)

	foreach var in `var1' `other_vars' {
		create_baseline_panel, var(`var') balance_date(`balance_date') 			///
			start_date(`start_date') end_date(`end_date')
	}
	
	use "../temp/baseline_`var1'.dta", clear
	foreach var in `other_vars' {
		merge 1:1 countyfips year_quarter using "../temp/baseline_`var'.dta", 	///
			nogen keep(1 3)
	}

	save_data "`outstub'/baseline_`name'_county_quarter.dta", 					///
		key(countyfips year_quarter) replace log(`logfile')
end

program create_baseline_panel
    syntax, var(str) balance_date(str) start_date(str) end_date(str)
	
	use "../../../drive/derived_large/output/county_quarter_panel_all.dta", clear
	keep if (year_quarter >= `=qofd(td(`start_date'))' & 				///
			 year_quarter <= `=qofd(td(`end_date'))')

	preserve
		keep if year_quarter == `=qofd(td(`balance_date'))'
		keep if !missing(`var')
		keep countyfips
		save_data "../temp/`var'_nonmiss_countyfips.dta", replace 		///
			key(countyfips) log(none)
	restore
	
	merge m:1 countyfips using "../temp/`var'_nonmiss_countyfips.dta", 	///
		keep(3) nogen
	
	rename countyfips countyfips_str
	encode countyfips_str, gen(countyfips)
	
	xtset countyfips year_quarter
	assert r(balanced) == "strongly balanced"
	
	save_data "../temp/baseline_`var'.dta", key(countyfips year_quarter) ///
		replace log(none)
end

main
