clear all
set more off
set maxvar 32000

program main
    local in_zipcode    "../../../drive/derived_large/zipcode"
    local instub_irs       "../../../drive/base_large/irs_soi"
    local instub_safmr     "../../../base/safmr/output"
	
	clean_irs, instub(`instub_irs')
    save_data "../temp/irs_2014_clean.dta",  log(none)      ///
        key(zipcode) replace
    
    clean_safmr, instub(`instub_safmr')
    save_data "../temp/safmr_2014_clean.dta",     log(none)      ///
        key(zipcode) replace 
		
	use zipcode population_cens2010 urb_pop_cens2010 sh_hhlds_renteroccup_cens2010 ///
	    n_hhlds_cens2010 n_hhlds_urban_cens2010 population_acs2014 ///
		using "`in_zipcode'/zipcode_cross.dta", clear
    merge 1:1 zipcode using "../temp/irs_2014_clean.dta", ///
	    nogen keep(1 3)
    merge 1:1 zipcode using "../temp/safmr_2014_clean.dta", ///
	    nogen keep(1 3)
	gen alpha_alt = sh_hhlds_renteroccup_cens2010*safmr2br/wage_per_wage_hhld
	gen alpha = safmr2br/wage_per_wage_hhld
	
	keep zipcode alpha*
	save_data "../output/alpha_by_zip.dta", key(zipcode) replace
end

program clean_irs 
    syntax, instub(str)
    
    use "`instub'/irs_zip.dta", clear

    drop if inlist(zipcode, "0", "00000", "99999")    
    keep if year == 2014
    
    keep zipcode statefips share_wage_hhlds share_bussiness_hhlds /// 
         share_farmer_hhlds agi_per_hhld wage_per_wage_hhld       ///
         wage_per_hhld bussines_rev_per_owner
end

program clean_safmr 
    syntax, instub(str)
    
    use "`instub'/safmr_2012_2016_by_zipcode_county_cbsa.dta", clear
    keep zipcode countyfips cbsa year safmr1br safmr2br safmr3br
    keep if year == 2014
    drop year
	collapse (mean) safmr*, by(zipcode)
end



main
