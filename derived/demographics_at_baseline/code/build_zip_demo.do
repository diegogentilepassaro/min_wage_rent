set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_zip         "../../../drive/base_large/zipcode_master"
    local in_tract       "../../../drive/base_large/tract_master"
    local in_block       "../../../drive/base_large/census_block_master"
    local in_demo        "../../../drive/derived_large/demographics_at_baseline"
    local outstub        "../../../drive/derived_large/demographics_at_baseline"
    local logfile        "../output/data_file_manifest.log"

    assign_block_demo_to_zip, in_block(`in_block') in_demo(`in_demo')
	save "../temp/census_block_to_zip_demo.dta", replace
	
    assign_tract_demo_to_zip, in_tract(`in_tract') in_demo(`in_demo')
	save "../temp/tract_to_zip_demo.dta", replace

	use "`in_zip'/zipcode_master.dta", clear
	merge 1:1 zipcode using "../temp/census_block_to_zip_demo.dta", ///
	    nogen assert(3)
	merge 1:1 zipcode using "../temp/tract_to_zip_demo.dta", ///
	    nogen assert(1 3)
	save_data "`outstub'/zip_demo_at_baseline.dta", ///
	    key(zipcode) replace log(`logfile')
end

program assign_block_demo_to_zip
    syntax, in_block(str) in_demo(str)
	
    use "`in_block'/census_block_master.dta", clear
	merge 1:1 block using "`in_demo'/block_demo_baseline.dta", nogen assert(3) ///
	    keepusing(n_male n_white n_black urban_population n_hhlds_renter_occupied)
	keep if !missing(zipcode)
	gcollapse (sum) n_male_census2010 = n_male n_white_census2010 = n_white ///
	    n_black_census_2010 = n_black urb_pop_census_2010 = urban_population ///
		n_hhlds_renter_occ_census_2010 = n_hhlds_renter_occupied, ///
	    by(zipcode)
end

program assign_tract_demo_to_zip
    syntax, in_tract(str) in_demo(str)
	
	use tract num_houses zipcode ///
	    using "`in_tract'/tract_master.dta", clear	
    merge 1:1 tract using "`in_demo'/tract_demo_baseline.dta", nogen assert(3) ///
	    keepusing(population med_hhld_inc n_workers n_mw_workers_statutory ///
		n_mw_workers_state n_mw_workers_fed)
	keep if !missing(zipcode)
	preserve
        gcollapse (mean) med_hhld_inc_acs2011 = med_hhld_inc [aw = num_houses], ///
		    by(zipcode)
		save "../temp/tract_to_zip_med_hhld_inc.dta", replace
	restore 
	gcollapse (sum) population_acs2011 = population n_workers_acs2011 = n_workers ///
	    n_mw_wkrs_statutory = n_mw_workers_statutory ///
	    n_mw_wkrs_state = n_mw_workers_state ///
	    n_mw_wkrs_fed = n_mw_workers_fed, by(zipcode)
	merge 1:1 zipcode using "../temp/tract_to_zip_med_hhld_inc.dta", nogen ///
	    assert(1 3)
	foreach stub in statutory state fed {
	    gen share_mw_wkrs_`stub'          = n_mw_wkrs_`stub'/n_workers_acs2011
	    gen share_mw_wkrs_over_pop_`stub' = n_mw_wkrs_`stub'/population_acs2011	
	}
end

main
