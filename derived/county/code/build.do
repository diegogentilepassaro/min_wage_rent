set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_geo        "../../../drive/base_large/county_master"
    local in_demo       "../../../drive/derived_large/demographics_at_baseline"
    local in_base_large "../../../drive/base_large"
    local outstub       "../../../drive/derived_large/county"
    local logfile       "../output/data_file_manifest.log"

    build_zillow_county_stats, instub(`in_base_large')

    use countyfips statefips cbsa using "`in_geo'/county_master.dta", clear

    merge 1:1 countyfips using "../temp/zillow_counties_with_rents.dta", ///
	    nogen keep(1 3)
    merge 1:1 countyfips using "`in_demo'/county.dta", ///
        nogen keep(1 3)

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
