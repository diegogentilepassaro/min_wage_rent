cap program drop estimate_twfe_model
program estimate_twfe_model 
    syntax [if], yvar(str) xvars(str) controls(str)         ///
                 absorb(str) cluster(str) model_name(str)  ///
                 [outfolder(str)]

    if "`outfolder'"==""{
        local outfolder "../output"
    }

    preserve
    di 1
        reghdfe `yvar' `xvars' `controls' `if', ///
            absorb(`absorb') vce(cluster `cluster') nocons
di 2
        ** Model diagnostics
        local N         = e(N)
        local r2        = e(r2)
        local r2_within = e(r2_within)

        estimate save "../temp/estimates.dta", replace
        
        ** Build basic results
        coefplot, vertical base gen
        keep __at __b __se
        rename (__at __b __se) (at b se)
        
        local i = 1
        foreach var in `xvars' {
            gen var = "`var'" if at == `i'
            local i = `i' + 1
        }
        keep if at <= `i' - 1 // Keep xvars only, drop controls
        drop at
        
        gen model     = "`model_name'"
        gen N         = `N'
        gen r2        = `r2'
        gen r2_within = `r2_within'
        

        order model var b se

        save             "`outfolder'/estimates_`model_name'.dta", replace
        export delimited "`outfolder'/estimates_`model_name'.csv", replace
    restore
end 
