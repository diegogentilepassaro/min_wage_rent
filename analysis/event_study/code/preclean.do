clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/output"
    local outstub "../temp"
    local logfile "../output/data_file_manifest.log"

    foreach data in rent listing {
        foreach w in 6 12 {
            use "`instub'/baseline_`data'_panel.dta", clear
            
            create_latest_event_vars, event_dummy(sal_mw_event) w(`w')            ///
                time(year_month) geo(zipcode) panel_end(2019m12)

            create_vars, log_vars(actual_mw med`data'pricepsqft_sfcc med`data'price_sfcc)
            simplify_varnames, data(`data')

            save_data "`outstub'/baseline_`data'_panel_`w'.dta",                  ///
                key(zipcode year_month) replace log(`logfile')
        }
    }
end

program create_latest_event_vars
    syntax, event_dummy(str) w(int) time(str) geo(str) panel_end(str)
    
    local window_span = `w'*2 + 1 

    gen `event_dummy'_`time' = `time' if `event_dummy' == 1
    format `event_dummy'_`time' %tm

    gen months_until_panel_ends = `=tm(`panel_end')' - `time'

    preserve
        keep if months_until_panel_ends >= (`w' + 1)
        collapse (max) last_`event_dummy'_`time' = `event_dummy'_`time', by(`geo')

        format last_`event_dummy'_`time' %tm
        keep `geo' last_`event_dummy'_`time'

        save_data "../temp/last_event`w'_by_`geo'.dta", key(`geo') replace
    restore
    
    merge m:1 `geo' using "../temp/last_event`w'_by_`geo'.dta",                  ///
        nogen assert(3) keep(3)
    
    gen last_`event_dummy'_rel_months`w' = `time' - last_`event_dummy'_`time'
    replace last_`event_dummy'_rel_months`w' = last_`event_dummy'_rel_months`w' + `w' + 1
    
    gen treated = !missing(last_`event_dummy'_rel_months`w')

    replace last_`event_dummy'_rel_months`w' = 0                                /// 0 is pre-period
                if last_`event_dummy'_rel_months`w' <= 0 & treated
    replace last_`event_dummy'_rel_months`w' = 1000                             /// 1000 is post-period
                if last_`event_dummy'_rel_months`w' > `window_span' & treated
    replace last_`event_dummy'_rel_months`w' = 5000    if !treated              /// 5000 means never treated
                

    gen unused_mw_event`w' = (mw_event == 1 & last_`event_dummy'_rel_months`w' != (`w' + 1))
    bysort `geo' (`time'): gen cumsum_unused_events = sum(unused_mw_event`w')
    
    drop `event_dummy'_`time' last_`event_dummy'_`time'
end

program create_vars
    syntax, log_vars(str)

    foreach var in `log_vars' {
        gen ln_`var' = ln(`var')
    }
end

program simplify_varnames
    syntax, data(str)
    
    local marker "rent"
    if "`data'" == "listing" {
        local marker "houseprice"
    }

    rename  (ln_actual_mw  ln_med`data'pricepsqft_sfcc  ln_med`data'price_sfcc)  ///
            (ln_mw         ln_`marker'_psqft            ln_`marker')

end

main
