set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local instub  "../../../drive/base_large/census_block_master"
    local outstub "../../../drive/base_large/county_master"
    local logfile "../output/data_file_manifest.log"

    use `instub'/census_block_master.dta if !missing(countyfips), clear

    make_baseline_frame, master_geo(countyfips)

    assign_geography, instub(`instub') master_geo(countyfips) geo_to_assign(statefips)
    assign_geography, instub(`instub') master_geo(countyfips) geo_to_assign(cbsa)

    strcompress
    save_data "`outstub'/county_master.dta",                  ///
        key(countyfips) log(`logfile') replace
    export delimited "`outstub'/county_master.csv", replace
end

main
