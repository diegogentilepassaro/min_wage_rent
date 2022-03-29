clear all
set more off
set maxvar 32000

program main
    local instub      "../output"
    local in_wages    "../../twfe_wages/output"
    local in_zip      "../../../drive/derived_large/zipcode"

    use "`instub'/data_counterfactuals.dta", clear

    keep if counterfactual == "fed_9usd" & year == 2020
    keep if !cbsa_low_inc_increase

    foreach var in d_mw_res d_mw_wkp rho                   ///
                   change_ln_rents change_ln_wagebill  {
        
        get_xlabel, var(`var')
        local x_lab = r(x_lab)
        
        local scale_opts ""
        local bin_opt    ""
        if inlist("`var'", "d_mw_res", "d_mw_wkp") {
            local scale_opts "yscale(r(0 53.5)) xscale(r(0 0.23))"
            local bin_opt    "bin(25)"
        }
        if inlist("`var'", "rho", "change_ln_rents", "change_ln_wagebill") {
            local bin_opt    "bin(30)"
            if "`var'"!="rho" {
                local scale_opts "yscale(r(0 40))"
            }
        }

        hist `var', percent `bin_opt'                                   ///
            xtitle("`x_lab'") ytitle("Percentage") `scale_opts'         ///
            graphregion(color(white)) bgcolor(white)                    ///
            plotregion(margin(b = 1.5))
        
        graph export "../output/hist_`var'.png", replace
        graph export "../output/hist_`var'.eps", replace
    }

    collapse (mean) rho_lb rho rho_ub, by(diff_qts)

    twoway (line     rho  diff_qts, lcol(navy))                             ///
           (scatter  rho  diff_qts, mcol(navy)),                            ///
        xtitle("Difference between change in wrk. MW and change in res. MW (deciles)")  ///
        ytitle("Mean landlord share")                                       ///
        xlabel(1(1)10) ylabel(0(0.04)0.2)                                   ///
        graphregion(color(white)) bgcolor(white) legend(off)
        
    graph export "../output/deciles_diff.png", replace
    graph export "../output/deciles_diff.eps", replace
end


program load_parameters, rclass
    syntax, in_baseline(str) in_wages(str)

    use `in_baseline'/estimates_static.dta, clear
    keep if model == "static_both"

    qui sum b if var == "mw_res"
    return local gamma = r(mean)
    qui sum b if var == "mw_wkp_tot_17"
    return local beta = r(mean)

    use `in_wages'/estimates_cbsa_time.dta, clear
    qui sum b
    return local epsilon = r(mean)
end

program compute_vars
    syntax, beta(str) gamma(str) epsilon(str) [s(real 0.35)]

    keep if rural == 0

    * Predictions with parameters
    gen diff_mw    = d_mw_wkp_tot_17 - d_mw_res
    xtile diff_qts = diff_mw, nquantiles(10)

    egen max_d_mw_res = max(d_mw_res)
    gen no_direct_treatment       = d_mw_res == 0
    gen fully_affected            = !no_direct_treatment

    gen change_ln_rents    = `beta'*d_mw_wkp_tot_17 + `gamma'*d_mw_res
    gen change_ln_wagebill = `epsilon'*d_mw_wkp_tot_17

    gen perc_incr_rent     = exp(change_ln_rents)    - 1
    gen perc_incr_wagebill = exp(change_ln_wagebill) - 1
    gen ratio_increases    = perc_incr_rent/perc_incr_wagebill

    local s_lb = `s' - 0.1
    local s_ub = `s' + 0.1

    gen rho    = `s'*ratio_increases
    gen rho_lb = `s_lb'*ratio_increases
    gen rho_ub = `s_ub'*ratio_increases
end

program get_xlabel, rclass
    syntax, var(str)

    if inlist("`var'", "p_d_ln_rents", "p_d_ln_rents_with_fe", ///
              "p_d_ln_rents_zillow", "p_d_ln_rents_with_fe_zillow") {
        return local x_lab "Change in log rents"
    }

    if "`var'"=="d_mw_res"           return local x_lab "Change in residence MW"
    if "`var'"=="d_mw_wkp"           return local x_lab "Change in workplace MW"

    if "`var'"=="change_ln_rents"    return local x_lab "Change in log rents per sq. foot"
    if "`var'"=="change_ln_wagebill" return local x_lab "Change in log total wages"

    if "`var'"=="rho"                return local x_lab "Share pocketed by landlords"
end


main
