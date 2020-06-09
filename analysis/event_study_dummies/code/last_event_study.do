clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../temp"
	local outstub "../output"

	local FE "zipcode calendar_month year_month"
	*local controls "unused_event_PRE unused_event_POST"
	*local controls "cum_unused_mw_events"

	foreach window in 12 24 {
		use "`instub'/last_rent_panel_`window'.dta", clear

		foreach depvar in medrentprice_sfcc medrentprice_mfr5plus 					///
		    			medrentprice_2br medrentpricepsqft_sfcc 					///
						medrentpricepsqft_mfr5plus medrentpricepsqft_2br {
			
			create_event_plot, depvar(`depvar') controls(" ") w(`window')	///
				absorb(`FE') cluster(zipcode)
			graph export "`outstub'/last_`depvar'_`window'.png", replace	

			* Unused control 1
			local ctrls "unused_event_POST unused_event_PRE"
			create_event_plot, depvar(`depvar') controls(`ctrls') w(`window')	///
				absorb(`FE') cluster(zipcode)
			graph export "`outstub'/control_unused_events/last_`depvar'_`window'.png", replace

			* Unused control 2
			local ctrls "cum_unused_mw_events"
			create_event_plot, depvar(`depvar') controls(`ctrls') w(`window')	///
				absorb(`FE') cluster(zipcode)
			graph export "`outstub'/control_unused_events_2/last_`depvar'_`window'.png", replace
		}
	}
	
	foreach window in 12 24 {
		use "`instub'/last_listing_panel_`window'.dta", clear

		foreach depvar in medlistingprice_sfcc medlistingprice_low_tier 			///
						medlistingprice_top_tier medlistingpricepsqft_sfcc 			///
						medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier {
		
			create_event_plot, depvar(`depvar') controls(" ") w(`window')	///
				absorb(`FE') cluster(zipcode)
			graph export "`outstub'/last_`depvar'_`window'.png", replace	
		}
	}
end

program create_event_plot
	syntax, depvar(str) controls(str) absorb(str) w(int) cluster(str)

	quietly levelsof year_month
	local num_periods = `r(r)' - `w'

	local w_plus1 = `w' + 1
	local w_span  = 2*`w' + 1
	
	** Omit d_neg1
	local dummy_coeffs  "d_0"
	local keep_coeffs  "d_0"
	forval i = 1(1)`num_periods' {
		if `i'== 1 {
			local dummy_coeffs "`dummy_coeffs' d_`i'"
			local keep_coeffs  "`keep_coeffs' d_`i'"
		}
		else if `i' <= `w' {
			local dummy_coeffs "d_neg`i' `dummy_coeffs' d_`i'"
			local keep_coeffs  "d_neg`i' `keep_coeffs' d_`i'"
		}
		else {
			local dummy_coeffs "`dummy_coeffs' d_neg`i' d_`i'"
		}
	}
	
	reghdfe `depvar' `controls' `dummy_coeffs', nocons absorb(`absorb') vce(cluster `cluster')				
	
	mat B = e(b)
	mat V = e(V)

	mat A = J(`w_span', 3, .)
	mat colnames A = coeff ci_low ci_high

	local j = 1
	forvalues i = 1/`w_span' {
		if `i' == `w' {
			mat A[`i', 1] = 0
			mat A[`i', 2] = 0
			mat A[`i', 3] = 0
		}
		else {
			mat A[`i', 1] = B[1, `j']
			mat A[`i', 2] = B[1, `j'] - 1.96*(V[`j', `j']^.5)
			mat A[`i', 3] = B[1, `j'] + 1.96*(V[`j', `j']^.5)

			local j = `j' + 1
		}
	}

	mat tA = A'

	coefplot matrix(tA[1]), vertical ci((tA[2] tA[3])) 					///
		graphregion(color(white)) bgcolor(white)						///
		xlabel(1 "-`w'" `w_plus1' "0" `w_span' "`w'")					///
		xline(0, lcol(grey) lpat(dot)) name(`name') title(`title')
end

main
