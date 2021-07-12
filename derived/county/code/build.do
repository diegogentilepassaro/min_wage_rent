set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_base_large "../../../drive/base_large"
    local instub_geo    "../../../base/geo_master/output"
    local outstub       "../../../drive/derived_large/county"
    local logfile       "../output/data_file_manifest.log"

    build_zillow_county_stats, instub(`in_base_large')

    use countyfips statefips cbsa10 ///
        using "`instub_geo'/zip_county_place_usps_all.dta", clear
    duplicates drop
    isid countyfips

    merge 1:1 countyfips using "../temp/zillow_counties_with_rents.dta", ///
        nogen assert(1 3)
    merge 1:1 countyfips using "`in_base_large'/demographics/county_demo_2010.dta", ///
        nogen keep(1 3)
    merge 1:1 countyfips using "`in_base_large'/lodes/county_own_shares.dta", ///
        nogen keep(1 3) /*making a note here that we drop two `_merge == 2` rogue counties*/

    strcompress
	rename countyfips county
    save_data "`outstub'/county_cross.dta", replace ///
        key(county) log(`logfile')
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
