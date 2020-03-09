clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado
adopath + ../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	use `instub'zipcode_yearmonth_panel.dta, clear

	prepare_data, time_var(year_month) geo_unit(zipcode)

	foreach var in min_event mean_event {
		forvalues window = 6(6)12 {
			create_event_vars, event_dummy(`var') window(`window')                         ///
			    time_var(year_month) geo_unit(zipcode)
			
			create_event_plot, depvar(rent2br_median) event_var(rel_months_`var'`window')      ///
			    controls(" ") absorb(zipcode calendar_month##state year_month year_month##state) window(`window')

			create_event_plot, depvar(rent2br_psqft_median) event_var(rel_months_`var'`window')      ///
			    controls(" ") absorb(zipcode calendar_month##state year_month year_month##state) window(`window')

			create_event_plot, depvar(zhvi2br) event_var(rel_months_`var'`window')             ///
			    controls(" ") absorb(zipcode calendar_month##state year_month year_month##state) window(`window')
		}
	}
	
end

program prepare_data
    syntax, time_var(str) geo_unit(str)

    gen date = dofm(year_month)
	gen calendar_month = month(date)
	drop date
end

program create_event_vars
	syntax, event_dummy(str) window(int) time_var(str) geo_unit(str)
		
	* Diego's approach fixed. Use difference in dates (doesn't exclude overlapping)

	/* gen `event_dummy'_`time_var' = `time_var' if `event_dummy' == 1
	format `event_dummy'_`time_var' %tm
	bysort `geo_unit' (`time_var'): carryforward `event_dummy'_`time_var', replace

	gen rel_months_`event_dummy' = `time_var' - F`window'.`event_dummy'_`time_var'
	replace rel_months_`event_dummy' = 1000 if !inrange(rel_months_`event_dummy', -`window', `window')
	replace rel_months_`event_dummy' = rel_months_`event_dummy' + `window' + 1 if rel_months_`event_dummy' < 1000
	*/

	* Santi's approach. Idenfity "beginning of event" and add 12
	bysort `geo_unit' (`time_var'): gen event_start = 1 if `event_dummy'[_n + `window'] == 1
	gen event_start_non_overlap = event_start
	forvalues i = 2(1)`window' {  						// Set to missing if i days ago there was a mw increase
		bysort `geo_unit' (`time_var'): replace event_start_non_overlap = . if `event_dummy'[_n - `i']
	}
	
	local window_span = 2*`window' + 1
	gen rel_months_`event_dummy' = event_start_non_overlap
	forvalues i = 2(1)`window_span' {  					// Set to i if i days ago an event started 
		bysort `geo_unit' (`time_var'): replace rel_months_`event_dummy' = `i' if event_start_non_overlap[_n - `i' + 1] == 1
	}
	replace rel_months_`event_dummy' = 1000 if rel_months_`event_dummy' == .

	drop event_start event_start_non_overlap
	rename rel_months_`event_dummy' rel_months_`event_dummy'`window'
	sort `geo_unit' `time_var'
end

program create_event_plot
	syntax, depvar(str) event_var(str) controls(str) absorb(str) window(int)

	local window_plus1 = `window' + 1
	local window_span = 2*`window' + 1
	
	reghdfe `depvar' ib`window'.`event_var' `controls', absorb(`absorb') vce(cluster zipcode)
	
	coefplot, drop(1000.`event_var' _cons `controls') 							///
		base vertical graphregion(color(white)) bgcolor(white) 					///
		xlabel(1 "-`window'" `window_plus1' "0" `window_span' "`window'")		///
		xline(`window_plus1', lcol(grey) lpat(dot))
	graph export ../output/`depvar'_`event_var'.png, replace	
end

main
