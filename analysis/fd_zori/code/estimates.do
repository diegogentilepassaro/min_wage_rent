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

    local mw_wkp_var "mw_wkp_F"

    use "`instub'/zipcode_months.dta", clear
    xtset zipcode_num year_month

    gen mw_wkp_F = F4.mw_wkp_tot_17
    gen mw_res_F = F4.mw_res

    estimate_dist_lag_model, depvar(ln_zori_23)           ///
        dyn_var(`mw_wkp_var') w(4) stat_var(mw_res_F)     ///
        controls(`controls') absorb(year_month)           ///
        cluster(`cluster') model_name(time_FE)
    
    estimate_dist_lag_model, depvar(ln_zori_23)           ///
        dyn_var(`mw_wkp_var') w(4) stat_var(mw_res_F)     ///
        controls(`controls') absorb(cbsa_num##year_month) ///
        cluster(`cluster') model_name(cbsa_time_FE)
    
    clear
    foreach ff in time_FE cbsa_time_FE {
        append using ../temp/estimates_`ff'.dta
    }

    save             "`outstub'/estimates_zori.dta", replace
    export delimited "`outstub'/estimates_zori.csv", replace
end

main
