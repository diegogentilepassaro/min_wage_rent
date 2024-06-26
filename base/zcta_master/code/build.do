set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local instub  "../../../drive/base_large/census_block_master"
    local outstub "../../../drive/base_large/zcta_master"
    local logfile "../output/data_file_manifest.log"

    use `instub'/census_block_master.dta if !missing(zipcode), clear

    make_baseline_frame, master_geo(zcta)

    assign_geography, instub(`instub') master_geo(zcta) geo_to_assign(tract)
    assign_geography, instub(`instub') master_geo(zcta) geo_to_assign(place_code)
    assign_geography, instub(`instub') master_geo(zcta) geo_to_assign(countyfips)
    assign_geography, instub(`instub') master_geo(zcta) geo_to_assign(statefips)
    assign_geography, instub(`instub') master_geo(zcta) geo_to_assign(cbsa)

    strcompress
    save_data "`outstub'/zcta_master.dta",                  ///
        key(zcta) log(`logfile') replace
    export delimited "`outstub'/zcta_master.csv", replace
end

main
