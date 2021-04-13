set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
    local instub_base  "../../../drive/base_large"
    local instub_geo  "../../../base/geo_master/output"
    local outstub "../output"

    build_zillow_county_stats, instub(`instub_base')

    use countyfips statefips cbsa10 ///
        using "`instub_geo'/zip_county_place_usps_all.dta", clear
    duplicates drop
    isid countyfips

    merge 1:1 countyfips using "../temp/zillow_counties_with_rents.dta", ///
        nogen assert(1 3)
    destring countyfips, replace
    merge 1:1 countyfips using "`instub_base'/demographics/county_demo_2010.dta", ///
        nogen keep(1 3)

    /* Should we build own shares for county? */

    strcompress
    save_data "`outstub'/county_panel.dta", ///
        key(countyfips) replace
end

program build_zillow_county_stats
    syntax, instub(str)

    use "`instub'/zillow/zillow_county_clean.dta", clear

    keep if !missing(medrentpricepsqft_SFCC)
    collapse (count) n_months_zillow_rents = medrentpricepsqft_SFCC, by(countyfips)
    tostring countyfips, format(%05.0f) replace

    save "../temp/zillow_counties_with_rents.dta", replace
end

main
