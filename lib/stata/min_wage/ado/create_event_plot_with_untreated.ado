program create_event_plot_with_untreated
	syntax [if], depvar(str) event_var(str) controls(str) absorb(str) 			///
		window(int) cluster(str) [* name(str) title(str) ytitle(str) yaxis(str)]

	local window_plus1 = `window' + 1
	local window_span = 2*`window' + 1

	local rel_time_dummies "i0.`event_var'#1.treated"
	forvalues i = 1(1)`window_span' {
		if `i' != `window' {
			local rel_time_dummies "`rel_time_dummies' i`i'.`event_var'#1.treated"
		}
	}
	local rel_time_dummies "`rel_time_dummies' i1000.`event_var'#1.treated"

	reghdfe `depvar' `rel_time_dummies' `controls' `if', nocons 	///
		absorb(`absorb') vce(cluster `cluster')				
	
	mat B = e(b)
	mat V = e(V)

	mat A = J(`window_span', 3, .)
	mat colnames A = coeff ci_low ci_high

	local j = 1
	forvalues i = 1(1)`window_span' {
		if `i' == `window' {
			mat A[`i', 1] = 0
			mat A[`i', 2] = 0
			mat A[`i', 3] = 0
		}
		else {
			mat A[`i', 1] = B[1, `j'+1]
			mat A[`i', 2] = B[1, `j'+1] - 1.96*(V[`j'+1, `j'+1]^.5)
			mat A[`i', 3] = B[1, `j'+1] + 1.96*(V[`j'+1, `j'+1]^.5)

			local j = `j' + 1
		}
	}
	mat tA = A'

	coefplot matrix(tA[1]), vertical ci((tA[2] tA[3])) 						///
		graphregion(color(white)) bgcolor(white)							///
		xlabel(1 "-`window'" `window_plus1' "0" `window_span' "`window'")	///
		xline(0, lcol(grey) lpat(dot)) 										///
		name(`name') title(`title') ytitle(`ytitle') `yaxis'
end
