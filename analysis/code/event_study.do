clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado
adopath + ../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	use ../../derived/output/data_ready.dta, clear

	prepare_data

	/*preserve
	collapse rent2br_median, by(rel_months_min_event)
	
	tset rel_months_min_event
	tsline rent2br_median if rel_months != 1000 ///
	   graphregion(color(white)) bgcolor(white)
	restore*/
	
    areg rent2br_psqft_median ib12.rel_months_min_event ///
        i.calendar_month i.year_month, absorb(zipcode) vce(cluster zipcode)
    
	coefplot, drop(*.year_month *.state 1000.rel_months_min_event _cons) ///
	    base vertical graphregion(color(white)) bgcolor(white)
end

program prepare_data
    gen date = dofm(year_month)
    gen calendar_month = month(date)
	drop date

	create_event_vars, event_dummy(min_event) window(12) ///
	    time_var(year_month) geo_unit(zipcode)
end

program create_event_vars
	syntax, event_dummy(str) window(str) time_var(str) geo_unit(str)
	
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
		
	sort zipcode year_month
end

main
