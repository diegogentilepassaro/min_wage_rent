clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	make_results_labels
	local estlabels "`r(estlabels)'"

	horse_race_models, depvar(ln_med_rent_psqft_sfcc) w(5) ///
	    absorb(year_month) cluster(statefips)
	esttab * using "`outstub'/horse_race.tex", compress se replace substitute(\_ _) 	///
	    order(F5D.ln_mw F4D.ln_mw F3D.ln_mw F2D.ln_mw FD.ln_mw D.ln_mw ///
		LD.ln_mw L2D.ln_mw L3D.ln_mw L4D.ln_mw L5D.ln_mw LD.ln_med_rent_psqft_sfcc) ///
        coeflabels(`estlabels') ///
		stats(N, fmt(%9.0g) 		///
		labels("Observations")) star(* 0.10 ** 0.05 *** 0.01) 	///
		mtitles("DiD" "\shortstack{Distributed \\ leads and lags}" "\shortstack{Distributed \\ Lags}" ///
		"\shortstack{AB Distributed \\ leads and lags}" "\shortstack{AB Distributed \\ Lags}" ///
		"\shortstack{MW Distributed \\ leads and lags}" "\shortstack{MW Distributed \\ Lags}") nonote
		
	horse_race_models, depvar(ln_med_rent_psqft_sfcc) w(5) ///
	    absorb(year_month zipcode) cluster(statefips)
	esttab * using "`outstub'/horse_race_zipcode_trend.tex", compress se replace substitute(\_ _)	///
	    order(F5D.ln_mw F4D.ln_mw F3D.ln_mw F2D.ln_mw FD.ln_mw D.ln_mw ///
		LD.ln_mw L2D.ln_mw L3D.ln_mw L4D.ln_mw L5D.ln_mw LD.ln_med_rent_psqft_sfcc) ///	 
		coeflabels(`estlabels') ///
		stats(N, fmt(%9.0g) 		///
		labels("Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		mtitles("DiD" "\shortstack{Distributed \\ leads and lags}" "\shortstack{Distributed \\ Lags}" ///
		"\shortstack{AB Distributed \\ leads and lags}" "\shortstack{AB Distributed \\ Lags}" ///
		"\shortstack{MW Distributed \\ leads and lags}" "\shortstack{MW Distributed \\ Lags}") nonote
		
	horse_race_models, depvar(ln_med_rent_psqft_sfcc) w(5) ///
	    absorb(year_month zipcode c.trend_times2#i.zipcode) cluster(statefips)
	esttab * using "`outstub'/horse_race_zipcode_trend_sq.tex", compress se replace substitute(\_ _)	///
	    order(F5D.ln_mw F4D.ln_mw F3D.ln_mw F2D.ln_mw FD.ln_mw D.ln_mw ///
		LD.ln_mw L2D.ln_mw L3D.ln_mw L4D.ln_mw L5D.ln_mw LD.ln_med_rent_psqft_sfcc) ///    
        coeflabels(`estlabels') ////
		stats(N, fmt(%9.0g) 		///
		labels("Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		mtitles("DiD" "\shortstack{Distributed \\ leads and lags}" "\shortstack{Distributed \\ Lags}" ///
		"\shortstack{AB Distributed \\ leads and lags}" "\shortstack{AB Distributed \\ Lags}" ///
		"\shortstack{MW Distributed \\ leads and lags}" "\shortstack{MW Distributed \\ Lags}") nonote
end

program horse_race_models
    syntax, depvar(str) w(int) absorb(str) cluster(str) 
	
    eststo clear
	eststo: qui reghdfe D.`depvar' D.ln_mw,							///
		absorb(`absorb') 												///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
		
	eststo: qui ivreghdfe D.`depvar' L(-`w'/`w').D.ln_mw (L.D.`depvar' = L2.D.`depvar'), 			///
		absorb(`absorb') ///
		cluster (`cluster') nocons

	eststo: qui ivreghdfe D.`depvar' L(0/`w').D.ln_mw (L.D.`depvar' = L2.D.`depvar'), 			///
		absorb(`absorb') ///
		cluster (`cluster') nocons
		
	eststo: qui ivreghdfe D.`depvar' L(-`w'/`w').D.ln_mw (L.D.`depvar' = L6.D.ln_mw), 			///
		absorb(`absorb') ///
		cluster (`cluster') nocons
		
	eststo: qui ivreghdfe D.`depvar' L(0/`w').D.ln_mw (L.D.`depvar' = L6.D.ln_mw), 			///
		absorb(`absorb') ///
		cluster (`cluster') nocons
end

program make_results_labels, rclass
		
		local estlabels `"            F5D.ln_mw "$\Delta \ln(MW)_{t-5}$" F4D.ln_mw "$\Delta \ln(MW)_{t-4}$""'
		local estlabels `"`estlabels' F3D.ln_mw "$\Delta \ln(MW)_{t-3}$" F2D.ln_mw "$\Delta \ln(MW)_{t-2}$""'
		local estlabels `"`estlabels' FD.ln_mw "$\Delta \ln(MW)_{t-1}$" D.ln_mw "$\Delta \ln(MW)_{t}$""'
		local estlabels `"`estlabels' LD.ln_mw "$\Delta \ln(MW)_{t+1}$" L2D.ln_mw "$\Delta \ln(MW)_{t+2}$""'
		local estlabels `"`estlabels' L3D.ln_mw "$\Delta \ln(MW)_{t+3}$" L4D.ln_mw "$\Delta \ln(MW)_{t+4}$""'
		local estlabels `"`estlabels' L5D.ln_mw "$\Delta \ln(MW)_{t+5}$" LD.ln_med_rent_psqft_sfcc "$\Delta \ln(y)_{t-1}$""'

		return local estlabels "`estlabels'"		
	

end 

main
