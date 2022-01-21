cap program drop estimate_stacked_model
program estimate_stacked_model 
    syntax [if], depvar(str) res_mw_var(str)    ///
        absorb(str) cluster(str) model_name(str) ///
        [wkp_mw_var(str)  controls(str) wgt(str) outfolder(str)]

    if "`outfolder'"==""{
        local outfolder "../output"
    }

    if "`wgt'"=="" {
        local wgtsyntax ""
    } 
    else {
        local wgtsyntax "[pw=`wgt']"
    }

    preserve
        reghdfe `depvar' `res_mw_var' `wkp_mw_var' `controls' `wgtsyntax' `if', ///
            absorb(`absorb') cluster(`cluster') nocons

        ** Model diagnostics
        local N  = e(N)
        local r2 = e(r2)
        
        if "`wkp_mw_var'" != "" {
        	test `res_mw_var' = `wkp_mw_var'
            local p_equality = r(p)
        }
        estimate save "../temp/estimates.dta", replace
        
        ** Build basic results
        qui coefplot, vertical base gen
        keep __at __b __se
        rename (__at __b __se) (at b se)

        ****

        keep if _n <= 2
        keep if !missing(at)
        gen var     = "`res_mw_var'"    if _n == 1
        replace var = "`wkp_mw_var'"   if _n == 2
        replace at  = 0

        gen model = "`model_name'"
        gen N     = `N'
        gen r2    = `r2'
        if "`wkp_mw_var'" != "" {
            gen p_equality = `p_equality'
        }

        order  model var  at b se
        gsort  model -var at b se

        save             "`outfolder'/estimates_`model_name'.dta", replace
        export delimited "`outfolder'/estimates_`model_name'.csv", replace
    restore
end 
