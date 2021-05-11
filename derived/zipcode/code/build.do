set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
    local instub_base  "../../../drive/base_large"
    local instub_geo  "../../../base/geo_master/output"
    local outstub "../output"

    build_zillow_zipcode_stats, instub(`instub_base')

    use "`instub_geo'/zip_county_place_usps_master.dta", clear
    merge 1:1 zipcode using "../temp/zillow_zipcodes_with_rents.dta", ///
        nogen assert(1 3)
    merge 1:1 zipcode using "`instub_base'/demographics/zip_demo_2010.dta", ///
        nogen keep(1 3)
    merge 1:1 zipcode using "`instub_base'/lodes/zipcode_own_shares.dta", ///
        nogen keep(1 3)

    strcompress
    save_data "`outstub'/zipcode_panel.dta", ///
        key(zipcode) replace
end

program build_zillow_zipcode_stats
    syntax, instub(str)

    use "`instub'/zillow/zillow_zipcode_clean.dta"

    keep if !missing(medrentpricepsqft_SFCC)
    collapse (count) n_months_zillow_rents = medrentpricepsqft_SFCC, by(zipcode)
    tostring zipcode, format(%05.0f) replace

    save "../temp/zillow_zipcodes_with_rents.dta", replace
end

main
