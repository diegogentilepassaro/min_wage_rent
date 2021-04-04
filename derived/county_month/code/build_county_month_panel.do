set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
	local instub_derived  "../../../drive/derived_large"
	local instub_geo  "../../../base/geo_master/output"
	local instub_base  "../../../drive/base_large"
	local instub_qcew "../../../base/qcew/output"
	local outstub "../../../drive/derived_large/county_month"
	local logfile "../output/data_file_manifest.log"

	use countyfips statefips cbsa10 ///
	    using "`instub_geo'/zip_county_place_usps_all.dta", clear
    duplicates drop
	isid countyfips

	destring countyfips, replace
    merge 1:m countyfips using "`instub_derived'/min_wage/county_statutory_mw.dta", ///
	   nogen assert(3) keepusing(year month actual_mw_wg_mean ///
	   actual_mw_ignore_local_wg_mean local_mw county_mw fed_mw state_mw ///
	   actual_mw binding_mw actual_mw_ignore_local binding_mw_ignore_local)
	   
	tostring countyfips, replace
    merge 1:1 countyfips year month using "`instub_base'/zillow/zillow_county_clean.dta"
	qui sum medrentpricepsqft_SFCC if _merge == 2 & inrange(year, 2010, 2019)	
	*assert r(N) == 0 /* This assertion fails and it should't. We are loosing counties with Zillow data.*/
	/* Among the _merge == 2 I found pretty important counties like Sacramento, New Haven, or New London. */
	/* I wonder why they are not in our geo master? */
	keep if inlist(_merge, 1, 3)
	drop _merge
	

	/* Should we build experienced MW data by county? Probably we should! */
	
	/* Should we build ACS population by county-year? Probably we should! */

    add_dates
	merge m:1 statefips countyfips year_month ///
	    using "`instub_qcew'/ind_emp_wage_countymonth.dta", nogen keep(1 3)

	strcompress
	save_data "`outstub'/county_month_panel.dta", replace ///
	    key(countyfips year month) log(`logfile')
end

program add_dates
    gen day = 1
	gen date = mdy(month, day, year)
	gen year_month = mofd(date)
	format year_month %tm
	gen year_quarter = qofd(date)
	format year_quarter %tq
	drop day date
end

main
