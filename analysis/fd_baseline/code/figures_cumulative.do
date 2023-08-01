clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000
set scheme s2color, permanently

program main
    local instub "../output"

    use "`instub'/estimates_dynamic.dta", replace

    keep if model == "both_mw_wkp_dynamic"

    sum b if var == "mw_wkp_tot_17" & at == 0
    local beta = r(mean)

    sum b if var == "mw_res"
    local gamma = r(mean)

    keep if var == "mw_wkp_tot_17"

    gen     b_cum_onlywkp = 0
    replace b_cum_onlywkp = `beta' if at >= 0
        
    gen     b_cum_both = 0
    replace b_cum_both = `beta' + `gamma' if at >= 0

    twoway   ///
           (line b_cum_onlywkp at, mcol(navy)   msymbol(circle))                     ///
           (line b_cum_both    at, mcol(maroon) msymbol(square)),                    ///
        yline(0, lcol(grey) lpattern(dot))                                           ///
        xlabel(-6(1)6,              labsize(small)) xtitle("")                       ///
        ylabel(-0.04(0.02).1, grid labsize(small)) ytitle("Implied cumulative path") ///
        legend(order(1 `"Only workplace MW"'                                         ///
                    2 `"Both workplace and residence MW"'))                          ///
        graphregion(color(white)) bgcolor(white)
	
    graph export "../output/implied_cumulative_png.png", replace width(2221) height(1615)
    graph export "../output/implied_cumulative.eps",     replace
end


main
