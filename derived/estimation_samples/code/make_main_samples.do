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
    local rentvar_stubs     "SFCC 1BR 2BR 3BR 4BR 5BR CC MFdxtx Mfr5Plus SF Studio"

    local start_year_month  "2010m1"
    local end_year_month    "2019m12"
    local target_year_month "2015m1"
    #delimit ;
    local target_vars  "sh_hhlds_renteroccup_cens2010
                        sh_workers_under1250_2013     sh_residents_under1250_2013
                        sh_workers_underHS_2013       sh_residents_underHS_2013";
    #delimit cr

    * Zipcode-months
    create_unbalanced_panel, instub(`in_zip_mth')                       ///
        geo(zipcode) rent_var(`rent_var') stubs(`rentvar_stubs')        ///
        start_ym(`start_year_month') end_ym(`end_year_month')

    gen_vars, rent_var(`rent_var') stubs(`rentvar_stubs') geo(zipcode)

    foreach stub of local rentvar_stubs {

        gen_date_of_entry, rent_var(`rent_var') stub(`stub')

        flag_samples, instub(`in_zip_mth') geo(zipcode) geo_name(zipcode) ///
            rent_var(`rent_var') stub(`stub') target_ym(`target_year_month')
    }

    compute_weights, instub(`in_zipcode') target_vars(`target_vars')
    merge 1:1 zipcode year_month using "../temp/weights.dta", ///
       nogen assert(2 3) keep(3)

    save_data "`outstub'/zipcode_months.dta", key(zipcode year_month) ///
        replace log(`logfile')
    export delimited "`outstub'/zipcode_months.csv", replace

    * County-months
    create_unbalanced_panel, instub(`in_cty_mth')                     ///
        geo(county) rent_var(`rent_var')                             ///
        start_ym(`start_year_month') end_ym(`end_year_month')

    gen_vars, rent_var(`rent_var') geo(county)

    flag_samples, instub(`in_cty_mth') geo(county) geo_name(countyfips) ///
        rent_var(`rent_var') stub(SFCC) target_ym(`target_year_month')

    save_data "`outstub'/county_months.dta", key(countyfips year_month) ///
        replace log(`logfile')
    export delimited "`outstub'/county_months.csv", replace
end

program create_unbalanced_panel
    syntax, instub(str) geo(str) rent_var(str) [stubs(str)]      ///
            start_ym(str) end_ym(str)
       
    use "`instub'/`geo'_month_panel.dta" ///
        if inrange(year_month, `=tm(`start_ym')', `=tm(`end_ym')'), clear
    
    if "`geo'"=="county" {
        keep if !missing(`rent_var'_SFCC)
    }
    else {
        local i = 1
        foreach stub of local stubs {
            if `i' == 1 {
                local if_statement "if !missing(`rent_var'_`stub')"
            }
            local if_statement "`if_statement' | !missing(`rent_var'_`stub')"

            local i = `i' + 1
        }

        keep `if_statement'
    }

    drop_vars
    destring_geographies

    xtset `geo'_num year_month
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
    
    gen     fullbal_sample_`stub' = baseline_sample_`stub'
    replace fullbal_sample_`stub' = 0 if year_month <= `=tm(`target_ym')'

    gen unbalanced_sample_`stub' = !missing(`rent_var'_`stub')
end

program compute_weights
    syntax, instub(str) target_vars(str) [thresh(real 0.2) stub(str)]
    
    if "`stub'"=="" {
        local stub "SFCC"
    }

    preserve
        merge m:1 zipcode using "`instub'/zipcode_cross.dta", ///
            assert(2 3) keep(2 3) keepusing(`target_vars' urban_cbsa)

        foreach var of local target_vars {
            qui sum `var' if urban_cbsa == 1
            local var_mean = r(mean)
            local target_means "`target_means' `var_mean'"
        }
                
        keep if _merge == 3
        
        ebalance `target_vars' if unbalanced_sample_`stub', manualtargets(`target_means')
        rename _webal weights_unbal
        
        ebalance `target_vars' if baseline_sample_`stub', manualtargets(`target_means')
        rename _webal weights_baseline
        
        ebalance `target_vars' if fullbal_sample_`stub', manualtargets(`target_means')
        rename _webal weights_fullbal
        
        keep zipcode year_month weights_unbal weights_baseline weights_fullbal
        save "../temp/weights.dta", replace
    restore
end

program drop_vars
    foreach var in pctlistings_pricedown_SFCC SalesPrevForeclosed_Share ///
                   zhvi_2BR zhvi_SFCC zhvi_C zhvi_SF zri_SFCCMF zri_MF {
        cap drop `var'
    }

    cap drop medlistingprice*
    cap drop medrentprice_*
    cap drop medDailyli*
end

program destring_geographies

    cap destring statefips,  gen(statefips_num)
    cap destring cbsa,       gen(cbsa_num)
    cap destring place_code, gen(place_code_num)
    cap destring countyfips, gen(county_num)
    cap destring zipcode,    gen(zipcode_num)
end


main
