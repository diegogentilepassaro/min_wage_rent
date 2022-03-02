program make_baseline_frame
    syntax, master_geo(str)
	
    bys `master_geo': gen  n_census_blocks = _N
    bys `master_geo': egen n_blockgroups  = nvals(blockgroup)   // Must install egenmore
    bys `master_geo': egen n_tracts        = nvals(tract) 
    bys `master_geo': egen n_places        = nvals(place_code)  
    bys `master_geo': egen n_counties      = nvals(countyfips)
    bys `master_geo': egen n_cbsa          = nvals(cbsa)
    bys `master_geo': egen n_states        = nvals(statefips)

    preserve
        gcollapse (mean) share_rural_wgt_houses = rural ///
                [aweight = num_house10], by(`master_geo')

        save ../temp/share_rural.dta, replace
    restore

    gcollapse (max) n_census_blocks n_blockgroup n_tracts   ///
                    n_places        n_counties ///
					n_cbsa n_states    ///
              (sum) num_houses   = num_house10  ///
                    population   = pop10        ///
             (mean) sh_rural     = rural,       ///
        by(`master_geo')

    replace n_blockgroup = 0 if missing(n_blockgroup)
    replace n_tracts = 0 if missing(n_tracts)
    replace n_places = 0 if missing(n_places)
    replace n_counties = 0 if missing(n_counties)
    replace n_cbsa = 0 if missing(n_cbsa)
    replace n_states = 0 if missing(n_states)

    merge 1:1 `master_geo' using ../temp/share_rural.dta, ///
        assert(1 3) nogen
end
