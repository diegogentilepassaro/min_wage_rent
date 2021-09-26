cap program drop estimate_dist_lag_model
program estimate_dist_lag_model 
    syntax [if], depvar(str) dyn_var(str) stat_var(str)        ///
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

        if "`ab'"=="" {
            reghdfe D.`depvar' L(-`w'/`w').D.`dyn_var' D.`stat_var' ///
                    `contlist' `wgtsyntax' `if', absorb(`absorb') ///
                    vce(cluster `cluster') nocons                     
        }
        else {
            ivreghdfe D.`depvar' L(-`w'/`w').D.`dyn_var' D.`stat_var' ///
                    (L.D.`depvar'=L2.D.`depvar') `contlist' `wgtsyntax' `if', absorb(`absorb') ///
                    cluster(`cluster') nocons
        }

        ** Model diagnostics
        local N  = e(N)
        local r2 = e(r2)

        if "`test_equality'"!="" {
            test D.`dyn_var' = D.`stat_var'
            local p_equality = r(p)
        }

        if `w' > 0 {
            forvalues i = 1(1)`w'{
                local pretrend_test " `pretrend_test' (F`i'D.`dyn_var' = 0)"
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
        if "`ab'"=="" {
            keep if _n <= `winspan' + 1
            keep if !missing(at)
            gen var     = "`dyn_var'"    if _n <= `winspan'
            replace var = "`stat_var'"   if _n == `winspan' + 1
            replace at  = at - (`w' + 1)
            replace at  = 0 if _n > `winspan'
            
        }
        else {
            keep if _n <= `winspan' + 2
            keep if !missing(at)
            gen var     = "`dyn_var'"    
            replace var = "L_`depvar'" if _n == 1
            replace var = "`stat_var'"   if _n == `winspan' + 2
            replace at  = at - 1 if _n==1
            replace at  = at - (`w' + 2) if _n>1
            replace at  = 0 if _n > `winspan' + 1
        }
        

        save "../temp/estimates_`model_name'.dta", replace
        
        ** Add cumsum
        estimate use "../temp/estimates.dta"

        if "`dyn_var'" == "`stat_var'" {
            local sum_string "D.`stat_var'"
            local sum_string_b "_b[D.`stat_var']"
        }
        else {
            local sum_string "D.`stat_var' + D.`dyn_var'" 
            local sum_string_b "_b[D.`stat_var'] + _b[D.`dyn_var']" 
        }
        lincom `sum_string'

        matrix cumsum = (0, r(estimate), r(se))

        if `w' > 0 {
            forval t = 1(1)`w'{
                estimate use "../temp/estimates.dta"
                local sum_string "`sum_string' + L`t'.D.`dyn_var'"
                local sum_string_b "`sum_string_b' + _b[L`t'.D.`dyn_var']"
                lincom `sum_string'
                matrix cumsum = (matrix(cumsum) \ `t', r(estimate), r(se))
            }
            matrix cumsum = (matrix(cumsum) \ -1, 0, 0)
            if "`ab'"!="" {
                estimate use "../temp/estimates.dta"
                di "`sum_string'"
                nlcom (`sum_string_b')/(1 - _b[LD.`depvar'])
                mat AB_b = r(b)
                mat AB_V = r(V)
                matrix cumsum = (matrix(cumsum) \ `w', AB_b[1,1], AB_V[1,1])
            }
        }
        clear

        svmat cumsum
        rename (cumsum1 cumsum2 cumsum3) ///
               (at      b       se)

        gen var = "cumsum_from0"
        if "`ab'"!="" & `w'>0 {
            replace var = "AB_longrun_from0" if _n==_N
        }
        save "../temp/estimates_`model_name'_sumsum_from0.dta", replace

        ** Put everything together
        use "../temp/estimates_`model_name'.dta", clear
        append using "../temp/estimates_`model_name'_sumsum_from0.dta"

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

        if "`dyn_var'"=="`stat_var'" {
            drop if b == 0 & se == 0 & at != -1
        }

        save             "`outfolder'/estimates_`model_name'.dta", replace
        export delimited "`outfolder'/estimates_`model_name'.csv", replace
    restore
end 
