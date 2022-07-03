clear all
set more off
set maxvar 32000

program main 
    local instub   "../output"
    local outstub  "../output"
    
    import delimited `instub'/non_par_res.csv
    
    foreach mw_var in mw_wkp mw_res {
       make_means, mw_var(`mw_var')
       make_plots, mw_var(`mw_var')
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
    }
    else  {
        local type _resid_mw_wkp_dec
    }
    
    return local type `type'

end

program make_plots
    syntax, mw_var(str) [width(int 2221) height(int 1615)]
   
    get_res_name, mw_var(`mw_var')
    local type = r(type)
    
    twoway (scatter ln_rents `mw_var', mcolor(%10)) ///
        (scatter avgrents_`mw_var' avgqnt_`mw_var', mcolor(%5))
        
    graph export "../output/month_`mw_var'.png", replace width(`width') height(`height')
    graph export "../output/month_`mw_var'.eps", replace
    
    twoway (scatter ln_rents`type' `mw_var'`type', mcolor(%10)) ///
        (scatter avgrents_`mw_var'`type' avgqnt_`mw_var'`type', mcolor(%5)), ///
        xscale(range(-0.1 0.1)) yscale(range(-0.1 0.1))

    graph export "../output/month_`mw_var'`type'.png", replace width(`width') height(`height')
    graph export "../output/month_`mw_var'`type'.eps", replace
    
end

main
