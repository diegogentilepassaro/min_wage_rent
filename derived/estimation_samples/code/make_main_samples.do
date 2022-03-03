set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_zipcode  "../../../drive/derived_large/zipcode_month"
    local in_county   "../../../drive/derived_large/county_month"
    local outstub     "../../../drive/derived_large/estimation_samples"
    local logfile     "../output/data_file_manifest.log"
    
    local rent_var          "medrentpricepsqft_SFCC"
    local start_year_month  "2010m1"
    local end_year_month    "2019m12"
    local target_year_month "2015m1"
    local target_vars       "renthouse_share2010 black_share2010 med_hhinc20105 college_share20105"
    local targets           ".347 .124 62774 .386"

    foreach geo in zipcode { // county
        
        create_unbalanced_panel, instub(`in_`geo'')                     ///
            geo(`geo') rent_var(`rent_var')                             ///
            start_ym(`start_year_month') end_ym(`end_year_month')
        
        gen_vars, rent_var(`rent_var')
        
        flag_samples, instub(`in_`geo'') geo(`geo') rent_var(`rent_var') ///
                      target_ym(`target_year_month')
        *add_weights,  geo(`geo') target_vars(`target_vars') ///
        *              targets(`targets') target_ym(`target_year_month')
        
        save_data "`outstub'/`geo'_months.dta", key(`geo' year_month) ///
            replace log(`logfile')
        export delimited "`outstub'/`geo'_months.csv", replace
    }
end

program create_unbalanced_panel
    syntax, instub(str) geo(str) rent_var(str)        ///
            start_ym(str) end_ym(str)
       
    clear
    use "`instub'/`geo'_month_panel.dta" ///
        if !missing(`rent_var')
    
    keep if inrange(year_month, `=tm(`start_ym')', `=tm(`end_ym')')

    drop_vars
    destring_geographies

    xtset `geo'_num year_month
end

program gen_vars
    syntax, rent_var(str)

    gen ln_rents = log(`rent_var')
    
    foreach ctrl_type in emp estcount avgwwage {
        gen ln_`ctrl_type'_bizserv = log(`ctrl_type'_bizserv)
        gen ln_`ctrl_type'_info    = log(`ctrl_type'_info)
        gen ln_`ctrl_type'_fin     = log(`ctrl_type'_fin)
    }
end

program flag_samples
    syntax, instub(str) geo(str) rent_var(str) target_ym(str)

    preserve
        use year_month `geo' medrentpricepsqft_SFCC using  ///
            "`instub'/`geo'_month_panel.dta"               ///
            if !missing(`rent_var'), clear
        
        gcollapse (min) min_year_month = year_month, by(`geo')
        keep if min_year_month <= `=tm(`target_ym')'
        
        keep zipcode
        gen baseline_sample = 1
        
        save_data "../temp/baseline_`geo'.dta", key(`geo') ///
            replace log(none)
    restore
    
    merge m:1 `geo' using "../temp/baseline_`geo'.dta", ///
        nogen assert(1 3) keep(1 3)
    
    replace baseline_sample = 0 if missing(baseline_sample)
    
    gen     fullbal_sample = baseline_sample
    replace fullbal_sample = 0 if year_month <= `=tm(`target_ym')'
end

program add_weights
    syntax, geo(str) target_vars(str)               ///
            targets(str) target_ym(str)
    * balancing procedure: add ,in the right order the target 
    * average values from analysis/descriptive/output/desc_stats.tex
    
    ebalance `target_vars' if year_month == `=tm(`target_ym')', manualtargets(`targets')
        
    rename _webal weights_unbal

    preserve
        keep if baseline_sample

        ebalance `target_vars' if year_month == `=tm(`target_ym')', manualtargets(`targets')
        
        rename _webal weights_baseline
        
        keep `geo' weights_baseline

        tempfile weights_baseline
        save "`weights_baseline'", replace 
    restore
    merge m:1 `geo' using `weights_baseline', ///
        nogen assert(1 3) keep(1 3)
    
    preserve
        keep if fullbal_sample

        ebalance `target_vars' if year_month == `=tm(`target_ym')', manualtargets(`targets')
        
        rename _webal weights_fullbal
        
        keep `geo' weights_fullbal

        tempfile weights_fullbal
        save "`weights_fullbal'", replace 
    restore
    merge m:1 `geo' using `weights_fullbal', ///
        nogen assert(1 3) keep(1 3)
end

program drop_vars
    foreach var in medlistingprice_low_tier ///
        medlistingprice_top_tier medpctpricereduction_SFCC ///
        medrentprice_1BR medrentprice_4BR medrentprice_5BR ///
        medrentprice_CC medrentprice_MFdxtx medrentprice_Mfr5Plus ///
        medrentprice_SF medrentprice_Studio medrentpricepsqft_1BR ///
        medrentpricepsqft_4BR medrentpricepsqft_5BR medrentpricepsqft_CC ///
        medrentpricepsqft_MFdxtx medrentpricepsqft_Mfr5Plus ///
        medrentpricepsqft_SF medrentpricepsqft_Studio ///
        pctlistings_pricedown_SFCC SalesPrevForeclosed_Share ///
        zhvi_2BR zhvi_SFCC zhvi_C zhvi_SF zri_SFCCMF zri_MF {
        cap drop `var'
    }
end

program destring_geographies

    cap destring statefips,  gen(statefips_num)
    cap destring cbsa,       gen(cbsa_num)
    cap destring place_code, gen(place_code_num)
    cap destring county,     gen(county_num)
    cap destring countyfips, gen(county_num)
    cap destring zipcode,    gen(zipcode_num)
end


main
