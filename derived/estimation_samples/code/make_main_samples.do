set more off
clear all
version 15
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_zip_mth   "../../../drive/derived_large/zipcode_month"
    local in_cty_mth   "../../../drive/derived_large/county_month"
    local in_zipcode   "../../../drive/derived_large/zipcode"
    local outstub      "../../../drive/derived_large/estimation_samples"
    local logfile      "../output/data_file_manifest.log"

    local rent_var          "medrentpricepsqft"
    local rentvar_stubs     "SFCC SF CC Studio 1BR 2BR 3BR 4BR 5BR MFdxtx Mfr5Plus"

    local start_year_month  "2010m1"
    local end_year_month    "2019m12"
    local target_year_month "2015m1"
    #delimit ;
    local target_vars  "med_hhld_inc_acs2011 sh_hhlds_renteroccup_cens2010 
	                    sh_male_cens2010 sh_black_cens2010";
    #delimit cr

    * Zipcode-months
    create_unbalanced_panel, instub(`in_zip_mth')                           ///
        geo(zipcode) rent_var(`rent_var') stubs(`rentvar_stubs')            ///
        start_ym(`start_year_month') end_ym(`end_year_month')

    gen_vars, rent_var(`rent_var') stubs(`rentvar_stubs') geo(zipcode)

    foreach stub of local rentvar_stubs {

        gen_date_of_entry, rent_var(`rent_var') stub(`stub')

        flag_samples, instub(`in_zip_mth') geo(zipcode) geo_name(zipcode)    ///
            rent_var(`rent_var') stub(`stub') target_ym(`target_year_month')
    }

    compute_weights, instub(`in_zipcode') target_vars(`target_vars')
    merge 1:1 zipcode year_month using "../temp/weights.dta",                ///
       nogen assert(2 3) keep(3)

    save_data "`outstub'/zipcode_months.dta", key(zipcode year_month)        ///
        replace log(`logfile')
    export delimited "`outstub'/zipcode_months.csv", replace

    create_monthly_listings_panel, instub(`in_zip_mth')                      ///
        geo(zipcode) start_ym(`start_year_month') end_ym(`end_year_month')
    
    save_data "`outstub'/zipcode_months_listings.dta", key(zipcode year_month) ///
        replace log(`logfile')
    
    * County-months
    create_unbalanced_panel, instub(`in_cty_mth')                            ///
        geo(county) rent_var(`rent_var')                                     ///
        start_ym(`start_year_month') end_ym(`end_year_month')

    gen_vars, rent_var(`rent_var') geo(county)

    flag_samples, instub(`in_cty_mth') geo(county) geo_name(countyfips)      ///
        rent_var(`rent_var') stub(SFCC) target_ym(`target_year_month')

    save_data "`outstub'/county_months.dta", key(countyfips year_month)      ///
        replace log(`logfile')
    export delimited "`outstub'/county_months.csv", replace
end

program create_unbalanced_panel
    syntax, instub(str) geo(str) rent_var(str) [stubs(str)]      ///
            start_ym(str) end_ym(str) [w(int 6)]
       
    use "`instub'/`geo'_month_panel.dta" ///
        if inrange(year_month, `=tm(`start_ym')', `=tm(`end_ym')'), clear

    destring_geographies
    
    if "`geo'"=="county" {
        keep if !missing(`rent_var'_SFCC)

        xtset county_num year_month
    }
    else {
        xtset zipcode_num year_month

        local j = 0
        foreach stub of local stubs {
            if `j'==0 {
                local if_statement "if !missing(`rent_var'_`stub')"
            }
            else {
                local if_statement "`if_statement' | !missing(`rent_var'_`stub')"
            }
            
            forvalues i = 1(1)`w' {
                local if_statement "`if_statement' | !missing(F`i'.`rent_var'_`stub')"
            }
            local j = `j' + 1
        }

        keep `if_statement'
    }

    drop_vars
end

program gen_vars
    syntax, rent_var(str) [stubs(str)] geo(str)

    gen ln_rents = log(`rent_var'_SFCC)

    if "`geo'" == "zipcode"{
        foreach stub of local stubs {
            if "`stub'"!="SFCC" {
                gen ln_rents_`stub' = log(medrentpricepsqft_`stub')
            }
        }
    }

    foreach ctrl_type in emp estcount avgwwage {
        gen ln_`ctrl_type'_bizserv = log(`ctrl_type'_bizserv)
        gen ln_`ctrl_type'_info    = log(`ctrl_type'_info)
        gen ln_`ctrl_type'_fin     = log(`ctrl_type'_fin)
        drop `ctrl_type'_*
    }
end

program gen_date_of_entry
    syntax, rent_var(str) stub(str)

    preserve
        keep if !missing(`rent_var'_`stub')
        collapse (min) ym_entry_to_zillow_`stub' = year_month, by(zipcode)

        gen     yr_entry_to_zillow_`stub'  = year(dofm(ym_entry_to_zillow_`stub'))
        gen     qtr_entry_to_zillow_`stub' = quarter(dofm(ym_entry_to_zillow_`stub'))
        replace qtr_entry_to_zillow_`stub' = yq(yr_entry_to_zillow_`stub', qtr_entry_to_zillow_`stub')

        drop ym_entry_to_zillow_`stub'
        save "../temp/ym_entry_to_zillow_`stub'.dta", replace
    restore
    merge m:1 zipcode using "../temp/ym_entry_to_zillow_`stub'.dta", ///
        nogen assert(1 3)
end

program flag_samples
    syntax, instub(str) geo(str) geo_name(str) ///
        rent_var(str) stub(str) target_ym(str)

    preserve
        clear
        use year_month `geo_name' `rent_var'_`stub'    ///
            using "`instub'/`geo'_month_panel.dta"     ///
            if !missing(`rent_var'_`stub')
        
        gcollapse (min) min_year_month = year_month, by(`geo_name')
        keep if min_year_month <= `=tm(`target_ym')'
        
        keep `geo_name'
        gen baseline_sample_`stub' = 1
        
        save_data "../temp/baseline_`geo'.dta", key(`geo_name') ///
            replace log(none)
    restore
    
    merge m:1 `geo_name' using "../temp/baseline_`geo'.dta", ///
        nogen assert(1 3) keep(1 3)
    
    replace baseline_sample_`stub' = 0 if missing(baseline_sample_`stub')
    replace baseline_sample_`stub' = . if missing(`rent_var'_`stub')

    gen     fullbal_sample_`stub' = baseline_sample_`stub'
    replace fullbal_sample_`stub' = 0 if year_month <= `=tm(`target_ym')' & !missing(`rent_var'_`stub')

    gen     unbalanced_sample_`stub' = 1
    replace unbalanced_sample_`stub' = . if missing(`rent_var'_`stub')
end

program compute_weights
    syntax, instub(str) target_vars(str) [thresh(real 0.2) stub(str)]
    
    if "`stub'"=="" {
        local stub "SFCC"
    }
    
    preserve
        use zipcode `target_vars' urban_cbsa using "`instub'/zipcode_cross.dta", clear

        keep if urban_cbsa

        foreach var of local target_vars {
            qui sum `var'
            local var_mean = r(mean)
            local target_means "`target_means' `var_mean'"
        }
    restore
    
    preserve
        merge m:1 zipcode using "`instub'/zipcode_cross.dta", ///
                assert(2 3) keep(3) keepusing(`target_vars' urban_cbsa)
                
        ebalance `target_vars' if unbalanced_sample_`stub', manualtargets(`target_means')
        rename _webal weights_unbalanced
        
        ebalance `target_vars' if baseline_sample_`stub', manualtargets(`target_means')
        rename _webal weights_baseline
        
        ebalance `target_vars' if fullbal_sample_`stub', manualtargets(`target_means')
        rename _webal weights_fullbal
        
        keep zipcode year_month weights_unbalanced weights_baseline weights_fullbal
        save "../temp/weights.dta", replace
    restore
end

program drop_vars
    foreach var in pctlistings_pricedown_SFCC SalesPrevForeclosed_Share ///
                   zhvi_2BR zhvi_SFCC zhvi_C zhvi_SF zri_SFCCMF zri_MF Sale_Counts {
        cap drop `var'
    }

    cap drop Monthly* NewMonthly*
    cap drop medlistingprice*
    cap drop medrentprice_*
    cap drop medDailyli*
end

program create_monthly_listings_panel
    syntax, instub(str) geo(str) start_ym(str) end_ym(str) [w(int 6)]

    use "`instub'/zipcode_month_panel.dta" ///
        if inrange(year_month, `=tm(`start_ym')', `=tm(`end_ym')'), clear

    local SFCC_vars Monthlylistings_NSA_SFCC medlistingprice_SFCC medlistingpricepsqft_SFCC pctlistings_pricedown_SFCC
    keep zipcode statefips cbsa place_code countyfips year_month ///
        `SFCC_vars' mw_res mw_wkp_tot_timevary mw_wkp_*_17
    
    destring_geographies
    xtset zipcode_num year_month

    local if_statement "if !missing(Monthlylistings_NSA_SFCC)"
    foreach var of local SFCC_vars {
        forvalues i = 1(1)`w' {
            local if_statement "`if_statement' | !missing(F`i'.`var')"
        }
    }
    keep `if_statement'

	gen ln_monthly_listings = log(Monthlylistings_NSA_SFCC)
	gen ln_prices_psqft     = log(medlistingpricepsqft_SFCC)

    local target_ym = "2013m1"
    foreach var in Monthlylistings_NSA_SFCC medlistingpricepsqft_SFCC {
        preserve
            keep if !missing(`var')
            
            gcollapse (min) min_year_month = year_month, by(zipcode)
            keep if min_year_month <= `=tm(`target_ym')'
            
            keep zipcode

            if "`var'"=="Monthlylistings_NSA_SFCC"  local stub "n_listings"
            if "`var'"=="medlistingpricepsqft_SFCC" local stub "price_psqft"
            gen indata_`stub' = 1
            
            save_data "../temp/`var'.dta", key(zipcode) replace log(none)
        restore

        merge m:1 zipcode using "../temp/`var'.dta", nogen assert(1 3) keep(1 3)
        replace indata_`stub' = 0 if missing(indata_`stub')
        replace indata_`stub' = . if missing(`var')
    }
    keep if year_month >= `=tm(`target_ym')'
end

program destring_geographies

    cap destring statefips,  gen(statefips_num)
    cap destring cbsa,       gen(cbsa_num)
    cap destring place_code, gen(place_code_num)
    cap destring countyfips, gen(county_num)
    cap destring zipcode,    gen(zipcode_num)
end


main
