clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
    local instub  "../../../drive/derived_large/output"
    local outstub "../temp"
    local logfile "../output/data_file_manifest.log"
    
    use "`instub'/baseline_rent_panel.dta", clear
    
    create_latest_event_vars, event_dummy(mw_event025) w(6)                    ///
        time(year_month) geo(zipcode) panel_end(2019m12)
    
    create_latest_event_vars, event_dummy(sal_mw_event) w(6)                   ///
        time(year_month) geo(zipcode) panel_end(2019m12)
    
    create_latest_event_vars, event_dummy(mw_event075) w(6)                    ///
        time(year_month) geo(zipcode) panel_end(2019m12)
    
    save_data "`outstub'/baseline_rent_panel_6.dta", key(zipcode year_month)   ///
        replace log(`logfile')
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
    
    merge m:1 `geo' using "../temp/last_event`w'_by_`geo'.dta",                          ///
        nogen assert(3) keep(3)
    
    gen last_`event_dummy'_rel_months`w' = `time' - last_`event_dummy'_`time'
    replace last_`event_dummy'_rel_months`w' = last_`event_dummy'_rel_months`w' + `w' + 1
    
    gen treated_`event_dummy'_`w' = !missing(last_`event_dummy'_rel_months`w')

    replace last_`event_dummy'_rel_months`w' = 0                                         /// 0 is pre-period
                if last_`event_dummy'_rel_months`w' <= 0 & treated_`event_dummy'_`w'
    replace last_`event_dummy'_rel_months`w' = 1000                                      /// 1000 is post-period
                if last_`event_dummy'_rel_months`w' > `window_span' & treated_`event_dummy'_`w'
    replace last_`event_dummy'_rel_months`w' = 5000    if !treated_`event_dummy'_`w'     /// 5000 means never treated

    gen unused_`event_dummy'_`w' = (mw_event == 1 & last_`event_dummy'_rel_months`w' != (`w' + 1))
    bysort `geo' (`time'): gen c_unused_`event_dummy'_`w' = sum(unused_`event_dummy'_`w')
    
    drop `event_dummy'_`time' last_`event_dummy'_`time' months_until_panel_ends
end

main
