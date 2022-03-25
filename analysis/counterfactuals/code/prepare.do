clear all
set more off
set maxvar 32000

program main
	local in_zip_mth  "../../../drive/derived_large/zipcode_month"
    local in_est      "../../../drive/derived_large/estimation_samples"
    local in_cf_mw    "../../../drive/derived_large/min_wage_measures"
	local in_zip_year "../../../drive/derived_large/zipcode_year"
    
    local cluster = "statefips"
    local absorb  = "year_month"
    
    local mw_wkp_var "mw_wkp_tot_17"

    process_counterfactual_data, in_cf_mw(`in_cf_mw') in_zip_mth(`in_zip_mth')
    
    use zipcode statefips year_month year month ///
        mw_res `mw_wkp_var' medrentpricepsqft_SFCC ///
        using "`in_zip_mth'/zipcode_month_panel.dta", clear
	drop if year == 2020
	gen ln_rents = log(medrentpricepsqft_SFCC)
	destring zipcode, gen(zipcode_num)
    add_baseline_zipcodes, instub(`in_est')
    build_rents_for_cf, mw_wkp_var(`mw_wkp_var')
        
    keep zipcode year month d_mw_res d_`mw_wkp_var' ///
        ln_rents_pre
	order zipcode year month d_mw_res d_`mw_wkp_var' ///
        ln_rents_pre
    save_data "../output/d_ln_rents_cf_predictions.dta", ///
        key(zipcode year month) replace
		
    use "`in_zip_year'/zipcode_year.dta", clear
	build_wagebill_for_cf, mw_wkp_var(`mw_wkp_var')
	
	keep zipcode year ln_wagebill_pre n_hhlds_pre
	order zipcode year ln_wagebill_pre n_hhlds_pre
	save_data "../output/ln_wagebill_cf_predictions.dta", ///
	    key(zipcode year) replace
end

program process_counterfactual_data
    syntax, in_cf_mw(str) in_zip_mth(str)
    
    use zipcode year month counterfactual mw_wkp_tot using ///
        "`in_cf_mw'/zipcode_wkp_mw_cfs.dta", clear
    
    bysort zipcode counterfactual (year month): ///
        gen d_mw_wkp_cf = mw_wkp_tot[_n] - mw_wkp_tot[_n - 1]
	
    keep if (year == 2020 & month == 1)
    rename mw_wkp_tot mw_wkp_tot_cf
    gen fed_mw_cf = 7.25*1.1 if counterfactual == "fed_10pc"
    replace fed_mw_cf = 15 if counterfactual == "fed_15usd"
    replace fed_mw_cf = 9 if counterfactual == "fed_9usd"
    save "../temp/counterfactual.dta", replace
    
    use "`in_zip_mth'/zipcode_month_panel.dta", clear
    keep if (year == 2019 & month == 12)
    keep zipcode statutory_mw
    expand 3
    bysort zipcode: gen counterfactual = "fed_10pc" if _n == 1
    bysort zipcode: replace counterfactual = "fed_15usd" if _n == 2
    bysort zipcode: replace counterfactual = "fed_9usd" if _n == 3
    merge 1:1 zipcode counterfactual using "../temp/counterfactual.dta", ///
        nogen keep(3)
    egen statutory_mw_cf = rowmax(statutory_mw fed_mw_cf)
    gen d_mw_res_cf = log(statutory_mw_cf) - log(statutory_mw)
    drop fed_mw_cf statutory_mw_cf mw_wkp_tot_cf
    
    foreach stub in "10pc" "9usd" "15usd" {
        preserve
            keep if counterfactual == "fed_`stub'"
            drop counterfactual
            save "../temp/counterfactual_fed_`stub'.dta", replace
        restore
    }
end

program add_baseline_zipcodes
    syntax, instub(str)

    preserve
        use `instub'/zipcode_months.dta, clear

        keep if baseline_sample == 1
        bys  zipcode: keep if _n == 1
        keep zipcode baseline_sample

        tempfile zipcode_years_baseline
        save    `zipcode_years_baseline'
    restore

    merge m:1 zipcode using `zipcode_years_baseline', keep(1 3) nogen

    replace baseline_sample = 0 if baseline_sample != 1
end

program build_rents_for_cf
    syntax, mw_wkp_var(str)

    local mw_wkp_var "mw_wkp_tot_17"

    bysort zipcode (year_month): gen d_ln_rents = ln_rents[_n] - ln_rents[_n-1]
    bysort zipcode (year_month): gen d_mw_res = mw_res[_n] - mw_res[_n-1]
    bysort zipcode (year_month): gen d_`mw_wkp_var' = `mw_wkp_var'[_n] - `mw_wkp_var'[_n-1]
	
    append using "../temp/counterfactual_fed_9usd.dta"
    
    replace d_mw_res = d_mw_res_cf if (year == 2020 & month == 1)
    replace d_`mw_wkp_var' = d_mw_wkp_cf if (year == 2020 & month == 1)
    
    bysort zipcode (year month): gen ln_rents_pre = ///
            ln_rents[_n-1] if (year == 2020 & month == 1)
    gen counterfactual = 0
    replace counterfactual = 1 if (year == 2020 & month == 1) 
    replace year_month = `=tm(2019m12)' if year_month == 2020

    keep if counterfactual == 1
end

program build_wagebill_for_cf
    syntax, mw_wkp_var(str)

    keep if year == 2019
    append using "../temp/counterfactual_fed_9usd.dta"
	gen counterfactual = 0
	replace counterfactual = 1 if year == 2020
	keep zipcode year counterfactual ln_wagebill ln_n_hhdls
	bysort zipcode (year): carryforward ln_wagebill, replace
	gen n_hhlds = exp(ln_n_hhdls)
	bysort zipcode (year): carryforward n_hhlds, replace
	keep if counterfactual == 1
	rename (ln_wagebill n_hhlds) (ln_wagebill_pre n_hhlds_pre)
end

main
