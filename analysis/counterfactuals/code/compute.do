clear all
set more off
set maxvar 32000
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_cf_mw     "../../../drive/derived_large/min_wage_measures"
    local in_baseline  "../../fd_baseline/output"
    local in_wages     "../../twfe_wages/output"
    local in_exp_share "../../../drive/analysis_large/expenditure_shares"
    local in_zip       "../../../drive/derived_large/zipcode"
    local out_large    "../../../drive/analysis_large/counterfactuals"

    load_parameters, in_baseline(`in_baseline') in_wages(`in_wages')
    local beta    = r(beta)
    local gamma   = r(gamma)
    local epsilon = r(epsilon)

    di "Beta, Gamma, and Epsilon: `beta', `gamma', `epsilon'"

    load_counterfactuals,  instub(`in_cf_mw')
    select_urban_zipcodes, instub(`in_zip')
    merge m:1 zipcode using "`in_exp_share'/s_by_zip.dta", ///
        nogen keep(1 3)
    
    compute_vars,         beta(`beta') gamma(`gamma') epsilon(`epsilon')
    flag_unaffected_cbsas
    flag_treatment_status

    foreach cf in fed_10pc fed_9usd fed_15usd chi14 {

        qui unique cbsa if counterfactual == "`cf'"
        local n_cbsas           = `r(unique)'
        qui unique cbsa if cbsa_low_inc_increase == 0 & counterfactual == "`cf'"
        local n_cbsas_affected = `r(unique)'

        di "{bf: Counterfactual: `cf'}"
        di "    Unique CBAs: `n_cbsas'"
        di "    Unique CBAs strongly affected: `n_cbsas_affected'"

        di "    Distribution of rho"
        sum rho if counterfactual == "`cf'" & year == 2020, d
        di "    Distribution of rho for strongly affected CBAs"
        sum rho if counterfactual == "`cf'" & year == 2020 & cbsa_low_inc_increase == 0, d
    }

    save_data  "`out_large'/data_counterfactuals.dta", key(zipcode counterfactual year) ///
        log("../output/data_file_manifest.log") replace
    export delimited "`out_large'/data_counterfactuals.csv", replace

    preserve
        compute_tot_incidence

        qui sum tot_incidence if counterfactual == "fed_9usd"
        local tot_inc = r(mean)

        export delimited "../output/tot_incidence.csv", replace
    restore

end

program load_parameters, rclass
    syntax, in_baseline(str) in_wages(str)

    use `in_baseline'/estimates_static.dta, clear
    keep if model == "static_both"

    qui sum b if var == "mw_res"
    return local gamma = r(mean)
    qui sum b if var == "mw_wkp_tot_17"
    return local beta = r(mean)

    use `in_wages'/estimates_all.dta if model == "cbsa_time", clear
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
    
    gen        diff_mw  = d_mw_wkp - d_mw_res
    gquantiles diff_qts = diff_mw, xtile nquantiles(10) by(counterfactual)
end

program select_urban_zipcodes
    syntax, instub(str)

    merge m:1 zipcode using `instub'/zipcode_cross.dta,  ///
        assert(2 3) keep(3) nogen keepusing(cbsa urban_cbsa)

    keep if urban_cbsa
end

program compute_vars
    syntax, beta(str) gamma(str) epsilon(str)

    gen change_ln_rents    = `beta'*d_mw_wkp + `gamma'*d_mw_res
    gen change_ln_wagebill = `epsilon'*d_mw_wkp

    gen perc_incr_rent     = exp(change_ln_rents)    - 1
    gen perc_incr_wagebill = exp(change_ln_wagebill) - 1
    gen ratio_increases    = perc_incr_rent/perc_incr_wagebill

    gen rho              = s*ratio_increases
    gen rho_with_imputed = s_imputed*ratio_increases

    foreach var in change_ln_rents change_ln_wagebill perc_incr_rent perc_incr_wagebill ///
                   ratio_increases rho rho_with_imputed {
        
        replace `var' = . if missing(d_mw_res)
    }
end

program flag_unaffected_cbsas
    syntax, [thresh(real 0.001)]

    preserve
        collapse (mean) perc_incr_wagebill perc_incr_rent,       ///
            by(cbsa counterfactual)

        gen cbsa_low_inc_increase = perc_incr_wagebill < `thresh'
        tempfile cbsa_averages
        save    `cbsa_averages', replace
    restore

    merge m:1 cbsa counterfactual using `cbsa_averages', ///
        assert(3) nogen
end

program flag_treatment_status

    preserve
        keep if year == 2020 & !missing(s_imputed) & !missing(perc_incr_rent)  ///
                             & !missing(perc_incr_wagebill)

        gen no_direct_treatment = (d_mw_res == 0)            if cbsa_low_inc_increase == 0
        gen fully_affected      = (no_direct_treatment == 0) if !missing(no_direct_treatment)

        keep zipcode counterfactual no_direct_treatment fully_affected
        
        tempfile treatment_status
        save    `treatment_status', replace
    restore

    merge m:1 zipcode counterfactual using `treatment_status', assert(1 3) nogen
end

program compute_tot_incidence
    keep if !missing(s_imputed) & !missing(perc_incr_rent) &    ///
            !missing(perc_incr_wagebill) & cbsa_low_inc_increase == 0
    keep if (year == 2020 & month == 1)
    keep zipcode counterfactual change_ln_rents perc_incr_rent ///
        change_ln_wagebill perc_incr_wagebill                  ///
        safmr2br_imputed wage_per_whhld_monthly_imputed

    gen num_terms_ti   = safmr2br_imputed               * perc_incr_rent
    gen denom_terms_ti = wage_per_whhld_monthly_imputed * perc_incr_wagebill

    collapse (sum)   num_tot_incidence   = num_terms_ti    ///
                     denom_tot_incidence = denom_terms_ti  ///
             (count) N                   = num_terms_ti,   ///
        by(counterfactual)

    gen tot_incidence = num_tot_incidence/denom_tot_incidence
end

main
