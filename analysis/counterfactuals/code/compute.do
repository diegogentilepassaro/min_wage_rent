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

    gen  no_direct_treatment  = (d_mw_res == 0) ///
        if !missing(s_imputed) & !cbsa_low_inc_increase

    gen  fully_affected       = (no_direct_treatment == 0) ///
        if !missing(s_imputed) & !cbsa_low_inc_increase
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

        qui sum tot_incidence if counterfactual == "fed_9usd"
        local tot_inc = r(mean)

        export delimited "../output/tot_incidence.csv", replace
    restore

    make_autofill_values, beta(`beta') gamma(`gamma') epsilon(`epsilon') tot_inc(`tot_inc')
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
    keep if !missing(s_imputed) & !cbsa_low_inc_increase
    keep if (year == 2020 & month == 1)
    keep zipcode counterfactual change_ln_rents perc_incr_rent ///
        change_ln_wagebill perc_incr_wagebill                  ///
        safmr2br_imputed wage_per_whhld_monthly_imputed

    gen num_terms_ti = safmr2br_imputed*(perc_incr_rent)
    gen denom_terms_ti = wage_per_whhld_monthly_imputed*(perc_incr_wagebill)

    collapse (sum) num_tot_incidence   = num_terms_ti        ///
                   denom_tot_incidence = denom_terms_ti      ///
             (count) N = num_terms_ti, by(counterfactual)

    gen tot_incidence = num_tot_incidence/denom_tot_incidence
end

program make_autofill_values
    syntax, gamma(real) beta(real) epsilon(real) tot_inc(real)

    local tot_inc_cents = `tot_inc'*100

    gen main_cf = counterfactual == "fed_9usd"

    qui sum rho if main_cf & !cbsa_low_inc_increase & year == 2020, detail
	
    local rho_mean      = r(mean)
    local rho_median    = r(p50)
    local rho_med_cents = r(p50)*100

    qui sum rho if main_cf & year == 2020 & cbsa_low_inc_increase == 0 & ///
       no_direct_treatment == 0
    local rho_meandir_cent = 100 * r(mean)

    qui sum rho if main_cf & year == 2020 & cbsa_low_inc_increase == 0 & ///
       no_direct_treatment == 1
    local rho_meanind_cent = 100 * r(mean)
	
    qui count if main_cf & year == 2020 & cbsa_low_inc_increase == 0

    local zip_total = r(N)

    qui count if main_cf & year == 2020 & cbsa_low_inc_increase == 0 & /// 
       no_direct_treatment == 1

    local zip_no_treat = r(N)
    local zip_notr_pct = 100*`zip_no_treat' / `zip_total'
	
    qui count if main_cf & year == 2019 & cbsa_low_inc_increase == 0 & /// 
       no_direct_treatment == 0 & statutory_mw == 7.25
	   
    local zip_bound = r(N)	
    local zip_bound_pct = 100 * `zip_bound' / `zip_total'
	
    qui sum d_mw_res if main_cf & year == 2020 & cbsa_low_inc_increase == 0

    local avg_change = 100 * r(mean)
        

    cap file close f
    file open   f using "../output/autofill_counterfactuals.tex", write replace
    file write  f "\newcommand{\gammaCf}{\textnormal{"                    %5.4f  (`gamma')          "}}" _n
    file write  f "\newcommand{\betaCf}{\textnormal{"                     %5.4f  (`beta')           "}}" _n
    file write  f "\newcommand{\epsilonCf}{\textnormal{"                  %5.4f  (`epsilon')        "}}" _n
    file write  f "\newcommand{\totIncidenceFedNine}{\textnormal{"        %4.3f  (`tot_inc')        "}}" _n
    file write  f "\newcommand{\totIncidenceCentsFedNine}{\textnormal{"   %4.1f  (`tot_inc_cents')  "}}" _n
    file write  f "\newcommand{\rhoMeanFedNine}{\textnormal{"             %4.3f  (`rho_mean')       "}}" _n
    file write  f "\newcommand{\rhoMedianFedNine}{\textnormal{"           %4.3f  (`rho_median')     "}}" _n
    file write  f "\newcommand{\rhoMedianCentsFedNine}{\textnormal{"      %4.0f  (`rho_med_cents')  "}}" _n
    file write  f "\newcommand{\rhoMeanCentsIndirFedNine}{\textnormal{"   %4.1f  (`rho_meanind_cent') "}}" _n
    file write  f "\newcommand{\rhoMeanCentsDirFedNine}{\textnormal{"     %4.1f  (`rho_meandir_cent') "}}" _n
    file write  f "\newcommand{\zipcodesFedNine}{\textnormal{"            %5.0fc (`zip_total')      "}}" _n
    file write  f "\newcommand{\zipNoIncFedNine}{\textnormal{"            %5.0fc (`zip_no_treat')   "}}" _n
    file write  f "\newcommand{\zipBoundFedNine}{\textnormal{"            %5.0fc (`zip_bound')      "}}" _n
    file write  f "\newcommand{\zipNoIncPctFedNine}{\textnormal{"         %4.1f  (`zip_notr_pct')   "}}" _n
    file write  f "\newcommand{\zipBoundPctFedNine}{\textnormal{"         %4.1f  (`zip_bound_pct')  "}}" _n
    file write  f "\newcommand{\AvgChangeFedNine}{\textnormal{"           %4.1f  (`avg_change')     "}}" _n
    file close  f
end

main
