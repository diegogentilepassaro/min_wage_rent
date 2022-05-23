clear all
set more off
set maxvar 32000

program main
    local in_cf_mw     "../../../drive/derived_large/min_wage_measures"
    local in_baseline  "../../fd_baseline/output"
    local in_wages     "../../twfe_wages/output"
    local in_exp_share "../../../drive/analysis_large/expenditure_shares"
    local in_zip       "../../../drive/derived_large/zipcode"

    load_parameters, in_baseline(`in_baseline') in_wages(`in_wages')
    local beta    = r(beta)
    local gamma   = r(gamma)
    local epsilon = r(epsilon)

    di "Beta, Gamma, and Epsilon: `beta', `gamma', `epsilon'"

    load_counterfactuals,  instub(`in_cf_mw')
    select_urban_zipcodes, instub(`in_zip')
    merge m:1 zipcode using "`in_exp_share'/s_by_zip.dta", ///
        nogen keep(1 3)
    
    compute_vars, beta(`beta') gamma(`gamma') epsilon(`epsilon')

    flag_unaffected_cbsas

    foreach cf in fed_10pc fed_9usd fed_15usd {

        qui unique cbsa if counterfactual == "`cf'"
        local n_cbsas           = `r(unique)'
        qui unique cbsa if !cbsa_low_inc_increase & counterfactual == "`cf'"
        local n_cbsas_affected = `r(unique)'

        di "{bf: Counterfactual: `cf'}"
        di "    Unique CBAs: `n_cbsas'"
        di "    Unique CBAs strongly affected: `n_cbsas_affected'"

        di "    Distribution of rho"
        sum rho if counterfactual == "`cf'" & year == 2020, detail
        di "    Distribution of rho for strongly affected CBAs"
        sum rho if counterfactual == "`cf'" & !cbsa_low_inc_increase & year == 2020, detail
    }

    save             "../output/data_counterfactuals.dta", replace
    export delimited "../output/data_counterfactuals.csv", replace

    preserve
        compute_tot_incidence
        export delimited "../output/tot_incidence.csv", replace
    restore

    make_autofill_values, beta(`beta') gamma(`gamma') epsilon(`epsilon')
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
    syntax, beta(str) gamma(str) epsilon(str)

    gen  no_direct_treatment  = d_mw_res == 0
    gen  fully_affected       = !no_direct_treatment

    gen change_ln_rents    = `beta'*d_mw_wkp + `gamma'*d_mw_res
    gen change_ln_wagebill = `epsilon'*d_mw_wkp

    gen perc_incr_rent     = exp(change_ln_rents)    - 1
    gen perc_incr_wagebill = exp(change_ln_wagebill) - 1
    gen ratio_increases    = perc_incr_rent/perc_incr_wagebill

    gen rho              = s*ratio_increases
    gen rho_with_imputed = s_imputed*ratio_increases
end

program flag_unaffected_cbsas
    syntax, [thresh(real 0.001)]

    preserve
        collapse (mean) perc_incr_wagebill perc_incr_rent,       ///
            by(cbsa counterfactual)

        gen cbsa_low_inc_increase = perc_incr_wagebill < `thresh'

        save "../output/cbsa_averages.dta", replace
    restore

    merge m:1 cbsa counterfactual using "../output/cbsa_averages.dta", ///
        assert(3) nogen
end

program compute_tot_incidence
    
    keep if (year == 2020 & month == 1) & !cbsa_low_inc_increase
    keep zipcode counterfactual change_ln_rents perc_incr_rent ///
        change_ln_wagebill perc_incr_wagebill                  ///
        safmr2br_imputed wage_per_whhld_monthly_imputed
    gen num_terms = safmr2br_imputed*(perc_incr_rent)
    gen denom_terms = wage_per_whhld_monthly_imputed*(perc_incr_wagebill)

    collapse (sum) num_tot_incidence   = num_terms         ///
                   denom_tot_incidence = denom_terms       ///
        if (!missing(num_terms) & !missing(denom_terms)),  ///
        by(counterfactual)

    gen tot_incidence = num_tot_incidence/denom_tot_incidence
end

program make_autofill_values
    syntax, gamma(str) beta(str) epsilon(str)

    qui sum rho if counterfactual == "fed_9usd" & !cbsa_low_inc_increase & year == 2020, detail
	
    local rho_mean = r(mean)
    local rho_median = r(p50)
	
    qui count if counterfactual == "fed_9usd" & year == 2020 & cbsa_low_inc_increase == 0

    local zip_total = r(N)

    qui count if counterfactual == "fed_9usd" & year == 2020 & cbsa_low_inc_increase == 0 & /// 
       no_direct_treatment == 1

    local zip_no_treat = r(N)

    local zip_notr_pct = 100*`zip_no_treat' / `zip_total'
	
    qui count if counterfactual == "fed_9usd" & year == 2019 & cbsa_low_inc_increase == 0 & /// 
       no_direct_treatment == 0 & statutory_mw == 7.25
	   
    local zip_bound = r(N)
	
    local zip_bound_pct = 100 * `zip_bound' / `zip_total'
	
    qui sum d_mw_res if counterfactual == "fed_9usd" & year == 2020 & cbsa_low_inc_increase == 0

    local avg_change = 100 * r(mean)

    cap file close f
    file open   f using "../output/autofill_counterfactuals.tex", write replace
    file write  f "\newcommand{\gammaCounterfactual}{\textnormal{"       %5.4f  (`gamma')         "}}" _n
    file write  f "\newcommand{\betaCounterfactual}{\textnormal{"        %5.4f  (`beta')          "}}" _n
    file write  f "\newcommand{\epsilonCounterfactual}{\textnormal{"     %5.4f  (`epsilon')       "}}" _n
    file write  f "\newcommand{\rhoMeanCounterfactual}{\textnormal{"     %4.3f  (`rho_mean')      "}}" _n
    file write  f "\newcommand{\rhoMedianCounterfactual}{\textnormal{"   %4.3f  (`rho_median')    "}}" _n
    file write  f "\newcommand{\zipcodesCounterfactual}{\textnormal{"    %5.0fc (`zip_total')     "}}" _n
    file write  f "\newcommand{\zipNoIncCounterfactual}{\textnormal{"    %5.0fc (`zip_no_treat')  "}}" _n
    file write  f "\newcommand{\zipBoundCounterfactual}{\textnormal{"    %5.0fc (`zip_bound')     "}}" _n
    file write  f "\newcommand{\zipNoIncPctCounterfactual}{\textnormal{" %4.1f  (`zip_notr_pct')  "}}" _n
    file write  f "\newcommand{\zipBoundPctCounterfactual}{\textnormal{" %4.1f  (`zip_bound_pct') "}}" _n
    file write  f "\newcommand{\AvgChangeCounterfactual}{\textnormal{"   %4.1f  (`avg_change')    "}}" _n
    file close  f
end

main
