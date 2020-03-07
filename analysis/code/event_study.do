clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado
adopath + ../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	use ../../derived/output/data_ready.dta, clear
	gen date = dofm(year_month)
    gen calendar_month = month(date)
	drop date

	local window = 3
	prepare_data, window(`window') event_dummy(min_event)
	create_event_plot, depvar(rent2br_median) rel_event_var(rel_months_min_event`window') ///
	    window(`window')
	create_event_plot, depvar(zhvi2br) rel_event_var(rel_months_min_event`window') ///
	    window(`window')
	
	local window = 6
	prepare_data, window(`window') event_dummy(min_event)
	create_event_plot, depvar(rent2br_median) rel_event_var(rel_months_min_event`window') ///
	    window(`window')
	create_event_plot, depvar(zhvi2br) rel_event_var(rel_months_min_event`window') ///
	    window(`window')

	local window = 12
	prepare_data, window(`window') event_dummy(min_event)
	create_event_plot, depvar(rent2br_median) rel_event_var(rel_months_min_event`window') ///
	    window(`window')
	create_event_plot, depvar(zhvi2br) rel_event_var(rel_months_min_event`window') ///
	    window(`window')
end

program prepare_data
    syntax, window(int) event_dummy(str)

	create_event_vars, event_dummy(`event_dummy') window(`window') ///
	    time_var(year_month) geo_unit(zipcode)
end

program create_event_vars
	syntax, event_dummy(str) window(int) time_var(str) geo_unit(str)
	
	local window_span = 2*`window' + 1
		
	gen `event_dummy'_`time_var' = `time_var' if `event_dummy' == 1
	format `event_dummy'_`time_var' %tm
	bysort `geo_unit' (`time_var'): carryforward `event_dummy'_`time_var', replace

	gen f`window'_`event_dummy'_`time_var' = F`window'.`event_dummy'_`time_var'
	format f`window'_`event_dummy'_`time_var' %tm

	gen rel_months_`event_dummy' = `time_var' - `event_dummy'_`time_var'
    replace rel_months_`event_dummy' = rel_months_`event_dummy' + `window' + 1
	replace rel_months_`event_dummy' = 1000 if rel_months_`event_dummy' > `window_span'

    gen f`window'_rel_months_`event_dummy' = `time_var' - f`window'_`event_dummy'_`time_var' + `window' + 1
	replace rel_months_`event_dummy' = f`window'_rel_months_`event_dummy' ///
	    if rel_months_`event_dummy' == 1000 & inrange(f`window'_rel_months_`event_dummy', 1, `window')

	replace `event_dummy'_`time_var' = f`window'_`event_dummy'_`time_var' ///
	    if inrange(rel_months_`event_dummy', 1, `window')
	replace `event_dummy'_`time_var' = . if rel_months_`event_dummy' == 1000

	bysort `geo_unit' `event_dummy'_`time_var': ///
	    egen min_rel_months_`event_dummy' = min(rel_months_`event_dummy')
	drop if min_rel_months_`event_dummy' == `window' + 1

	drop f`window'_`event_dummy'_`time_var' f`window'_rel_months_`event_dummy' ///
	    min_rel_months_`event_dummy'
	
	rename (rel_months_`event_dummy' `event_dummy'_`time_var') ///
	    (rel_months_`event_dummy'`window' `event_dummy'_`time_var'`window')
	sort zipcode year_month
end

program create_event_plot
    syntax, depvar(str) rel_event_var(str) window(int)

	local window_plus1 = `window' + 1
	local window_span = 2*`window' + 1
	
    areg `depvar' ib`window'.`rel_event_var' ///
        i.calendar_month i.calendar_month#i.state ///
		i.year_month, absorb(zipcode) vce(cluster zipcode)
    
	coefplot, drop(1000.`rel_event_var' *.calendar_month *.calendar_month#*.state *.year_month _cons) ///
	    base vertical graphregion(color(white)) bgcolor(white) ///
		xlabel(1 "-`window'" `window_plus1' "0" `window_span' "`window'") ///
		xline(`window_plus1', lcol(grey) lpat(dot))
	graph export ../output/`depvar'_event_w`window'.png, replace	
end

main
