clear all
set more off
set maxvar 32000
set scheme s2color, permanently

program main
    local in_large "../../../drive/analysis_large/counterfactuals"
    local in_wages "../../twfe_wages/output"
    local in_zip   "../../../drive/derived_large/zipcode"

    import delimited "../output/tot_incidence_var_epsilon.csv", clear

    rename counterfactual cofa
    replace epsilon = round(epsilon, .001)
    gen base = (epsilon > .099) & (epsilon < 0.101)

    twoway (line    tot_incidence epsilon if cofa == "fed_9usd",             lcol(navy))    ///
           (line    tot_incidence epsilon if cofa == "chi14",                lcol(maroon))  ///
           (scatter tot_incidence epsilon if cofa == "fed_9usd" & base == 1, mcol(navy))    ///
           (scatter tot_incidence epsilon if cofa == "chi14"    & base == 1, mcol(maroon)), ///
        xtitle("Elasticity of wage income to the minimum wage") xline(0.1, lpat(dash) lcol(gray)) ///
        ytitle("Total share pocketed by landlords")                                         ///
        ylabel(0.06(0.03)0.19) xlabel(0.06(0.02)0.14)                                       ///
        graphregion(color(white)) bgcolor(white)                                            ///
        legend(order(1 "Federal MW" 2 "Chicago city MW"))
            
    graph export "../output/incidence_by_epsilon_png.png", width(2221) height(1615) replace
    graph export "../output/incidence_by_epsilon.eps", replace
end


main
