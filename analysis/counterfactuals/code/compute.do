clear all
set more off
set maxvar 32000

program main
    local in_cf_mw    "../../../drive/derived_large/min_wage_measures"
    local in_baseline "../../fd_baseline/output"
    local in_wages    "../../twfe_wages/output"
    local in_zip      "../../../drive/derived_large/zipcode"

    load_parameters, in_baseline(`in_baseline') in_wages(`in_wages')
    local beta    = r(beta)
    local gamma   = r(gamma)
    local epsilon = r(epsilon)

    di "Beta, Gamma, and Epsilon: `beta', `gamma', `epsilon'"

    load_counterfactuals,  instub(`in_cf_mw')
    select_urban_zipcodes, instub(`in_zip')
    
    compute_vars, beta(`beta') gamma(`gamma') epsilon(`epsilon')

    list if rho < -1
    drop if rho < -1

    sum rho, detail

    save             "../output/data_counterfactuals.dta", replace
    export delimited "../output/data_counterfactuals.csv", replace
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

program load_counterfactuals
    syntax, instub(str)

    clear
    use zipcode year month counterfactual mw_wkp_tot mw_res statutory_mw ///
        using "`instub'/zipcode_wkp_mw_cfs.dta"

    bysort zipcode counterfactual (year month): ///
        gen d_mw_wkp = mw_wkp_tot[_n] - mw_wkp_tot[_n - 1]
    bysort zipcode counterfactual (year month): ///
        gen d_mw_res = mw_res[_n] - mw_res[_n - 1]
    
    * Predictions with parameters
    gen   diff_mw  = d_mw_wkp - d_mw_res
    xtile diff_qts = diff_mw, nquantiles(10)
end

program select_urban_zipcodes
    syntax, instub(str)

    merge m:1 zipcode using `instub'/zipcode_cross.dta,  ///
        assert(2 3) keep(3) nogen keepusing(cbsa urban_cbsa)

    keep if urban_cbsa
end

program compute_vars
    syntax, beta(str) gamma(str) epsilon(str) [s(real 0.35)]

    gen  no_direct_treatment  = d_mw_res == 0
    gen  fully_affected       = !no_direct_treatment

    gen change_ln_rents    = `beta'*d_mw_wkp + `gamma'*d_mw_res
    gen change_ln_wagebill = `epsilon'*d_mw_wkp

    gen perc_incr_rent     = exp(change_ln_rents)    - 1
    gen perc_incr_wagebill = exp(change_ln_wagebill) - 1
    gen ratio_increases    = perc_incr_rent/perc_incr_wagebill

    local s_lb = `s' - 0.1
    local s_ub = `s' + 0.1

    gen rho    = `s'*ratio_increases
    gen rho_lb = `s_lb'*ratio_increases
    gen rho_ub = `s_ub'*ratio_increases
end


main
