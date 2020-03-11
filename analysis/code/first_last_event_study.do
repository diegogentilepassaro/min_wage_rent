clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado
adopath + ../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	use `instub'data_ready.dta, clear

	prepare_data, time_var(year_month) geo_unit(zipcode)

	foreach var in min_event {
		foreach window in 12 24 {
			create_latest_event_vars, event_dummy(`var') window(`window')                         ///
			    time_var(year_month) geo_unit(zipcode)

			create_event_plot, depvar(rent2br_median) event_var(last_`var'_rel_months`window')      ///
			    controls(" ") window(`window') ///
				absorb(zipcode calendar_month year_month)

			create_event_plot, depvar(rent2br_psqft_median) event_var(last_`var'_rel_months`window')      ///
			    controls(" ") window(`window') ///
				absorb(zipcode calendar_month year_month)

			create_event_plot, depvar(zhvi2br) event_var(last_`var'_rel_months`window')      ///
			    controls(" ") window(`window') ///
				absorb(zipcode msa calendar_month year_month)
		}
	}
end

program prepare_data
    syntax, time_var(str) geo_unit(str)

    gen date = dofm(year_month)
	gen calendar_month = month(date)
	drop date
	
	replace min_event = 0 if dmin_actual_mw < 0.25
	replace mean_event = 0 if dmean_actual_mw < 0.25
	replace max_event = 0 if dmax_actual_mw < 0.25

	drop if missing(msa)
	
	keep zipcode year_month state msa calendar_month ///
	    zhvi2br rent2br_median rent2br_psqft_median ///
		min_event mean_event max_event
end

program create_latest_event_vars
	syntax, event_dummy(str) window(int) time_var(str) geo_unit(str) [min_option(str)]
	
	local window_span = `window'*2 + 1 
	
	gen `event_dummy'_`time_var' = `time_var' if `event_dummy' == 1
	format `event_dummy'_`time_var' %tm
	
	bysort `geo_unit': egen last_`event_dummy'_`time_var' = max(`event_dummy'_`time_var')
	gen last_`event_dummy'_rel_months`window' = `time_var' - last_`event_dummy'_`time_var'
	replace last_`event_dummy'_rel_months`window' = last_`event_dummy'_rel_months`window' + `window' + 1
	replace last_`event_dummy'_rel_months`window' = 0 ///
	    if last_`event_dummy'_rel_months`window' <= 0
	replace last_`event_dummy'_rel_months`window' = 1000 ///
	    if last_`event_dummy'_rel_months`window' > `window_span'
		
	drop `event_dummy'_`time_var' last_`event_dummy'_`time_var'
end

program create_event_plot
	syntax, depvar(str) event_var(str) controls(str) absorb(str) window(int)

	local window_plus1 = `window' + 1
	local window_span = 2*`window' + 1

	forval i = 1(1)`window_span' {
		local keep_coeffs = "`keep_coeffs'" + " `i'.`event_var'"
	}

	reghdfe `depvar' ib`window'.`event_var' `controls', nocons ///
	    absorb(`absorb') vce(cluster zipcode)
	
	coefplot, keep(`keep_coeffs') ///
		base vertical graphregion(color(white)) bgcolor(white) ///
		xlabel(1 "-`window'" `window_plus1' "0" `window_span' "`window'") ///
		xline(`window_plus1', lcol(grey) lpat(dot))
	graph export ../output/`depvar'_`event_var'.png, replace	
end

main
