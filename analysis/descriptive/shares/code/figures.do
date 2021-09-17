clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../../drive/base_large/lodes"

    foreach geo in county zipcode {
        use "`instub'/`geo'_own_shares.dta", replace
        
        plot_density, var(`geo')

        graph export "../output/shares_`geo'.png"
        graph export "../output/shares_`geo'.eps"
    }
end


program plot_density
    syntax, var(str) 

    if "`var'" == "county"  local var_title "County"
    if "`var'" == "zipcode" local var_title "ZIP code"

    twoway (kdensity share_tot)      ///
           (kdensity share_lowinc),  ///
        xtitle("Share who work in same `var_title'") ///
        legend(order(1 "Total workers" 2 "Low-wage workers")) ///
        graphregion(color(white)) bgcolor(white)
end


main
