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
    
    use "`instub'/zipcode_months.dta", clear
    xtset zipcode_num `absorb'

    estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(baseline) outfolder("../temp")
        
    estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(" ") absorb(`absorb') cluster(`cluster') ///
        model_name(nocontrols) outfolder("../temp")

    estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(`controls') ab absorb(`absorb') cluster(`cluster') ///
        model_name(AB) outfolder("../temp")

    estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality wgt(weights_baseline) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(baseline_wgt) outfolder("../temp")
    
    local specifications "`specifications' baseline nocontrols AB baseline_wgt"

    estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(`controls') absorb(`absorb' zipcode) cluster(`cluster') ///
        model_name(zip_spec_trend) outfolder("../temp")
        
    estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(`controls') absorb(`absorb'##county_num) ///
        cluster(`cluster') ///
        model_name(county_timefe) outfolder("../temp")

    estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(`controls') absorb(`absorb'##cbsa_num) ///
        cluster(`cluster') ///
        model_name(cbsa_timefe) outfolder("../temp")
        
    estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(`controls') absorb(`absorb'##statefips_num) ///
        cluster(`cluster') ///
        model_name(state_timefe) outfolder("../temp")
    
    local specifications "`specifications' zip_spec_trend county_timefe cbsa_timefe state_timefe"

    foreach mw_wkp_alt_var in mw_wkp_tot_10 mw_wkp_tot_14 mw_wkp_tot_18 mw_wkp_earn_under1250_17 mw_wkp_age_under29_17 {
        
        estimate_dist_lag_model if baseline_sample == 1, depvar(ln_rents) ///
            dyn_var(`mw_wkp_alt_var') w(0) stat_var(mw_res) test_equality ///
            controls(`controls') absorb(`absorb') cluster(`cluster') ///
            model_name(`mw_wkp_alt_var') outfolder("../temp")
            
        local specifications "`specifications' `mw_wkp_alt_var'"
    }

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(unbal) outfolder("../temp")
    
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality wgt(weights_unbal) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(unbal_wgt) outfolder("../temp")

    local specifications "`specifications' unbal unbal_wgt"
    
    estimate_dist_lag_model if fullbal_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(fullbal) outfolder("../temp")
    
    estimate_dist_lag_model if fullbal_sample == 1, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) test_equality wgt(weights_fullbal) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(fullbal_wgt) outfolder("../temp")
    
    local specifications "`specifications' fullbal fullbal_wgt"

    clear
    foreach ff in `specifications' {        
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_static.dta, replace
    export delimited `outstub'/estimates_static.csv, replace
end


main
