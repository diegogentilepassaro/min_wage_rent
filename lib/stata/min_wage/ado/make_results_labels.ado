program make_results_labels, rclass
	syntax, w(int)
	
	local estlabels_static `"D.ln_mw "$\Delta \ln \underline{w}_{ict}$""'

	local estlabels `"D.ln_mw "$\Delta \ln \underline{w}_{ic,t}$""'
	local estlabels `"FD.ln_mw "$\Delta \ln \underline{w}_{ic,t-1}$" `estlabels' LD.ln_mw "$\Delta \ln \underline{w}_{ic,t+1}$""'
	forvalues i = 2(1)`w'{
		local estlabels `"F`i'D.ln_mw "$\Delta \ln \underline{w}_{ic,t-`i'}$" `estlabels' L`i'D.ln_mw "$\Delta \ln \underline{w}_{ic,t+`i'}$""'
	}

	return local estlabels_static "`estlabels_static'"
	return local estlabels_dyn "`estlabels'"	
	return local estlabels_with_lagged_y `"`estlabels' LD.ln_med_rent_psqft_sfcc "$\Delta \ln y_{ic,t-1}$""'
end
