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
    
    
    use "`instub'/baseline_zipcode_months.dta", clear
    xtset zipcode_num year_month

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(static_baseline) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(" ") absorb(year_month) cluster(`cluster') ///
        model_name(static_nocontrols) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') ab absorb(year_month) cluster(`cluster') ///
        model_name(static_AB) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality wgt(wgt_cbsa100) ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(static_baseline_wgt) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month zipcode) cluster(`cluster') ///
        model_name(static_zip_spec_trend) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month##statefips_num year_month##county_num) ///
        cluster(`cluster') ///
        model_name(static_state_county_timefe) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month##statefips_num year_month##cbsa10_num) ///
        cluster(`cluster') ///
        model_name(static_state_cbsa_timefe) outfolder("../temp")
        
    
    use "`instub'/all_zipcode_months.dta", clear
    xtset zipcode_num year_month

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(static_unbal) outfolder("../temp")
    
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality wgt(wgt_cbsa100) ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(static_unbal_wgt) outfolder("../temp")

    
    use "`instub'/balanced_zipcode_months.dta", clear
    xtset zipcode_num year_month    
    
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(static_fullbal) outfolder("../temp")
    
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(exp_ln_mw_17) w(0) stat_var(ln_mw) test_equality wgt(wgt_cbsa100) ///
        controls(`controls') absorb(year_month) cluster(`cluster') ///
        model_name(static_fullbal_wgt) outfolder("../temp")
        

    use "../temp/estimates_static_baseline.dta", clear
    foreach ff in static_nocontrols          static_AB                 ///
                  static_baseline_wgt        static_zip_spec_trend     ///
                  static_state_county_timefe static_state_cbsa_timefe  ///
                  static_unbal               static_unbal_wgt          ///
                  static_fullbal             static_fullbal_wgt {
        
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_static.dta, replace
    export delimited `outstub'/estimates_static.csv, replace
end


main
