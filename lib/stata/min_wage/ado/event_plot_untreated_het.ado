program event_plot_untreated_het
	syntax [if], depvar(str) event_var(str) controls(str) absorb(str) 			  ///
		window(int) cluster(str) [* name(str) title(str) ytitle(str) yaxis(str)]  ///
		het_char(str)

	local window_plus1 = `window' + 1
	local window_span = 2*`window' + 1

	





end