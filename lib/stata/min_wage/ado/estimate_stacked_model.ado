cap program drop estimate_stacked_model
program estimate_stacked_model 
    syntax [if], depvar(str) mw_var1(str) mw_var2(str) ///
        absorb(str) cluster(str) model_name(str) ///
        [controls(str) wgt(str) outfolder(str)]

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
        reghdfe `depvar' `mw_var1' `mw_var2' `controls' `wgtsyntax' `if', ///
            absorb(`absorb') cluster(`cluster') nocons

        ** Model diagnostics
        local N  = e(N)
        local r2 = e(r2)
        
        if "`mw_var1'" != "`mw_var2'" {
        	test `mw_var1' = `mw_var2'
            local p_equality = r(p)
        }

         ** Build basic results
        qui coefplot, vertical base gen
        keep __at __b __se
        rename (__at __b __se) (at b se)

        estimate save "../temp/estimates.dta", replace
        save "../temp/estimates.dta", replace

        ** Add cumsum
        if "`mw_var1'" == "`mw_var2'" {
            local sum_string   "`mw_var1'"
            local sum_string_b "_b[`mw_var1']"
        }
        else {
            local sum_string   "`mw_var1' + `mw_var2'" 
            local sum_string_b "_b[`mw_var1'] + _b[`mw_var2']" 
        }

        lincom `sum_string'

        matrix cumsum = (0, r(estimate), r(se))
        clear
        svmat cumsum
        rename (cumsum1 cumsum2 cumsum3) ///
               (at      b       se)

        gen var = "cumsum_from0"
        save "../temp/estimates_cumsum_from0.dta", replace
       
        ** Put everything together
        use "../temp/estimates.dta", clear

        if "`mw_var1'" == "`mw_var2'" {
            keep if _n <= 1
        }
        else {
            keep if _n <= 2
        }
        keep if !missing(at)
        gen var     = "`mw_var1'"    if _n == 1
        replace var = "`mw_var2'"   if _n == 2
        replace at  = 0
        append using "../temp/estimates_cumsum_from0.dta"

        gen model = "`model_name'"
        gen N     = `N'
        gen r2    = `r2'
        if ("`mw_var1'" != "`mw_var2'") {
            gen p_equality = `p_equality'
        }

        order  model var  at b se
        gsort  model -var at b se

        save             "`outfolder'/estimates_`model_name'.dta", replace
        export delimited "`outfolder'/estimates_`model_name'.csv", replace
    restore
end 
