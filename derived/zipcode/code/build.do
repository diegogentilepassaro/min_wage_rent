set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_base_large  "../../../drive/base_large"
    local instub_geo     "../../../base/geo_master/output"
    local outstub        "../../../drive/derived_large/zipcode"
    local logfile        "../output/data_file_manifest.log"

    build_zillow_zipcode_stats, instub(`in_base_large')

    use "`instub_geo'/zip_county_place_usps_master.dta", clear

    merge 1:1 zipcode using "../temp/zillow_zipcodes_with_rents.dta",         ///
        nogen assert(1 3)
    merge 1:1 zipcode using "`in_base_large'/demographics/zip_demo_2010.dta", ///
        nogen keep(1 3)
    merge 1:1 zipcode using "`in_base_large'/lodes/zipcode_own_shares.dta",   ///
        nogen keep(1 3)

    strcompress
    save_data "`outstub'/zipcode_cross.dta",                                  ///
        key(zipcode) log(`logfile') replace
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
