set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
	local instub_derived  "../../../drive/derived_large"
	local instub_base  "../../../drive/base_large"
	local outstub "../output"

	use "`instub_derived'/min_wage/zip_statutory_mw.dta", clear
    merge 1:1 zipcode year month using "`instub_base'/zillow/zillow_zipcode_clean.dta"
	qui sum medrentpricepsqft_SFCC if _merge == 2 & inrange(year, 2010, 2019)	
	assert r(N) == 0
	keep if inlist(_merge, 1, 3)
	drop _merge
	
    merge 1:1 zipcode year month using "`instub_derived'/min_wage/zip_experienced_mw.dta", ///
	    nogen keep(1 3)
	qui sum medrentpricepsqft_SFCC if !missing(medrentpricepsqft_SFCC)
	local observations_with_rents = r(N)
	sum exp_ln_mw_tot if !missing(medrentpricepsqft_SFCC)
	assert `observations_with_rents' == r(N)

    merge m:1 zipcode year using "`instub_base'/demographics/acs_population_zipyear.dta", ///
	    nogen keep(1 3)
    qui sum acs_pop if !missing(medrentpricepsqft_SFCC)
	assert `observations_with_rents' == r(N)
	
	compress
	save_data "`outstub'/zipcode_yearmonth_panel.dta", key(zipcode year month) ///
		log(none) replace
end

main
