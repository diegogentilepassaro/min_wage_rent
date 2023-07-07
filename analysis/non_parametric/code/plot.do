clear all
set more off
set maxvar 32000
set scheme s2color, permanently

program main 
    local instub   "../../../drive/analysis_large/non_parametric"
    local outstub  "../output"
    
    foreach mgroup in cbsa_month {
        import delimited `instub'/non_par_resid_`mgroup'.csv, clear

        foreach mw_var in mw_wkp mw_res {
            make_means, mw_var(`mw_var')

            make_plots, mw_var(`mw_var') mgroup(`mgroup')
        }
    }
end

program get_resid_name, rclass
    syntax, mw_var(str)
    
    if "`mw_var'" == "mw_wkp" {
        local vtype _resid_mw_res_dec
        local xlab1 "Workplace MW"
        local xlab2 "Workplace MW (residualized)"
    }
    else  {
        local vtype _resid_mw_wkp_dec
        local xlab1 "Residence MW"
        local xlab2 "Residence MW (residualized)"
    }

    return local vtype `vtype'
    return local xlab1 `xlab1'
    return local xlab2 `xlab2'
end

program make_means
    syntax, mw_var(str) 

    get_resid_name, mw_var(`mw_var')
    local vtype = r(vtype)

    xtile qnt_`mw_var' = `mw_var', nq(30)
    bys qnt_`mw_var': egen avgrents_`mw_var' = mean(ln_rents)
    bys qnt_`mw_var': egen avgqnt_`mw_var'   = mean(`mw_var')
    
    local varname `mw_var'`vtype'

    xtile qnt_`varname' = `varname', nq(30)
    bys qnt_`varname': egen avgrents_`varname' = mean(ln_rents`vtype')
    bys qnt_`varname': egen avgqnt_`varname'   = mean(`varname')
    
end


program make_plots
    syntax, mw_var(str) mgroup(str)                ///
            [width(int 2221) height(int 1615) xr(real .1) yr(real .05)]

    get_resid_name, mw_var(`mw_var')
    local vtype = r(vtype)
    local xlab1 = r(xlab1)
    local xlab2 = r(xlab2)

    twoway (scatter ln_rents `mw_var',                               ///
                                    mcolor(gray%4) msize(small))     ///
           (scatter avgrents_`mw_var' avgqnt_`mw_var',               ///
                                    mcolor(red%1) msize(small)),     ///
        xtitle(`xlab1') ytitle("Log rents")                          ///
        graphregion(color(white)) bgcolor(white) legend(off) 

    graph export "../output/`mgroup'_`mw_var'_png.png", replace           ///
        width(`width') height(`height')
    graph export "../output/`mgroup'_`mw_var'.pdf", replace

    local xrm = -`xr'
    local yrm = -`yr'
    gen x_range = inrange(`mw_var'`vtype', `xrm', `xr')
    gen y_range = inrange(ln_rents`vtype', `yrm', `yr')
    gen both_r   = x_range*y_range

    twoway (scatter ln_rents`vtype'          `mw_var'`vtype' if both_r, ///
                                        mcolor(gray%4) msize(small))    ///
           (scatter avgrents_`mw_var'`vtype' avgqnt_`mw_var'`vtype' if both_r,    ///
                                        mcolor(red%1)  msize(small)),   ///
        xlab(`xrm'(.05)`xr') ylab(`yrm'(.025)`yr')                      ///
        xtitle(`xlab2') ytitle("Log rents (residualized)")              ///
        bgcolor(white) graphregion(color(white)) legend(off)

    graph export "../output/`mgroup'_`mw_var'`vtype'_png.png", replace       ///
        width(`width') height(`height')
    graph export "../output/`mgroup'_`mw_var'`vtype'.pdf", replace
    
    drop x_range y_range both_r
end

main
