clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
	local instub      "../../../drive/derived_large/zipcode_month"
	
	use zipcode year month medlistingprice_SFCC ///
	    medlistingpricepsqft_SFCC medrentprice_SFCC medrentpricepsqft_SFCC ///
		using "`instub'/zipcode_month_panel.dta", clear
	collapse (mean) medlistingprice_SFCC medlistingpricepsqft_SFCC ///
	    medrentprice_SFCC medrentpricepsqft_SFCC, by(zipcode)

	replace medrentpricepsqft_SFCC = . if medrentpricepsqft_SFCC >= 10
    gen sqft_from_listings = medlistingprice_SFCC/medlistingpricepsqft_SFCC
	replace sqft_from_listings = . if sqft_from_listings >= 9000
    gen sqft_from_rents    = medrentprice_SFCC/medrentpricepsqft_SFCC
	replace sqft_from_rents = . if sqft_from_rents >= 9000
	
	scatter sqft_from_listings sqft_from_rents if sqft_from_rents, ///
	    graphregion(color(white)) bgcolor(white)
	graph export "../output/sqft_rents_vs_listings.png", replace
	
	histogram sqft_from_listings, ///
	    graphregion(color(white)) bgcolor(white)
	graph export "../output/histogram_sqft_listings.png", replace
	
	histogram sqft_from_rents if sqft_from_rents, ///
	    graphregion(color(white)) bgcolor(white)
	graph export "../output/histogram_sqft_rents.png", replace
	
	keep zipcode sqft_from_listings sqft_from_rents medrentpricepsqft_SFCC
	rename medrentpricepsqft_SFCC rent_psqft
	
	save_data "../output/housing_sqft_per_zipcode.dta", key(zipcode) replace
end

main
