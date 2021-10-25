clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
	local instub "../../../base/geo_master/output"

	use "`instub'/zip_county_place_usps_master.dta", clear
	drop place_name county_name cbsa10_name state_abb 
	merge 1:1 zipcode using "../output/housing_sqft_per_zipcode.dta", ///
	    nogen assert(3)
		
	local covariates "area_sqmi pop2020_esri houses_zcta_place_county"
	local absorb "place_code countyfips cbsa10 statefips zipcode_type"
	
	reghdfe sqft_from_rents `covariates', absorb(`absorb')
	predict p_sqft_from_rents, xb
	gen imp_sqft_from_rents = sqft_from_rents
	replace imp_sqft_from_rents = p_sqft_from_rents if missing(imp_sqft_from_rents)
	
	reghdfe sqft_from_listings `covariates', absorb(`absorb')
	predict p_sqft_from_listings, xb
	gen imp_sqft_from_listings = sqft_from_rents
	replace imp_sqft_from_listings = p_sqft_from_listings if missing(imp_sqft_from_listings)
	
	keep zipcode zcta sqft_from_rents sqft_from_listings ///
	    p_sqft_from_rents p_sqft_from_listings ///
		imp_sqft_from_rents imp_sqft_from_listings
	save_data "../output/sqft_data_with_predictions.dta", ///
	    key(zipcode) replace
	export delimited "../output/sqft_data_with_predictions.csv", replace
end

main
