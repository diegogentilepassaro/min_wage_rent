clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
    local instub_acs      "../../../base/acs/output"
    local instub_irs      "../../../drive/base_large/irs_soi"
    local instub_safmr    "../../../base/safmr/output"
    local instub_est_samp "../../../drive/derived_large/estimation_samples"	

    clean_acs, instub(`instub_acs')
	save_data "../temp/acs_2011_clean.dta", ///
	    key(zcta) log(none) replace
	
	clean_irs, instub(`instub_irs')
	save_data "../temp/irs_2010_clean.dta", ///
	    key(zipcode) log(none) replace
	
	clean_safmr, instub(`instub_safmr')
	save_data "../temp/safmr_clean.dta", ///
	    key(zipcode countyfips cbsa10 year) log(none) replace
	keep if year == 2012
	drop year
	save_data "../temp/safmr_2012_clean.dta", ///
	    key(zipcode countyfips cbsa10) log(none) replace
	
	build_zip_lvl_samples, instub(`instub_est_samp')
	foreach data in "all" "all_urban" "all_zillow_rents" "baseline_zillow_rents" {
	    use "../temp/`data'_zipcodes.dta", clear
		merge 1:1 zipcode using "../temp/actual_mw_feb2010.dta", ///
		    nogen keep(1 3)
		merge 1:1 zipcode using "../temp/rents_jan2015.dta", ///
		    nogen keep(1 3)
		merge 1:1 zipcode using "../temp/irs_2010_clean.dta", ///
		    nogen keep(1 3)
		merge m:1 zcta using "../temp/acs_2011_clean.dta", ///
		    nogen keep(1 3)
		merge 1:1 zipcode countyfips cbsa10 ///
		    using "../temp/safmr_2012_clean.dta", nogen keep(1 3)
		drop zcta countyfips cbsa10 statefips
		save_data "../output/`data'_zipcode_lvl_data.dta", ///
		    key(zipcode) replace
        export delimited "../output/`data'_zipcode_lvl_data.csv", replace
	}
	
	use zipcode countyfips cbsa10 statefips year_month year month ///
	    actual_mw exp_ln_mw_17 ln_mw ///
	    medrentpricepsqft_SFCC medrentprice_SFCC ///
		ln_rents medrentpricepsqft_2BR medrentprice_2BR ///
		ln_emp_bizserv ln_emp_info ln_emp_fin ///
		ln_estcount_bizserv ln_estcount_info ln_estcount_fin ///
		ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ///
	    using "`instub_est_samp'/baseline_zipcode_months.dta", clear
	merge m:1 zipcode using "../temp/baseline_zillow_rents_zipcodes.dta", ///
	    nogen keep(3)
	merge m:1 zipcode countyfips cbsa10 year using "../temp/safmr_clean.dta", ///
	    nogen keep(1 3)
    save_data "../output/baseline_zillow_rents_zipcode_months.dta", ///
		    key(zipcode year_month) replace
	export delimited "../output/baseline_zillow_rents_zipcode_months.csv", replace
end

program clean_acs
	syntax, instub(str)
	
	import delimited "`instub'/acs_2011.csv", clear stringcols(1)
	
	gen share_black_pop     = black/population
	gen share_hispanic_pop  = hispanic/population
    gen share_renter_hhlds    = renter_occupied/total_households
	gen hhld_size             = population/total_households
    keep zcta population total_households hhld_size share_renter_hhlds ///
        share_black_pop share_hispanic_pop total_earnings_hhld
end

program clean_irs 
    syntax, instub(str)
	
	use "`instub'/irs_zip.dta", clear
	drop if zipcode == "0"
	drop if zipcode == "00000"
	
	keep if year == 2010
	
    keep zipcode statefips share_wage_hhlds share_bussiness_hhlds /// 
	    share_farmer_hhlds agi_per_hhld wage_per_wage_hhld ///
		wage_per_hhld bussines_rev_per_owner
end

program clean_safmr 
    syntax, instub(str)
	
	use "`instub'/safmr_2012_2016_by_zipcode_county_cbsa10.dta", clear
	keep zipcode countyfips cbsa10 year safmr1br safmr2br safmr3br	
end

program build_zip_lvl_samples
    syntax, instub(str)
	
	use zipcode zcta countyfips cbsa10 statefips year_month year ///
	    month medrentprice_SFCC medrentpricepsqft_SFCC ///
		medrentprice_2BR medrentpricepsqft_2BR rural actual_mw ///
		using "`instub'/all_zipcode_months.dta", clear
		
	preserve
	    keep if year == 2015 & month == 1
		keep zipcode medrentprice_SFCC medrentpricepsqft_SFCC ///
		medrentprice_2BR medrentpricepsqft_2BR
		save "../temp/rents_jan2015.dta", replace
	restore
		
	preserve
	    keep if year == 2010 & month == 2
		keep zipcode actual_mw
		save "../temp/actual_mw_feb2010.dta", replace
	restore
	
	preserve
	    keep zipcode zcta countyfips cbsa10 statefips rural
		duplicates drop zipcode, force
		save "../temp/all_zipcodes.dta", replace
	restore 
	
	preserve
	    keep if rural == 0
	    keep zipcode zcta countyfips cbsa10 statefips rural
		duplicates drop zipcode, force
		save "../temp/all_urban_zipcodes.dta", replace
	restore 
	
	preserve
	    keep if !missing(medrentpricepsqft_SFCC)
	    keep zipcode zcta countyfips cbsa10 statefips rural
		duplicates drop zipcode, force
		save "../temp/all_zillow_rents_zipcodes.dta", replace
	restore 
	
    use zipcode zcta countyfips cbsa10 statefips year_month year ///
	    month medrentpricepsqft_SFCC rural actual_mw ///
		using "`instub'/baseline_zipcode_months.dta", clear
		
	preserve
	    keep if !missing(medrentpricepsqft_SFCC)
	    keep zipcode zcta countyfips cbsa10 statefips rural
		duplicates drop zipcode, force
		save "../temp/baseline_zillow_rents_zipcodes.dta", replace
	restore 
end

main
