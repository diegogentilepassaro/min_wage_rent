clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local outstub "../output"

    define_controls
    local controls "`r(economic_controls)'"
    local cluster = "statefips"
    local absorb  = "year_month"

    local mw_wkp_var "mw_wkp_tot_17"

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
        samples(baseline unbal unbal_by_entry fullbal)
    local specifications "`specifications' `r(specifications)'"
    
    estimate_arellano_bond, mw_wkp_var(`mw_wkp_var') controls(`controls')         ///
        absorb(`absorb') cluster(`cluster')
    local specifications "`specifications' `r(specifications)'"
	
	estimate_alt_zillow_cats, mw_wkp_var(`mw_wkp_var') controls(`controls') ///
	    absorb(`absorb') cluster(`cluster')
    local specifications "`specifications' `r(specifications)'"
    
    foreach mw_wkp_var in mw_wkp_tot_14 mw_wkp_tot_18 mw_wkp_tot_timevary    ///
                          mw_wkp_earn_under1250_17 mw_wkp_age_under29_17        {
        
        estimate_dist_lag_model if baseline_sample,                           ///
            depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)      ///
            controls(`controls') absorb(`absorb') cluster(`cluster')          ///
            model_name(`mw_wkp_var'_rents) test_equality
            
        estimate_dist_lag_model if (baseline_sample & !missing(D.ln_rents)),  ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)        ///
            controls(`controls') absorb(`absorb') cluster(`cluster')          ///
            model_name(`mw_wkp_var'_wkp_mw_on_res_mw) test_equality
            
        local specifications "`specifications' `mw_wkp_var'_rents `mw_wkp_var'_wkp_mw_on_res_mw"
    }

    clear
    foreach ff in `specifications' {        
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_static.dta, replace
    export delimited `outstub'/estimates_static.csv, replace

    ** DYNAMIC
    use "`instub'/zipcode_months.dta", clear
    xtset zipcode_num `absorb'
	
	local mw_wkp_var "mw_wkp_tot_17"
    estimate_alt_zillow_cats_dyn, mw_wkp_var(`mw_wkp_var') controls(`controls') ///
	    absorb(`absorb') cluster(`cluster')
    local specifications "`r(specifications)'"

	gen ln_monthly_listings = log(Monthlylistings_NSA_SFCC)

	estimate_dist_lag_model if baseline_sample,   ///
		depvar(ln_monthly_listings) dyn_var(`mw_wkp_var') w(6) stat_var(mw_res) ///
		controls(`controls') absorb(`absorb') cluster(`cluster')          ///
		model_name(monthly_listings)
		
	estimate_dist_lag_model if fullbal_sample,   ///
		depvar(ln_monthly_listings) dyn_var(`mw_wkp_var') w(6) stat_var(mw_res) ///
		controls(`controls') absorb(`absorb') cluster(`cluster')          ///
		model_name(monthly_listings_fullbal)
		
	estimate_dist_lag_model,   ///
		depvar(ln_monthly_listings) dyn_var(`mw_wkp_var') w(6) stat_var(mw_res) ///
		controls(`controls') absorb(`absorb'##yr_entry_to_zillow) cluster(`cluster')          ///
		model_name(monthly_listings_unbal)
		
    local specifications "`specifications' monthly_listings monthly_listings_fullbal"
    local specifications "`specifications' monthly_listings_unbal"


    clear
    foreach ff in `specifications' {        
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_dynamic.dta, replace
    export delimited `outstub'/estimates_dynamic.csv, replace
        
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

        estimate_dist_lag_model if baseline_sample,                           ///
            depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)      ///
            controls(`ctrl_vars') absorb(`absorb') cluster(`cluster')         ///
            model_name(`name'_rents) test_equality
        
        estimate_dist_lag_model if (baseline_sample & !missing(D.ln_rents)),   ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)         ///
            controls(`ctrl_vars') absorb(`absorb') cluster(`cluster')          ///
            model_name(`name'_wkp_mw_on_res_mw) test_equality

        local specifications "`specifications' `name'_rents `name'_wkp_mw_on_res_mw"
    }

    return local specifications "`specifications'"
end

program estimate_geofe_specifications, rclass
    syntax, mw_wkp_var(str) controls(str) cluster(str) geos(str)

    local specifications ""
    foreach geo in `geos' {
        estimate_dist_lag_model if baseline_sample,                                 ///
            depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)            ///
            controls(`controls') absorb(year_month##`geo'_num) cluster(`cluster')   ///
            model_name(`geo'time_fe_rents) test_equality
            
        estimate_dist_lag_model if (baseline_sample & !missing(D.ln_rents)),         ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)               ///
            controls(`controls') absorb(year_month##`geo'_num) cluster(`cluster')    ///
            model_name(`geo'time_fe_wkp_mw_on_res_mw) test_equality

        local specifications "`specifications' `geo'time_fe_rents `geo'time_fe_wkp_mw_on_res_mw"
    }

    return local specifications "`specifications'"
end

program estimate_sample_specifications, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str) ///
            samples(str)

    gen unbal_sample           = 1
    gen unbal_by_entry_sample  = 1
    gen weights_unbal_by_entry = weights_unbal

    local specifications ""
    foreach sample in `samples' {

        local absorb_vars "`absorb'"
        if "`'" == "unbal_by_entry" {
            local absorb_vars "`absorb'##yr_entry_to_zillow"
        }

        if "`sample'" != "baseline" {
            estimate_dist_lag_model if `sample'_sample,                                    ///
                depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)               ///
                controls(`controls') absorb(`absorb_vars') cluster(`cluster')              ///
                model_name(`sample'_rents) test_equality
                
            estimate_dist_lag_model if (`sample'_sample & !missing(D.ln_rents)),           ///
                depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)                 ///
                controls(`controls') absorb(`absorb_vars') cluster(`cluster')              ///
                model_name(`sample'_wkp_mw_on_res_mw) test_equality

            local specifications "`specifications' `sample'_rents `sample'_wkp_mw_on_res_mw"
        }

        estimate_dist_lag_model if `sample'_sample, depvar(ln_rents)                        ///
            dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) wgt(weights_`sample')               ///
            controls(`controls') absorb(`absorb_vars') cluster(`cluster')                   ///
            model_name(`sample'_wgt_rents) test_equality
            
        estimate_dist_lag_model if (`sample'_sample & !missing(D.ln_rents)),                 ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res) wgt(weights_`sample') ///
            controls(`controls') absorb(`absorb_vars') cluster(`cluster')                    ///
            model_name(`sample'_wgt_wkp_mw_on_res_mw) test_equality
            
        local specifications "`specifications' `sample'_wgt_rents `sample'_wgt_wkp_mw_on_res_mw"
    }

    drop unbal_* weights_unbal_by_entry
    return local specifications "`specifications'"
end


program estimate_arellano_bond, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str)

    estimate_dist_lag_model if baseline_sample,                         ///
        depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)    ///
        controls(`controls') ab absorb(`absorb') cluster(`cluster')     ///
        model_name(AB_rents) test_equality
    
    estimate_dist_lag_model if (baseline_sample & !missing(D.ln_rents)), ///
        depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)       ///
        controls(`controls') ab absorb(`absorb') cluster(`cluster')      ///
        model_name(AB_wkp_mw_on_res_mw) test_equality

    return local specifications "AB_rents AB_wkp_mw_on_res_mw"
end


program estimate_zipcodetrend, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str)

    estimate_dist_lag_model if baseline_sample,                           ///
        depvar(ln_rents) dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)      ///
        controls(`controls') absorb(`absorb' zipcode) cluster(`cluster')  ///
        model_name(ziptrend_rents) test_equality
        
    estimate_dist_lag_model if (baseline_sample & !missing(D.ln_rents)),   ///
        depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)         ///
        controls(`controls') absorb(`absorb' zipcode) cluster(`cluster')   ///
        model_name(ziptrend_wkp_mw_on_res_mw) test_equality

    return local specifications "ziptrend_rents ziptrend_wkp_mw_on_res_mw"
end

program estimate_alt_zillow_cats, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str)

    local specifications ""
	
	local depvars "SF CC Studio 1BR 2BR 3BR Mfr5Plus"
    local n_depvars: word count `depvars'
	
    forval i = 1/`n_depvars' {
        local depvar: word `i' of `depvars'

        estimate_dist_lag_model if baseline_sample,                           ///
            depvar(ln_rents_`depvar') dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)      ///
            controls(`controls') absorb(`absorb') cluster(`cluster')         ///
            model_name(`depvar'_rents) test_equality
        
        estimate_dist_lag_model if (baseline_sample & !missing(D.ln_rents_`depvar')),   ///
            depvar(`mw_wkp_var') dyn_var(mw_res) w(0) stat_var(mw_res)         ///
            controls(`controls') absorb(`absorb') cluster(`cluster')          ///
            model_name(`depvar'_wkp_mw_on_res_mw) test_equality

        local specifications "`specifications' `depvar'_rents `depvar'_wkp_mw_on_res_mw"
    }

    return local specifications "`specifications'"
end

program estimate_alt_zillow_cats_dyn, rclass
    syntax, mw_wkp_var(str) controls(str) absorb(str) cluster(str)

    local specifications ""
	
	local depvars "SF CC Studio 1BR 2BR 3BR Mfr5Plus"
    local n_depvars: word count `depvars'
	
    forval i = 1/`n_depvars' {
        local depvar: word `i' of `depvars'

        estimate_dist_lag_model if baseline_sample,                           ///
            depvar(ln_rents_`depvar') dyn_var(`mw_wkp_var') w(6) stat_var(mw_res)      ///
            controls(`controls') absorb(`absorb') cluster(`cluster')         ///
            model_name(`depvar'_rents_dyn) test_equality

        local specifications "`specifications' `depvar'_rents_dyn"
    }

    return local specifications "`specifications'"
end

main
