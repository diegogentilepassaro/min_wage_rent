set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local instub  "../../../drive/base_large/census_block_master"
    local outstub "../../../drive/base_large/tract_master"
    local logfile "../output/data_file_manifest.log"

    use `instub'/census_block_master.dta if !missing(tract), clear

    make_baseline_frame, master_geo(tract)

    assign_geography, instub(`instub') master_geo(tract) geo_to_assign(zipcode)
    assign_geography, instub(`instub') master_geo(tract) geo_to_assign(place_code)
    assign_geography, instub(`instub') master_geo(tract) geo_to_assign(place_name)
    assign_geography, instub(`instub') master_geo(tract) geo_to_assign(countyfips)
    assign_geography, instub(`instub') master_geo(tract) geo_to_assign(countyfips_name)
    assign_geography, instub(`instub') master_geo(tract) geo_to_assign(statefips)
    assign_geography, instub(`instub') master_geo(tract) geo_to_assign(cbsa)

    strcompress
    save_data "`outstub'/tract_master.dta",                  ///
        key(tract) log(`logfile') replace
    export delimited "`outstub'/tract_master.csv", replace
end

main
