program assign_geography
    syntax, instub(str) master_geo(str) geo_to_assign(str) [pop]

    preserve
        use `instub'/census_block_master.dta if !missing(`master_geo'), clear

        gcollapse (sum) num_houses   = num_house10  ///
                        population   = pop10,       ///
            by(`master_geo' `geo_to_assign')

        if "`pop'"=="" {
            gsort `master_geo' -num_houses
        }
        else {
            gsort `master_geo' -population
        }

        bys `master_geo': keep if _n == 1

        tempfile data_geo
        save    `data_geo', replace
    restore

    merge 1:1 `master_geo' using `data_geo', assert(3) nogen
end
