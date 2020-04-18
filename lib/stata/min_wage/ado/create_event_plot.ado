program create_event_plot
	syntax, depvar(str) event_var(str) controls(str) absorb(str) ///
	    window(int) cluster(str) [* name(str) title(str)]

	local window_plus1 = `window' + 1
	local window_span = 2*`window' + 1

	
	forval i = 1(1)`window_span' {
		local keep_coeffs = "`keep_coeffs'" + " `i'.`event_var'"
	}

	reghdfe `depvar' ib`window'.`event_var' `controls' `if', nocons ///
		absorb(`absorb') vce(cluster `cluster')				
	
	coefplot, keep(`keep_coeffs') ///
		base vertical graphregion(color(white)) bgcolor(white) ///
		xlabel(1 "-`window'" `window_plus1' "0" `window_span' "`window'") ///
		xline(`window_plus1', lcol(grey) lpat(dot)) name(`name') title(`title')
end

