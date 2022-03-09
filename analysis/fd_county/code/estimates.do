clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub  "../../../drive/derived_large/estimation_samples"
    local outstub "../output"

    define_controls
    local controls "`r(economic_controls)'"
    local cluster = "statefips"
    local absorb  = "year_month"

    local mw_wkp_var "mw_wkp_tot_17"

    ** STATIC
    use "`instub'/county_months.dta" if baseline_sample, clear
    xtset county_num `absorb'

    estimate_dist_lag_model if !missing(D.ln_rents), depvar(`mw_wkp_var') ///
        dyn_var(mw_res) w(0) stat_var(mw_res) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(mw_wkp_on_res_mw) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(mw_res) w(0) stat_var(mw_res) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(static_mw_res) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(`mw_wkp_var') ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(static_mw_wkp) outfolder("../temp")

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(static_both) test_equality outfolder("../temp")

    use ../temp/estimates_mw_wkp_on_res_mw.dta, clear
    gen p_equality = .
    foreach ff in static_mw_res static_mw_wkp static_both {
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_static.dta, replace
    export delimited `outstub'/estimates_static.csv, replace

    ** DYNAMIC
    use "`instub'//county_months.dta" if baseline_sample, clear
    xtset county_num `absorb'

    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(6) stat_var(mw_res) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(both_mw_wkp_dynamic) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(mw_res) w(6) stat_var(`mw_wkp_var') ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(both_mw_res_dynamic) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(`mw_wkp_var') w(6) stat_var(`mw_wkp_var') ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(mw_wkp_only_dynamic) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents) ///
        dyn_var(mw_res) w(6) stat_var(mw_res) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(mw_res_only_dynamic) outfolder("../temp")
        
    estimate_dist_lag_model_two_dyn, depvar(ln_rents) ///
        dyn_var1(`mw_wkp_var') w(6) dyn_var2(mw_res) ///
        controls(`controls') absorb(`absorb') cluster(`cluster') ///
        model_name(both_dynamic) outfolder("../temp")
        
    use ../temp/estimates_both_mw_wkp_dynamic.dta, clear
    foreach ff in both_mw_res_dynamic mw_wkp_only_dynamic ///
        mw_res_only_dynamic both_dynamic {
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_dynamic.dta, replace
    export delimited `outstub'/estimates_dynamic.csv, replace
end

main
