cap program drop estimate_dist_lag_model_two_dyn
program estimate_dist_lag_model_two_dyn 
    syntax [if], depvar(str) dyn_var1(str) dyn_var2(str)        ///
        controls(str) absorb(str) cluster(str) model_name(str) ///
        [wgt(str) ab test_equality outfolder(str) w(int 6)]

    if "`outfolder'"==""{
        local outfolder "../output"
    }

    if "`wgt'"=="" {
        local wgtsyntax ""
    } 
    else {
        local wgtsyntax "[pw=`wgt']"
    }

    if "`controls'"==" " {
        local contlist ""
    }
    else {
        local contlist "D.(`controls')"
    }

    preserve

        reghdfe D.`depvar' L(-`w'/`w').D.`dyn_var1' L(-`w'/`w').D.`dyn_var2' ///
                `contlist' `wgtsyntax' `if', absorb(`absorb') ///
                vce(cluster `cluster') nocons                     

        ** Model diagnostics
        local N  = e(N)
        local r2 = e(r2)

        if "`test_equality'"!="" {
            test D.`dyn_var1' = D.`dyn_var2'
            local p_equality = r(p)
        }

        if `w' > 0 {
            forvalues i = 1(1)`w'{
                local pretrend_test " `pretrend_test' (F`i'D.`dyn_var1' = 0)"
            }
            test `pretrend_test'
            local p_pretrend = r(p)
        }

        estimate save "../temp/estimates.dta", replace
        
        ** Build basic results
        qui coefplot, vertical base gen
        keep __at __b __se
        rename (__at __b __se) (at b se)

        local winspan = 2*`w' + 1
        keep if _n <= 2*`winspan'
        keep if !missing(at)
        gen var     = "`dyn_var1'"   if _n <= `winspan'
        replace var = "`dyn_var2'"   if _n > `winspan'
        replace at  = at - (`w' + 1) if var == "`dyn_var1'"
        replace at  = at - (`w' + 1)  - `winspan' if var == "`dyn_var2'"

        gen model = "`model_name'"
        gen N     = `N'
        gen r2    = `r2'
        if "`test_equality'"!="" {
            gen p_equality = `p_equality'
        }        
        if `w'>0 {
            gen p_pretrend = `p_pretrend'
        }

        order  model var  at b se
        gsort  model -var at b se

        save             "`outfolder'/estimates_`model_name'.dta", replace
        export delimited "`outfolder'/estimates_`model_name'.csv", replace
    restore
end 
