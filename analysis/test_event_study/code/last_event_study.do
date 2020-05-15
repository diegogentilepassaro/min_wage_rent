clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main    
    es_tests, data(rent) window(6) depvar(medrentpricepsqft_sfcc)
    es_tests, data(listing) window(6) depvar(medlistingpricepsqft_sfcc)
	
	graph drop _all
    es_tests, data(rent) window(12) depvar(medrentpricepsqft_sfcc)
    es_tests, data(listing) window(12) depvar(medlistingpricepsqft_sfcc)
end

program es_tests
syntax, data(str) window(int) depvar(str) 
    use "../temp/baseline_`data'_panel_`window'.dta", clear
    create_event_plot, depvar(`depvar')                   ///
        event_var(last_sal_mw_event_rel_months`window') ///
        controls(" ") window(`window')    ///
        absorb(zipcode year_month) cluster(zipcode) ///
        name(`data') ///
        title("Two-way FE", size(tiny))

    create_event_plot, depvar(`depvar')                   ///
        event_var(last_sal_mw_event_rel_months`window') ///
        controls(" ") window(`window')    ///
        absorb(zipcode year_month calendar_month) cluster(zipcode) ///
        name(`data'_cal) ///
        title("Two-way FE and calendar-month", size(tiny))
        
    create_event_plot, depvar(`depvar')                   ///
        event_var(last_sal_mw_event_rel_months`window') ///
        controls(" ") window(`window')    ///
        absorb(zipcode year_month calendar_month##statefips) cluster(zipcode) ///
        name(`data'_calstate) ///
        title("Two-way FE and state-specific calendar-month", size(tiny))
        
    create_event_plot, depvar(`depvar')                   ///
        event_var(last_sal_mw_event_rel_months`window') ///
        controls(" ") window(`window')    ///
        absorb(zipcode year_month calendar_month##countyfips) cluster(zipcode) ///
        name(`data'_calcounty) ///
        title("Two-way FE and county-specific calendar-month", size(tiny))

    create_event_plot, depvar(`depvar')                   ///
        event_var(last_sal_mw_event_rel_months`window') ///
        controls(i.cumul_nbr_unused_mw_events) window(`window')    ///
        absorb(zipcode year_month calendar_month##countyfips) cluster(zipcode) ///
        name(`data'_unus_calcounty) ///
        title("Two-way FE county-specific calendar-month and number unused events FE", size(tiny))

    create_event_plot, depvar(`depvar')                   ///
        event_var(last_sal_mw_event_rel_months`window') ///
        controls(i.cumul_nbr_unused_mw_events) window(`window')    ///
        absorb(zipcode msa year_month calendar_month##countyfips) cluster(zipcode) ///
        name(`data'_unus_msa_calcounty) ///
        title("Two-way FE msa FE county-specific calendar-month and number unused events FE", size(tiny))
        
    create_event_plot, depvar(`depvar')                   ///
        event_var(last_sal_mw_event_rel_months`window') ///
        controls(i.cumul_nbr_unused_mw_events) window(`window')    ///
        absorb(zipcode msa year_month##statefips calendar_month##countyfips) cluster(zipcode) ///
        name(`data'_unus_msa_calcounty_stime) ///
        title("Zipcode FE msa FE county-specific calendar-month state-specific time FE and number unused events FE", size(tiny))
        
    create_event_plot, depvar(`depvar')                   ///
        event_var(last_sal_mw_event_rel_months`window') ///
        controls(i.cumul_nbr_unused_mw_events) window(`window')    ///
        absorb(zipcode msa year_month##countyfips calendar_month##countyfips) cluster(zipcode) ///
        name(`data'_unus_msa_calcounty_ctime) ///
        title("Zipcode FE msa FE county-specific calendar-month county-specific time FE and number unused events FE", size(tiny))

    graph combine `data' `data'_cal `data'_calstate `data'_calcounty ///
        `data'_unus_calcounty `data'_unus_msa_calcounty ///
        `data'_unus_msa_calcounty_stime `data'_unus_msa_calcounty_ctime, ///
         xsize(20) ysize(10) row(2) col(4) ycommon graphregion(color(white))
    graph export "../output/`data'_`window'_the_FEs_limit.png", replace
end

main
