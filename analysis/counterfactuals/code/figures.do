clear all
set more off
set maxvar 32000

program main
    local instub      "../output"
    local in_baseline "../../fd_baseline/output"
    local in_wages    "../../twfe_wages/output"
    local in_zip      "../../../drive/derived_large/zipcode"

    use "`in_zip'/zipcode_cross.dta", clear
    load_parameters, in_baseline(`in_baseline') in_wages(`in_wages')
    local beta    = r(beta)
    local gamma   = r(gamma)
    local epsilon = r(epsilon)

    di "Beta, Gamma, and Epsilon: `beta', `gamma', `epsilon'"

    use `instub'/d_ln_rents_cf_predictions.dta, clear
    merge 1:1 zipcode using  `instub'/ln_wagebill_cf_predictions.dta, ///
        nogen keep(1 3) keepusing(ln_wagebill_pre n_hhlds_pre)
    merge 1:1 zipcode using "`in_zip'/zipcode_cross.dta", ///
        nogen keep(1 3) keepusing(cbsa sh_rural_pop_2010)
    gen rural = (sh_rural_pop_2010 >= 0.8)
    drop sh_rural_pop_2010

    compute_vars, beta(`beta') gamma(`gamma') epsilon(`epsilon')
    preserve
        keep zipcode cbsa d_mw_res d_mw_wkp_tot_17 ///
            change_ln_wagebill change_ln_rents rho
        save_data "../output/predicted_changes_in_rents.dta", ///
            key(zipcode) replace log(none)
        export delimited "../output/predicted_changes_in_rents.csv", replace
    restore
    foreach var in d_mw_res d_mw_wkp_tot_17 ///
                    perc_incr_rent perc_incr_wagebill ///
                    ratio_increases rho {
        
        get_xlabel, var(`var')
        local x_lab = r(x_lab)
        
        local scale_opts ""
        local bin_opt    ""
        if inlist("`var'", "d_mw_res", "d_mw_wkp_tot_17") {
            local scale_opts "yscale(r(0 43)) xscale(r(0 0.23))"
            local bin_opt    "bin(25)"
        }
        if inlist("`var'", "rho", "perc_incr_rent", "perc_incr_wagebill") {
            local bin_opt    "bin(30)"
        }

        hist `var', percent `bin_opt'                                   ///
            xtitle("`x_lab'") ytitle("Percentage") `scale_opts'         ///
            graphregion(color(white)) bgcolor(white)                    ///
            plotregion(margin(b = 1.5))
        
        graph export "../output/`var'.png", replace
        graph export "../output/`var'.eps", replace
    }

    save             "../output/data_counterfactuals.dta", replace
    export delimited "../output/data_counterfactuals.csv", replace

    collapse (mean) rho_lb rho rho_ub, by(diff_qts)

    twoway (line     rho       diff_qts, lcol(navy))                        ///
           (scatter  rho       diff_qts, mcol(navy)),                       ///
        xtitle("Difference between change in wrk. and res. MW (deciles)")   ///
        ytitle("Mean share accruing to landlord on each dollar")            ///
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
    if "`var'"=="d_mw_wkp_tot_17"    return local x_lab "Change in workplace MW"

    if "`var'"=="perc_incr_rent"     return local x_lab "Percent increase in rents per sq. foot"
    if "`var'"=="perc_incr_wagebill" return local x_lab "Percent increase in total wages"

    if "`var'"=="ratio_increases"    return local x_lab "Ratio of percent increases"
    if "`var'"=="rho"                return local x_lab "Landlord share"	

end


main
