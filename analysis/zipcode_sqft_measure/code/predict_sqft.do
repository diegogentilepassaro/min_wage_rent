clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
	local instub "../../../base/geo_master/output"

	use "`instub'/zip_county_place_usps_master.dta", clear
	drop place_name county_name cbsa10_name state_abb 
	merge 1:1 zipcode using "../output/housing_sqft_per_zipcode.dta", nogen assert(3)
}

main
