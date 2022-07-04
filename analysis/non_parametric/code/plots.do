clear all
set more off
set maxvar 32000

program main 
    local instub   "../output"
    local outstub  "../output"
    
    foreach group in month cbsa_month {
        import delimited `instub'/non_par_resid_`group'.csv, clear
    
        foreach mw_var in mw_wkp mw_res {
            make_means, mw_var(`mw_var')
            make_plots, mw_var(`mw_var') group(`group')
        }
    }
    

end

program make_means
    syntax, mw_var(str) 
    
    get_res_name, mw_var(`mw_var')
    local type = r(type)

    xtile qnt_`mw_var' = `mw_var', n(30)
    bys qnt_`mw_var': egen avgrents_`mw_var' = mean(ln_rents)
    bys qnt_`mw_var': egen avgqnt_`mw_var'   = mean(`mw_var')
    
    local varname `mw_var'`type'
    
    xtile qnt_`varname' = `varname', n(30)
    bys qnt_`varname': egen avgrents_`varname' = mean(ln_rents`type')
    bys qnt_`varname': egen avgqnt_`varname'   = mean(`varname')
    
end

program get_res_name, rclass
    syntax, mw_var(str)
    
    if "`mw_var'" == "mw_wkp" {
        local type _resid_mw_res_dec
        local xlab1 "Workplace MW"
        local xlab2 "Workplace MW (residualized)"
    }
    else  {
        local type _resid_mw_wkp_dec
        local xlab1 "Residence MW"
        local xlab2 "Residence MW (residualized)"
    }
    
    return local type `type'
    return local xlab1 `xlab1'
    return local xlab2 `xlab2'

end

program make_plots
    syntax, mw_var(str) group(str) [width(int 2221) height(int 1615)]
   
    get_res_name, mw_var(`mw_var')
    local type  = r(type)
    local xlab1 = r(xlab1)
    local xlab2 = r(xlab2)
    
    twoway (scatter ln_rents `mw_var', mcolor(gray%5)) ///
        (scatter avgrents_`mw_var' avgqnt_`mw_var', mcolor(red%1)), ///
        graphregion(color(white)) bgcolor(white) xtitle(`xlab1') ytitle("Log rents") ///
        legend(off)
        
    graph export "../output/`group'_`mw_var'.png", replace width(`width') height(`height')
    graph export "../output/`group'_`mw_var'.eps", replace
    
    twoway (scatter ln_rents`type' `mw_var'`type', mcolor(gray%5)) ///
        (scatter avgrents_`mw_var'`type' avgqnt_`mw_var'`type', mcolor(red%1)), ///
        xscale(range(-0.1 0.1)) yscale(range(-0.1 0.1)) graphregion(color(white)) ///
        bgcolor(white) xtitle(`xlab2') ytitle("Log rents (residualized)") ///
        legend(off)

    graph export "../output/`group'_`mw_var'`type'.png", replace width(`width') height(`height')
    graph export "../output/`group'_`mw_var'`type'.eps", replace
    
end

main
