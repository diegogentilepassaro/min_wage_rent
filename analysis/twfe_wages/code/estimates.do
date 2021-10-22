clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/zipcode_year"
    local outstub "../output"

    define_controls
    local controls "`r(economic_controls)'"
    local cluster "statefips"

    local exp_ln_mw_var "exp_ln_mw_17"

    ** STATIC
    use "`instub'/zipcode_year.dta", clear
    xtset zipcode_num year_month

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvar(exp_ln_mw_17_avg) controls(" ")        ///
        absorb(zipcode year) cluster(`cluster') model_name(naive)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvar(exp_ln_mw_17_avg) controls(`controls') ///
        absorb(zipcode year) cluster(`cluster') model_name(ctrls)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvar(exp_ln_mw_17_avg) controls(`controls') ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(cbsa_time)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvar(exp_ln_mw_17_avg) controls(`controls') ///
        absorb(zipcode year#state_num) cluster(`cluster') model_name(state_time)
    
    estimate_twfe_model if !missing(D.ln_rents), ///
        yvar(ln_wagebill) xvar(exp_ln_mw_17_avg) controls(`controls') ///
        absorb(zipcode year#cbsa_num) cluster(`cluster') model_name(cbsa_time_baseline)

    estimate_twfe_model, ///
        yvar(ln_wagebill) xvar(exp_ln_mw_10_avg) controls(`controls') ///
        absorb(zipcode year#state_num) cluster(`cluster') model_name(exp_mw_10)
    
    estimate_twfe_model, ///
        yvar(ln_wagebill) xvar(exp_ln_mw_18_avg) controls(`controls') ///
        absorb(zipcode year#state_num) cluster(`cluster') model_name(exp_mw_18)
    
    estimate_twfe_model, ///
        yvar(ln_wagebill) xvar(exp_ln_mw_18_avg) controls(`controls') ///
        absorb(zipcode year#state_num) cluster(`cluster') model_name(exp_mw_varying)
    
    estimate_twfe_model, ///
        yvar(ln_dividends) xvar(exp_ln_mw_17_avg) controls(`controls') ///
        absorb(zipcode year#state_num) cluster(`cluster') model_name(dividends)

    use ../temp/estimates_exp_mw_on_mw.dta, clear
    gen p_equality = .
    foreach ff in naive ctrls cbsa_time state_time cbsa_time_baseline ///
                  exp_mw_10 exp_mw_18 exp_mw_varying dividends {
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_static.dta, replace
    export delimited `outstub'/estimates_static.csv, replace
end

main
