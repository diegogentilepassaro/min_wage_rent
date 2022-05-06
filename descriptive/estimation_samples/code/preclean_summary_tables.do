clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000

program main
    local instub_zipcode   "../../../drive/derived_large/zipcode"
    local instub_irs       "../../../drive/base_large/irs_soi"
    local instub_safmr     "../../../base/safmr/output"
    local instub_zip_mth   "../../../drive/derived_large/zipcode_month"   
    local instub_est_samp  "../../../drive/derived_large/estimation_samples"    

    * Cross-sections    
    clean_irs, instub(`instub_irs')
    save_data "../temp/irs_2014_clean.dta",  log(none)      ///
        key(zipcode) replace
    
    clean_safmr, instub(`instub_safmr')
    save_data "../temp/safmr_clean.dta",     log(none)      ///
        key(zipcode countyfips cbsa year) replace
    
    keep if year == 2014
    drop year
    save_data "../temp/safmr_2014_clean.dta", log(none)     ///
        key(zipcode countyfips cbsa)  replace
    
    use zipcode countyfips cbsa statefips year_month year  ///
        month medrentprice_SFCC medrentprice_2BR           ///
        medrentpricepsqft_* statutory_mw                   ///
        using "`instub_zip_mth'/zipcode_month_panel.dta", clear
    
    merge m:1 zipcode using "`instub_zipcode'/zipcode_cross.dta", nogen ///
        assert(2 3)
    merge 1:1 zipcode year_month using "`instub_est_samp'/zipcode_months.dta", ///
        nogen assert(1 3) keepusing(fullbal_sample_SFCC)

    build_zip_lvl_samples, instub(`instub_est_samp')
    foreach data in "all"              "all_urban"          ///
                    "all_zillow_rents" "baseline" {
        
        use "../temp/`data'_zipcodes.dta", clear
        merge 1:1 zipcode using "`instub_zipcode'/zipcode_cross.dta", nogen ///
            assert(2 3) keep(3)
        merge 1:1 zipcode using "../temp/statutory_mw_dec2014.dta",  ///
            nogen keep(1 3)
        merge 1:1 zipcode using "../temp/statutory_mw_dec2019.dta",  ///
            nogen keep(1 3)
        merge 1:1 zipcode using "../temp/rents_dec2014.dta",      ///
            nogen keep(1 3)
        merge 1:1 zipcode using "../temp/irs_2014_clean.dta",     ///
            nogen keep(1 3)
        merge 1:1 zipcode countyfips cbsa                       ///
            using "../temp/safmr_2014_clean.dta", nogen keep(1 3)
        
        save_data "../output/`data'_zipcode_lvl_data.dta",        ///
            key(zipcode) replace
        export delimited "../output/`data'_zipcode_lvl_data.csv", replace
    }
    
    * Panel
    use zipcode countyfips cbsa statefips year_month year month    ///
        statutory_mw mw_wkp_tot_17 mw_res  *_SFCC  ln_rent*        ///
        mw_wkp_earn_under1250_17 mw_wkp_age_under29_17             ///
        ln_emp_bizserv ln_emp_info ln_emp_fin                      ///
        ln_estcount_bizserv ln_estcount_info ln_estcount_fin       ///
        ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin fullbal_sample_SFCC ///
        using "`instub_est_samp'/zipcode_months.dta", clear
    
    keep if fullbal_sample_SFCC == 1

    merge m:1 zipcode countyfips cbsa year using "../temp/safmr_clean.dta", ///
        nogen keep(1 3)
    
    save_data "../output/baseline_zillow_rents_zipcode_months.dta", ///
            key(zipcode year_month) replace
    export delimited "../output/baseline_zillow_rents_zipcode_months.csv", replace
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
end

program build_zip_lvl_samples
    syntax, instub(str)
    
    preserve
        keep if year == 2014 & month == 12
        keep zipcode medrentprice_SFCC medrentpricepsqft_SFCC     ///
            medrentprice_2BR medrentpricepsqft_2BR
        save "../temp/rents_dec2014.dta", replace
    restore
    
    preserve
        keep if year == 2014 & month == 12
        keep zipcode statutory_mw
        rename statutory_mw statutory_mw_dec2014
        save "../temp/statutory_mw_dec2014.dta", replace
    restore
    
    preserve
        keep if year == 2019 & month == 12
        keep zipcode statutory_mw
        rename statutory_mw statutory_mw_dec2019
        save "../temp/statutory_mw_dec2019.dta", replace
    restore
    
    preserve
        keep zipcode countyfips cbsa statefips urban_cbsa urban_zip
        duplicates drop zipcode, force
        save "../temp/all_zipcodes.dta", replace
    restore 
    
    preserve
        keep if urban_cbsa == 1
        keep zipcode countyfips cbsa statefips urban_cbsa urban_zip
        duplicates drop zipcode, force
        save "../temp/all_urban_zipcodes.dta", replace
    restore 
    
    preserve
        keep if !missing(medrentpricepsqft_SFCC)
        keep zipcode countyfips cbsa statefips urban_cbsa urban_zip
        duplicates drop zipcode, force
        save "../temp/all_zillow_rents_zipcodes.dta", replace
    restore 

    preserve
        keep if fullbal_sample_SFCC == 1
        keep zipcode countyfips cbsa statefips urban_cbsa urban_zip
        duplicates drop zipcode, force
        save "../temp/baseline_zipcodes.dta", replace
    restore 
end

main
