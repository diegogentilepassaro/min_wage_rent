clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/od_shares"

    foreach geo in county zipcode {
        import delimited "`instub'/`geo'_shares.csv", clear
        
        plot_density, var(`geo')

        graph export "../output/shares_`geo'.png"
        graph export "../output/shares_`geo'.eps"
    }
end


program plot_density
    syntax, var(str) 

    if "`var'" == "countyfips"  local var_title "County"
    if "`var'" == "zipcode" local var_title "ZIP code"

    twoway (kdensity sh_work_samegeo)                       ///
           (kdensity sh_work_samegeo_lowinc),               ///
        xtitle("Share who work in same `var_title'")           ///
        legend(order(1 "Total workers" 2 "Low-wage workers"))  ///
        graphregion(color(white)) bgcolor(white)
end


main
