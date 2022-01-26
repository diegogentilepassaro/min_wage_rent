clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local logfile "../output/data_file_manifest.log"

    local cluster "cbsa10"
    local absorb "year_month#event_id"

    use "`instub'/stacked_sample_window6.dta", clear
    *describe d_ln_emp_* d_ln_estcount_* d_ln_avgwwage_*, varlist
    *local controls = r(varlist)

    estimate_stacked_model if !missing(d_ln_rents), depvar(d_exp_ln_mw) ///
        mw_var1(d_ln_mw) mw_var2(d_ln_mw) ///
        absorb(`absorb') cluster(statefips) ///
        model_name(exp_mw_on_mw_w6) outfolder("../temp")

    estimate_stacked_model, depvar(d_ln_rents) ///
        mw_var1(d_ln_mw) mw_var2(d_ln_mw) ///
        absorb(`absorb') cluster(statefips) ///
        model_name(res_only_w6) outfolder("../temp")
        
    estimate_stacked_model, depvar(d_ln_rents) ///
        mw_var1(d_exp_ln_mw) mw_var2(d_exp_ln_mw) ///
        absorb(`absorb') cluster(statefips) ///
        model_name(exp_only_w6) outfolder("../temp")

    estimate_stacked_model, depvar(d_ln_rents) ///
        mw_var1(d_ln_mw) mw_var2(d_exp_ln_mw) ///
        absorb(`absorb') cluster(statefips) ///
        model_name(static_w6) outfolder("../temp")
        
    estimate_dyn_stacked_model, depvar(d_ln_rents) ///
        res_mw_var(d_ln_mw) wkp_mw_var(d_exp_ln_mw) ///
        absorb(`absorb') cluster(statefips) ///
        model_name(dyn_w6) outfolder("../temp")
        
    use ../temp/estimates_exp_mw_on_mw_w6.dta, clear
    foreach ff in res_only_w6 exp_only_w6 static_w6 {
        append using ../temp/estimates_`ff'.dta
    }
    save_data "../output/estimates_stacked_static.dta", ///
        key(model var at) log(`logfile') replace
    export delimited "../output/estimates_stacked_static.csv", replace

    use ../temp/estimates_dyn_w6.dta, clear
    save_data "../output/estimates_stacked_dyn.dta", ///
        key(model var at) log(`logfile') replace
    export delimited "../output/estimates_stacked_dyn.csv", replace
end

main
