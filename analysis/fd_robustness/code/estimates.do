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
    local cluster  "statefips"
    
    local specifications ""
    
    use "`instub'/baseline_zipcode_months.dta", clear
    xtset zipcode_num year_month

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(baseline) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(" ") absorb(year_month) cluster(`cluster') ///
        model_name(nocontrols) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') ab absorb(year_month) cluster(`cluster') ///
        model_name(AB) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality wgt(wgt_cbsa100) ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(baseline_wgt) outfolder("../temp")
    
    local specifications "`specifications' baseline nocontrols AB baseline_wgt"

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month zipcode) cluster(`cluster') ///
        model_name(zip_spec_trend) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month##county_num) ///
        cluster(`cluster') ///
        model_name(county_timefe) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month##cbsa10_num) ///
        cluster(`cluster') ///
        model_name(cbsa_timefe) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month##statefips_num) ///
        cluster(`cluster') ///
        model_name(state_timefe) outfolder("../temp")
    
    local specifications "`specifications' zip_spec_trend county_timefe cbsa_timefe state_timefe"

    foreach exp_mw_var in exp_ln_mw_10 exp_ln_mw_14 exp_ln_mw_18 exp_ln_mw_earn_under1250_14 exp_ln_mw_age_under29_14 {
        
        estimate_dist_lag_model, depvar(ln_rents) ///
            dyn_var(`exp_mw_var') w(0) stat_var(ln_mw) test_equality ///
            controls(`controls') absorb(year_month) cluster(`cluster') ///
            model_name(baseline_`exp_mw_var') outfolder("../temp")
            
        local specifications "`specifications' baseline_`exp_mw_var'"
    }

    use "`instub'/all_zipcode_months.dta", clear
    xtset zipcode_num year_month

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(unbal) outfolder("../temp")
    
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality wgt(wgt_cbsa100) ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(unbal_wgt) outfolder("../temp")

    local specifications "`specifications' unbal unbal_wgt"
    
    use "`instub'/balanced_zipcode_months.dta", clear
    xtset zipcode_num year_month    
    
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(fullbal) outfolder("../temp")
    
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality wgt(wgt_cbsa100) ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
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
