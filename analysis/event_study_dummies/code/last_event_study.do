clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../temp"
	local outstub "../output"

	local FE "zipcode year_month#statefips"
    local window = 6
	
	use "`instub'/last_rent_panel_`window'.dta", clear

	*drop_zipcodes_without_event, geo(zipcode) time(year_month)

	foreach depvar in _sfcc psqft_sfcc {
					  *  _sfcc _mfr5plus _2br psqft_sfcc psqft_mfr5plus psqft_2br {
		
		create_event_plot, depvar(medrentprice`depvar') w(`window')				///
			 controls(" ") absorb(`FE') cluster(zipcode)
		graph export "`outstub'/last_rent`depvar'_w`window'.png", replace	

		* Unused control
		create_event_plot, depvar(medrentprice`depvar') w(`window')				///
			controls("i.cum_unused_mw_events")  absorb(`FE') cluster(zipcode)
		graph export "`outstub'/control_unused_events/last_rent`depvar'_w`window'_unused-cumsum.png", replace
	}
	
	use "`instub'/last_listing_panel_`window'.dta", clear

	*drop_zipcodes_without_event, geo(zipcode) time(year_month)

	foreach depvar in _sfcc psqft_sfcc {
						* _sfcc _low_tier _top_tier psqft_sfcc psqft_low_tier psqft_top_tier {
	
		create_event_plot, depvar(medlistingprice`depvar') controls(" ") w(`window')	///
			absorb(`FE') cluster(zipcode)
		graph export "`outstub'/last_listing`depvar'_w`window'.png", replace	
	}
end

program drop_zipcodes_without_event
	syntax, geo(str) time(str)

	bysort `geo' (`time'): egen some_event_in_zip = max(d_0)

	keep if some_event_in_zip

	drop some_event_in_zip
end

program create_event_plot
	syntax, depvar(str) controls(str) absorb(str) w(int) cluster(str)

	qui ds
	loc last_dummy: word `c(k)' of `r(varlist)'

	local w_plus1 = `w' + 1
	local w_span  = 2*`w' + 1
	
	** Omit d_neg1
	local dummy_coeffs  "d_0"
	local keep_coeffs  "d_0"
	forval i = 1(1)`w' {
		if `i'== 1 {
			local dummy_coeffs "`dummy_coeffs' d_`i'"
		}
		else if `i' <= `w' {
			local dummy_coeffs "d_neg`i' `dummy_coeffs' d_`i'"
		}
		else {
			local dummy_coeffs "`dummy_coeffs' d_neg`i' d_`i'"
		}
	}
	
	reghdfe `depvar' `dummy_coeffs' d_neg`w_plus1'-`last_dummy' `controls', nocons absorb(`absorb') vce(cluster `cluster')				
	
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
