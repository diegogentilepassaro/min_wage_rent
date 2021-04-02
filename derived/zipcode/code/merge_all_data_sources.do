set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
	local instub_base  "../../../drive/base_large"
	local instub_geo  "../../../base/geo_master/output"
	local outstub "../output"

	use "`instub_geo'/zip_county_place_usps_master.dta", clear
	keep if zip_max_houses == 1
    merge m:1 zipcode using "`instub_base'/demographics/zip_demo_2010.dta", ///
	    nogen keep(1 3)
    qui sum urb_share2010 if !missing(medrentpricepsqft_SFCC)
	assert `observations_with_rents' == r(N)

	compress
	save_data "`outstub'/zipcode_panel.dta", key(zipcode) ///
		log(none) replace
end

main
