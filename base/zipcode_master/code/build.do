set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub  "../../../drive/base_large/census_block_master"
    local outstub "../../../drive/base_large/zipcode_master"
    local logfile "../output/data_file_manifest.log"

    use `instub'/census_block_master.dta if !missing(zipcode), clear

    make_baseline_frame

    assign_geography, instub(`instub') geo(place_code)
    assign_geography, instub(`instub') geo(countyfips)
    assign_geography, instub(`instub') geo(statefips)
    assign_geography, instub(`instub') geo(cbsa)

    strcompress
    save_data "`outstub'/zipcode_master.dta",                  ///
        key(zipcode) log(`logfile') replace
    export delimited "`outstub'/zipcode_master.csv", replace
end

program make_baseline_frame

    bys zipcode: gen  n_census_blocks = _N
    bys zipcode: egen n_places        = nvals(place_code)   // Must install egenmore
    bys zipcode: egen n_counties      = nvals(countyfips)
    bys zipcode: egen n_states        = nvals(statefips)

    preserve
        gcollapse (mean) share_rural_wgt_houses = rural ///
                [aweight = num_house10], by(zipcode)

        save ../temp/share_rural.dta, replace
    restore

    gcollapse (max) n_census_blocks n_counties  ///
                    n_places        n_states    ///
              (sum) num_houses   = num_house10  ///
                    population   = pop10        ///
             (mean) sh_rural     = rural,       ///
        by(zipcode)

    replace n_places = 0 if missing(n_places)

    merge 1:1 zipcode using ../temp/share_rural.dta, ///
        assert(1 3) nogen
end

program assign_geography
    syntax, instub(str) geo(str) [pop]

    preserve
        use `instub'/census_block_master.dta if !missing(zipcode), clear

        gcollapse (sum) num_houses   = num_house10  ///
                        population   = pop10,       ///
            by(zipcode `geo')

        if "`pop'"=="" {
            gsort zipcode -num_houses
        }
        else {
            gsort zipcode -population
        }

        bys zipcode: keep if _n == 1

        tempfile data_geo
        save    `data_geo', replace
    restore

    merge 1:1 zipcode using `data_geo', assert(3) nogen
end


main
