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
    local zillow_cats "SF CC Studio 1BR 2BR 3BR Mfr5Plus"

    ** STATIC	
    use "`instub'/zipcode_months.dta", clear
    xtset zipcode_num `absorb'

    estimate_baseline_ctrls, mw_wkp_var(`mw_wkp_var') controls(`controls')      ///
        absorb(`absorb') cluster(`cluster')
    local specifications "`r(specifications)'"

    estimate_geofe_specifications, mw_wkp_var(`mw_wkp_var') controls(" ")       ///
        cluster(`cluster') geos(county cbsa place_code statefips)
    local specifications "`specifications' `r(specifications)'"

    estimate_zipcodetrend, mw_wkp_var(`mw_wkp_var') controls(`controls')         ///
        absorb(`absorb') cluster(`cluster')
    local specifications "`specifications' `r(specifications)'"

    estimate_sample_specifications, mw_wkp_var(`mw_wkp_var') controls(`controls') ///
        absorb(`absorb') cluster(`cluster')                                       ///
        samples(baseline unbalanced unbal_by_entry)
    local specifications "`specifications' `r(specifications)'"

    estimate_arellano_bond, mw_wkp_var(`mw_wkp_var') controls(`controls')         ///
        absorb(`absorb') cluster(`cluster')
    local specifications "`specifications' `r(specifications)'"

    estimate_alt_zillow_cats, mw_wkp_var(`mw_wkp_var') controls(`controls')       ///
        absorb(`absorb') cluster(`cluster') stubs(`zillow_cats')
    local specifications "`specifications' `r(specifications)'"

    foreach mw_wkp_var in mw_wkp_tot_14 mw_wkp_tot_18 mw_wkp_tot_timevary          ///
                            mw_wkp_earn_under1250_17 mw_wkp_age_under29_17        {
        
        estimate_dist_lag_model if fullbal_sample_SFCC == 1,                       ///
            depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)           ///
            controls(`controls') absorb(`absorb') cluster(`cluster')               ///
            model_name(`mw_wkp_var'_rents) test_equality
            
        estimate_dist_lag_model if (fullbal_sample_SFCC == 1 & !missing(D.ln_rents)), ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)               ///
            controls(`controls') absorb(`absorb') cluster(`cluster')                 ///
            model_name(`mw_wkp_var'_wkp_mw_on_res_mw) test_equality
        
        local specifications "`specifications' `mw_wkp_var'_rents `mw_wkp_var'_wkp_mw_on_res_mw"
    }

    clear
    foreach ff in `specifications' {        
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_static.dta, replace
    export delimited `outstub'/estimates_static.csv, replace
end

program estimate_baseline_ctrls, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str)

    local specifications ""
    foreach num in 1 2 {

        if `num' == 1 {
            local name      "baseline"
            local ctrl_vars "`controls'"
        }
        else {
            local name      "nocontrols"
            local ctrl_vars ""
        }    

        estimate_dist_lag_model if fullbal_sample_SFCC == 1,                  ///
            depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)      ///
            controls(`ctrl_vars') absorb(`absorb') cluster(`cluster')         ///
            model_name(`name'_rents) test_equality
        
        estimate_dist_lag_model if (fullbal_sample_SFCC == 1 & !missing(D.ln_rents)), ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)                ///
            controls(`ctrl_vars') absorb(`absorb') cluster(`cluster')                 ///
            model_name(`name'_wkp_mw_on_res_mw) test_equality

        local specifications "`specifications' `name'_rents `name'_wkp_mw_on_res_mw"
    }

    return local specifications "`specifications'"
    end

program estimate_geofe_specifications, rclass
    syntax, mw_wkp_var(str) controls(str) cluster(str) geos(str)

    local specifications ""
    foreach geo in `geos' {
        estimate_dist_lag_model if fullbal_sample_SFCC == 1,                        ///
            depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)            ///
            controls(`controls') absorb(year_month##`geo'_num) cluster(`cluster')   ///
            model_name(`geo'time_fe_rents) test_equality
            
        estimate_dist_lag_model if (fullbal_sample_SFCC == 1 & !missing(D.ln_rents)),  ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)                 ///
            controls(`controls') absorb(year_month##`geo'_num) cluster(`cluster')      ///
            model_name(`geo'time_fe_wkp_mw_on_res_mw) test_equality

        local specifications "`specifications' `geo'time_fe_rents `geo'time_fe_wkp_mw_on_res_mw"
    }

    return local specifications "`specifications'"
end

program estimate_sample_specifications, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str) ///
            samples(str)

    gen unbal_by_entry_sample_SFCC  =  unbalanced_sample_SFCC
    gen weights_unbal_by_entry      =  weights_unbalanced

    local specifications ""
    foreach sample in `samples' {
        if "`sample'" == "baseline" {
            local sample_ind "fullbal"
        }
        else{
            local sample_ind "`sample'"
        }

        local absorb_vars "`absorb'"
        if "`'" == "unbal_by_entry" {
            local absorb_vars "`absorb'##qtr_entry_to_zillow_SFCC"
        }

        estimate_dist_lag_model if `sample_ind'_sample_SFCC == 1,                               ///
            depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)               ///
            controls(`controls') absorb(`absorb_vars') cluster(`cluster')              ///
            model_name(`sample'_rents) test_equality
            
        estimate_dist_lag_model if (`sample_ind'_sample_SFCC == 1 & !missing(D.ln_rents)),      ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)                 ///
            controls(`controls') absorb(`absorb_vars') cluster(`cluster')              ///
            model_name(`sample'_wkp_mw_on_res_mw) test_equality

        local specifications "`specifications' `sample'_rents `sample'_wkp_mw_on_res_mw"

        estimate_dist_lag_model if `sample_ind'_sample_SFCC, depvar(ln_rents)                   ///
            dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) wgt(weights_`sample_ind')               ///
            controls(`controls') absorb(`absorb_vars') cluster(`cluster')                   ///
            model_name(`sample'_wgt_rents) test_equality
            
        estimate_dist_lag_model if (`sample_ind'_sample_SFCC == 1 & !missing(D.ln_rents)),            ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res) wgt(weights_`sample_ind') ///
            controls(`controls') absorb(`absorb_vars') cluster(`cluster')                    ///
            model_name(`sample'_wgt_wkp_mw_on_res_mw) test_equality
            
        local specifications "`specifications' `sample'_wgt_rents `sample'_wgt_wkp_mw_on_res_mw"
    }

    drop unbal_by_entry_sample_SFCC weights_unbal_by_entry
    return local specifications "`specifications'"
end


program estimate_arellano_bond, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str)
		
    estimate_dist_lag_model if fullbal_sample_SFCC == 1,                  ///
        depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)      ///
        controls(`controls') ab absorb(`absorb') cluster(`cluster')       ///
        model_name(AB_rents) test_equality
		
    estimate_stacked_model if fullbal_sample_SFCC == 1, depvar(ln_rents)  ///
        mw_var1(mw_res) mw_var2(`mw_wkp_var') controls(`controls')        ///
        absorb(year_month zipcode) cluster(statefips)                     ///
        model_name(levels_model) test_equality
		
    estimate_stacked_model if fullbal_sample_SFCC == 1, depvar(ln_rents)  ///
        mw_var1(mw_res) mw_var2(`mw_wkp_var') controls(`controls')        ///
        absorb(year_month zipcode) cluster(statefips) ab                  ///
        model_name(AB_levels_model) test_equality

    return local specifications "AB_rents levels_model AB_levels_model"
end


program estimate_zipcodetrend, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str)

    estimate_dist_lag_model if fullbal_sample_SFCC == 1,                  ///
        depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)      ///
        controls(`controls') absorb(`absorb' zipcode) cluster(`cluster')  ///
        model_name(ziptrend_rents) test_equality
        
    estimate_dist_lag_model if (fullbal_sample_SFCC == 1 & !missing(D.ln_rents)),  ///
        depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)                 ///
        controls(`controls') absorb(`absorb' zipcode) cluster(`cluster')           ///
        model_name(ziptrend_wkp_mw_on_res_mw) test_equality

    return local specifications "ziptrend_rents ziptrend_wkp_mw_on_res_mw"
end

program estimate_alt_zillow_cats, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str) stubs(str)

    local specifications ""

    foreach stub of local stubs {
        estimate_dist_lag_model if unbalanced_sample_`stub',                       ///
            depvar(ln_rents_`stub') dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)    ///
            controls(`controls') absorb(`absorb'##qtr_entry_to_zillow_`stub')      ///
            cluster(`cluster') model_name(`stub'_rents) test_equality
        
        estimate_dist_lag_model if unbalanced_sample_`stub' & !missing(D.ln_rents_`stub'),    ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)                        ///
            controls(`controls') absorb(`absorb'##qtr_entry_to_zillow_`stub')                 ///
            cluster(`cluster')  model_name(`stub'_wkp_mw_on_res_mw) test_equality

        local specifications "`specifications' `stub'_rents `stub'_wkp_mw_on_res_mw"
    }

    return local specifications "`specifications'"
end


main
