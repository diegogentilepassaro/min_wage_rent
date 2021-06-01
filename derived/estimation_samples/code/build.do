set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
    local in_derived_large "../../../drive/derived_large"
    local outstub          "../../../drive/derived_large/estimation_samples"
    local logfile          "../output/data_file_manifest.log"
	
	local start_year_month "2010m1"
	local end_year_month "2019m12"
	local target_year_month "2015m1"
	local target_vars "renthouse_share2010 black_share2010 med_hhinc20105 college_share20105"
    local targets ".347 .124 62774 .386"

* Baseline zipcode-month
    use "`in_derived_large'/zipcode_month/zipcode_month_panel.dta", clear
	keep if !missing(medrentpricepsqft_SFCC)
    gcollapse (min) min_year_month = year_month, by(zipcode)
	keep if min_year_month <= `=tm(`target_year_month')'
	save_data "../temp/baseline_zipcodes.dta", key(zipcode) ///
	    replace log(none)
	
	use "`in_derived_large'/zipcode_month/zipcode_month_panel.dta", clear
	merge m:1 zipcode using "`in_derived_large'/zipcode/zipcode_cross.dta", ///
	    nogen assert(1 3) keep(3)
    merge m:1 zipcode using "../temp/baseline_zipcodes.dta", nogen ///
	    assert(1 3) keep(3)
	keep if inrange(year_month, `=tm(`start_year_month')', `=tm(`end_year_month')')
    add_weights, target_vars(`target_vars') targets(`targets') ///
	    target_year_month(`target_year_month')
	save_data "`outstub'/baseline_zipcode_months.dta", key(zipcode year_month) ///
	    replace log(`logfile')
	
* Full data zipcode-month
	use "`in_derived_large'/zipcode_month/zipcode_month_panel.dta", clear
	merge m:1 zipcode using "`in_derived_large'/zipcode/zipcode_cross.dta", ///
	    nogen assert(1 3) keep(3)
	keep if inrange(year_month, `=tm(`start_year_month')', `=tm(`end_year_month')')
    add_weights, target_vars(`target_vars') targets(`targets') ///
	    target_year_month(`target_year_month')
	save_data "`outstub'/all_zipcode_months.dta", key(zipcode year_month) ///
	    replace log(`logfile')
		
* Full balanced zipcode-month
	use "`outstub'/baseline_zipcode_months.dta", clear
	drop wgt_cbsa100
	merge m:1 zipcode using "`in_derived_large'/zipcode/zipcode_cross.dta", ///
	    nogen assert(2 3) keep(3)
	keep if year_month >= `=tm(`target_year_month')'
    add_weights, target_vars(`target_vars') targets(`targets') ///
	    target_year_month(`target_year_month')
	save_data "`outstub'/fully_balanced_zipcode_months.dta", key(zipcode year_month) ///
	    replace log(`logfile')
end

program add_weights
	syntax, target_vars(str) targets(str) target_year_month(str)
	* balancing procedure: add ,in the right order the target average values from analysis/descriptive/output/desc_stats.tex
	
	preserve
		keep if year_month == `=tm(`target_year_month')'
		ebalance `target_vars', manualtargets(`targets')
		rename _webal wgt_cbsa100
		keep zipcode wgt_cbsa100
		tempfile cbsa_weights
		save "`cbsa_weights'", replace 
	restore
	merge m:1 zipcode using `cbsa_weights', ///
	    nogen assert(1 3) keep(1 3)
end 

main
