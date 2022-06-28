clear all
set more off
set maxvar 32000

program main
    local in_data        "../output"
    local in_baseline    "../../fd_baseline/output"
    local in_wages     "../../twfe_wages/output"
    local out_autofill   "../output"

    load_parameters, in_baseline(`in_baseline') in_wages(`in_wages')
    local beta    = r(beta)
    local gamma   = r(gamma)
    local epsilon = r(epsilon)

    import delimited `in_data'/tot_incidence.csv, clear
    qui sum tot_incidence if counterfactual == "fed_9usd"
	local tot_inc_fed_9usd = r(mean)
	qui sum tot_incidence if counterfactual == "chi14"
    local tot_inc_chi14 = r(mean)

    use `in_data'/data_counterfactuals.dta, clear

    make_autofill_values, beta(`beta') gamma(`gamma') epsilon(`epsilon') ///
	    tot_inc_fed_9usd(`tot_inc_fed_9usd') tot_inc_chi14(`tot_inc_chi14')

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

program make_autofill_values
    syntax, gamma(real) beta(real) epsilon(real) tot_inc_fed_9usd(real) tot_inc_chi14(real)

    cap file close f
    file open   f using "../output/autofill_counterfactuals.tex", write replace
    file write  f "\newcommand{\gammaCf}{\textnormal{"                    %5.4f  (`gamma')           "}}" _n
    file write  f "\newcommand{\betaCf}{\textnormal{"                     %5.4f  (`beta')            "}}" _n
    file write  f "\newcommand{\epsilonCf}{\textnormal{"                  %5.4f  (`epsilon')         "}}" _n

    foreach cf in "fed_9usd" "chi14" {

        if "`cf'" == "fed_9usd" {
            local cfname "FedNine"
            local char1 = 5
            local char2 = 5
            local char3 = 5
            local char4 = 4
            local char5 = 3.1
			local tot_inc = `tot_inc_fed_9usd'
        }
        else if "`cf'" == "chi14" {
            local cfname "Chic"
            local char1 = 3
            local char2 = 2
            local char3 = 1
            local char4 = 3
            local char5 = 4.3
			local tot_inc = `tot_inc_chi14'
        }

        preserve
            local tot_inc_cents = `tot_inc'*100
            
            qui tab cbsa if cbsa_low_inc_increase == 1 & counterfactual == "`cf'"
            local cbsa_low_inc = r(r)

            keep if counterfactual == "`cf'" & cbsa_low_inc_increase == 0
            gen nonmiss_cond = !missing(s_imputed) & !missing(perc_incr_rent)  ///
                & !missing(perc_incr_wagebill)

            qui sum rho if nonmiss_cond == 1, d

            local rho_median    = r(p50)
            local rho_med_cents = r(p50)*100

            qui sum rho if nonmiss_cond == 1 & year == 2020 & no_direct_treatment == 0, d
            local rho_meddir_cent = 100 * r(p50)

            qui sum rho if nonmiss_cond == 1 & year == 2020 & no_direct_treatment == 1, d
            local rho_medind_cent = 100 * r(p50)

            qui count if nonmiss_cond == 1 & year == 2020
            local zip_total = r(N)

            qui count if nonmiss_cond == 1 & year == 2020 & no_direct_treatment == 1
            local zip_no_treat = r(N)
            local zip_notr_pct = 100*`zip_no_treat'/`zip_total'

            qui count if nonmiss_cond == 1 & year == 2020 & no_direct_treatment == 0
            local zip_treat    = r(N)
            local zip_tr_pct   = 100*`zip_treat'/`zip_total'

            qui count if year == 2019 & no_direct_treatment == 0 & statutory_mw == 7.25
            local zip_bound     = r(N)    
            local zip_bound_pct = 100*`zip_bound'/`zip_total'

            qui sum d_mw_res if nonmiss_cond == 1, d
            local avg_change_mw_res = 100 * r(mean)
            local med_change_mw_res = 100 * r(p50)

            qui sum d_mw_wkp if nonmiss_cond == 1, d
            local avg_change_mw_wkp = 100 * r(mean)
            local med_change_mw_wkp = 100 * r(p50)

            file write  f "\newcommand{\totIncidence`cfname'}{\textnormal{"        %4.3f        (`tot_inc')         "}}" _n
            file write  f "\newcommand{\totIncidenceCents`cfname'}{\textnormal{"   %3.1f        (`tot_inc_cents')   "}}" _n
            file write  f "\newcommand{\rhoMedian`cfname'}{\textnormal{"           %4.3f        (`rho_median')      "}}" _n
            file write  f "\newcommand{\rhoMedianCents`cfname'}{\textnormal{"      %1.0f        (`rho_med_cents')   "}}" _n
            file write  f "\newcommand{\rhoMedCentsIndir`cfname'}{\textnormal{"    %4.1f        (`rho_medind_cent') "}}" _n
            file write  f "\newcommand{\rhoMedCentsDir`cfname'}{\textnormal{"      %`char4'.1f  (`rho_meddir_cent') "}}" _n
            file write  f "\newcommand{\zipcodes`cfname'}{\textnormal{"            %`char1'.0fc (`zip_total')       "}}" _n
            file write  f "\newcommand{\zipNoInc`cfname'}{\textnormal{"            %`char1'.0fc (`zip_no_treat')    "}}" _n
            file write  f "\newcommand{\zipInc`cfname'}{\textnormal{"              %`char2'.0fc (`zip_treat')       "}}" _n
            file write  f "\newcommand{\zipBound`cfname'}{\textnormal{"            %`char3'.0fc (`zip_bound')       "}}" _n
            file write  f "\newcommand{\zipNoIncPct`cfname'}{\textnormal{"         %4.1f        (`zip_notr_pct')    "}}" _n
            file write  f "\newcommand{\zipIncPct`cfname'}{\textnormal{"           %4.1f        (`zip_tr_pct')      "}}" _n
            file write  f "\newcommand{\zipBoundPct`cfname'}{\textnormal{"         %3.1f        (`zip_bound_pct')   "}}" _n
            file write  f "\newcommand{\AvgChangeMWRes`cfname'}{\textnormal{"      %`char5'f    (`avg_change_mw_res') "}}" _n
            file write  f "\newcommand{\MedChangeMWRes`cfname'}{\textnormal{"      %`char5'f    (`med_change_mw_res') "}}" _n
            file write  f "\newcommand{\AvgChangeMWWkp`cfname'}{\textnormal{"      %`char5'f    (`avg_change_mw_wkp') "}}" _n
            file write  f "\newcommand{\MedChangeMWWkp`cfname'}{\textnormal{"      %`char5'f    (`med_change_mw_wkp') "}}" _n
            file write  f "\newcommand{\cbsaLowInc`cfname'}{\textnormal{"          %2.0f        (`cbsa_low_inc')     "}}" _n

        restore
    }
    file close  f
end

main



