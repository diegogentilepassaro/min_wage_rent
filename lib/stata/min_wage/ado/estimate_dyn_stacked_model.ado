cap program drop estimate_dyn_stacked_model
program estimate_dyn_stacked_model 
    syntax [if], depvar(str) res_mw_var(str) wkp_mw_var(str)     ///
        absorb(str) cluster(str) model_name(str) ///
        [controls(str) wgt(str) outfolder(str) w(int 6)]

    if "`outfolder'"==""{
        local outfolder "../output"
    }

    if "`wgt'"=="" {
        local wgtsyntax ""
    } 
    else {
        local wgtsyntax "[pw=`wgt']"
    }

    forval i = `w'(-1)1 {
        local leads "`leads' F`i'_`wkp_mw_var'"
    }
    forval i = 1(1)`w' {
        local lags "`lags' L`i'_`wkp_mw_var'"
    }

    preserve
        reghdfe `depvar' `leads' `wkp_mw_var' `lags' `res_mw_var' ///
            `controls' `wgtsyntax' `if', ///
            absorb(`absorb') cluster(`cluster') nocons                   

        ** Model diagnostics
        local N  = e(N)
        local r2 = e(r2)

        test `res_mw_var' = `wkp_mw_var'
        local p_equality = r(p)

        forvalues i = 1(1)`w'{
            local pretrend_test " `pretrend_test' (F`i'_`wkp_mw_var' = 0)"
        }
        test `pretrend_test'
        local p_pretrend = r(p)
        estimate save "../temp/estimates.dta", replace
        
        ** Build basic results
        qui coefplot, vertical base gen
        keep __at __b __se
        rename (__at __b __se) (at b se)

        
        local winspan = 2*`w' + 1
        keep if _n <= `winspan' + 1
        keep if !missing(at)
        gen var     = "`wkp_mw_var'"    if _n <= `winspan'
        replace var = "`res_mw_var'"   if _n == `winspan' + 1
        replace at  = at - (`w' + 1)
        replace at  = 0 if _n > `winspan'

        gen model = "`model_name'"
        gen N     = `N'
        gen r2    = `r2'
        gen p_equality = `p_equality'
        gen p_pretrend = `p_pretrend'

        order  model var  at b se
        gsort  model -var at b se

        save             "`outfolder'/estimates_`model_name'.dta", replace
        export delimited "`outfolder'/estimates_`model_name'.csv", replace
    restore
end 
