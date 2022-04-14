clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local outstub "../output"

    define_controls
    local controls "`r(economic_controls)'"
    local cluster = "statefips"
    local absorb  = "year_month"

    local mw_wkp_var  "mw_wkp_tot_17"

    use "`instub'/zipcode_months.dta", clear
    xtset zipcode_num `absorb'
    
    estimate_alt_zillow_cats_dyn, mw_wkp_var(`mw_wkp_var') controls(`controls') ///
        absorb(`absorb') cluster(`cluster') stubs(`zillow_cats')
    
    local specifications "`r(specifications)'"

    * Listings
    use "`instub'/zipcode_months_listings.dta", clear
    xtset zipcode_num `absorb'

    estimate_dist_lag_model if indata_n_listings,                               ///
        depvar(ln_monthly_listings) dyn_var(`mw_wkp_var') w(6) stat_var(mw_res) ///
        absorb(`absorb') cluster(`cluster')                                     ///
        model_name(monthly_listings)
    
    estimate_dist_lag_model if indata_n_listings,                               ///
        depvar(ln_monthly_listings) dyn_var(`mw_wkp_var') w(6) stat_var(mw_res) ///
        absorb(`absorb'##cbsa_num) cluster(`cluster')                           ///
        model_name(monthly_listings_by_cbsa)
    
    estimate_dist_lag_model if indata_price_psqft,                          ///
        depvar(ln_prices_psqft) dyn_var(`mw_wkp_var') w(6) stat_var(mw_res) ///
        absorb(`absorb') cluster(`cluster')                                 ///
        model_name(prices_psqft)
        
    estimate_dist_lag_model if indata_price_psqft,                          ///
        depvar(ln_prices_psqft) dyn_var(`mw_wkp_var') w(6) stat_var(mw_res) ///
        absorb(`absorb'##cbsa_num) cluster(`cluster')                       ///
        model_name(prices_psqft_by_cbsa)
        
    local specifications "`specifications' monthly_listings monthly_listings_by_cbsa"
    local specifications "`specifications' prices_psqft prices_psqft_by_cbsa"	

    clear
    foreach ff in `specifications' {        
        append using ../temp/estimates_`ff'.dta
    }

    save             `outstub'/estimates_dynamic.dta, replace
    export delimited `outstub'/estimates_dynamic.csv, replace
end

program estimate_alt_zillow_cats_dyn, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str) stubs(str)

    local specifications ""

    foreach stub of local stubs {
        estimate_dist_lag_model if unbalanced_sample_`stub',                                   ///
            depvar(ln_rents_`stub') dyn_var(`mw_wkp_var') w(6) stat_var(mw_res)                ///
            controls(`controls') absorb(`absorb'##qtr_entry_to_zillow_`stub') cluster(`cluster')         ///
            model_name(`stub'_rents_dyn) test_equality
        
        local specifications "`specifications' `stub'_rents_dyn"
    }

    return local specifications "`specifications'"
end


main
