clear all
set more off
set maxvar 32000
set scheme s2color, permanently

program main
    local in_large "../../../drive/analysis_large/counterfactuals"
    local in_wages "../../twfe_wages/output"
    local in_zip   "../../../drive/derived_large/zipcode"

    foreach cf in fed_9usd chi14 {

        use "`in_large'/data_counterfactuals.dta" ///
            if counterfactual == "`cf'" & year == 2020, clear

        keep if !cbsa_low_inc_increase

        local vars "rho_with_imputed"
        if "`cf'" == "fed_9usd" {
            local vars "d_mw_res d_mw_wkp rho rho_with_imputed"
            local vars "`vars' change_ln_rents change_ln_wagebill s_imputed"
        }

        foreach var of local vars {
            
            get_xlabel, var(`var')
            local x_lab = r(x_lab)
            
            local scale_opts ""
            local lab_opts   ""
            local bin_opt    ""
            if inlist("`var'", "d_mw_res", "d_mw_wkp") {
                local scale_opts "yscale(r(0 60)) xscale(r(0 0.23))"
                local lab_opts   "ylab(0(15)60) xlab(0(0.05)0.2)"
                local bin_opt    "bin(25)"
            }
            if inlist("`var'", "rho", "rho_with_imputed", "change_ln_rents", "change_ln_wagebill") {
                local bin_opt    "bin(30)"
                if !inlist("`var'", "rho", "rho_with_imputed") {
                    local scale_opts "yscale(r(0 40))"
                }
            }
            if inlist("`var'", "s_imputed") {
                local bin_opt    "bin(30)"
                local scale_opts "yscale(r(0 8))"
            }

            hist `var', percent `bin_opt'                                      ///
                xtitle("`x_lab'") ytitle("Percentage") `scale_opts' `lab_opts' ///
                graphregion(color(white)) bgcolor(white)                       ///
                plotregion(margin(b = 1.5))
            
            local filename "../output/hist_`var'_`cf'"
            if inlist("`var'", "s_imputed") {
                local filename "../output/hist_`var'"
            }
            
            graph export "`filename'_png.png", replace width(2221) height(1615)
            graph export "`filename'.eps", replace
        }

        collapse (mean) rho_with_imputed, by(diff_qts)

        twoway (line     rho_with_imputed  diff_qts, lcol(navy))                       ///
               (scatter  rho_with_imputed  diff_qts, mcol(navy)),                      ///
            xtitle("Difference between ch. in wkp. MW and ch. in res. MW (deciles)")   ///
            ytitle("Mean share pocketed by landlords")                                 ///
            xlabel(1(1)10) ylabel(0.06(0.04)0.18)                                      ///
            graphregion(color(white)) bgcolor(white) legend(off)
            
        graph export "../output/deciles_diff_`cf'_png.png", width(2221) height(1615) replace
        graph export "../output/deciles_diff_`cf'.eps", replace
    }
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
    if "`var'"=="rho_with_imputed"   return local x_lab "Share pocketed by landlords"

    if "`var'"=="s_imputed"          return local x_lab "Housing expenditure share"
end


main
