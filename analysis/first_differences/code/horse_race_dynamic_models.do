clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	horse_race_models, depvar(ln_med_rent_psqft) w(5) ///
	    absorb(year_month) cluster(statefips)
	esttab * using "`outstub'/horse_race.tex", compress se replace substitute(\_ _) 	///
	    order(F5D.ln_mw F4D.ln_mw F3D.ln_mw F2D.ln_mw FD.ln_mw D.ln_mw ///
		LD.ln_mw L2D.ln_mw L3D.ln_mw L4D.ln_mw L5D.ln_mw LD.ln_med_rent_psqft) ///
        coeflabels(F5D.ln_mw "\Delta ln(MW)_{t-5}" F4D.ln_mw "\Delta ln(MW)_{t-4}" ///
		F3D.ln_mw "\Delta ln(MW)_{t-3}" F2D.ln_mw "\Delta ln(MW)_{t-2}" ///
		FD.ln_mw "\Delta ln(MW)_{t-1}" D.ln_mw "\Delta ln(MW)_{t}" ///
		LD.ln_mw "\Delta ln(MW)_{t+1}" L2D.ln_mw "\Delta ln(MW)_{t+2}" ///
		L3D.ln_mw "\Delta ln(MW)_{t+3}" L4D.ln_mw "\Delta ln(MW)_{t+4}" ///
		L5D.ln_mw "\Delta ln(MW)_{t+5}" LD.ln_med_rent_psqft "\Delta ln(y)_{t-1}") ///
		stats(r2 N, fmt(%9.3f %9.0g) 		///
		labels("R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 	///
		mtitles("DiD" "Distributed leads and lags" "Distributed Lags" ///
		"AB distributed leads and lags" "AB distributed lags") nonote
		
	horse_race_models, depvar(ln_med_rent_psqft) w(5) ///
	    absorb(year_month zipcode) cluster(statefips)
	esttab * using "`outstub'/horse_race_zipcode_trend.tex", compress se replace 	///
	    order(F5D.ln_mw F4D.ln_mw F3D.ln_mw F2D.ln_mw FD.ln_mw D.ln_mw ///
		LD.ln_mw L2D.ln_mw L3D.ln_mw L4D.ln_mw L5D.ln_mw LD.ln_med_rent_psqft) ///	    coeflabels(F3D.ln_mw "\Delta ln(MW)_{t-3}" F2D.ln_mw "\Delta ln(MW)_{t-2}" ///
		coeflabels(F5D.ln_mw "\Delta ln(MW)_{t-5}" F4D.ln_mw "\Delta ln(MW)_{t-4}" ///
		F3D.ln_mw "\Delta ln(MW)_{t-3}" F2D.ln_mw "\Delta ln(MW)_{t-2}" ///
		FD.ln_mw "\Delta ln(MW)_{t-1}" D.ln_mw "\Delta ln(MW)_{t}" ///
		LD.ln_mw "\Delta ln(MW)_{t+1}" L2D.ln_mw "\Delta ln(MW)_{t+2}" ///
		L3D.ln_mw "\Delta ln(MW)_{t+3}" L4D.ln_mw "\Delta ln(MW)_{t+4}" ///
		L5D.ln_mw "\Delta ln(MW)_{t+5}" LD.ln_med_rent_psqft "\Delta ln(y)_{t-1}") ///
		stats(r2 N, fmt(%9.3f %9.0g) 		///
		labels("R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		mtitles("DiD" "Distributed leads and lags" "Distributed Lags" ///
		"AB distributed leads and lags" "AB distributed lags") nonote
		
	horse_race_models, depvar(ln_med_rent_psqft) w(5) ///
	    absorb(year_month zipcode c.trend_times2#i.zipcode) cluster(statefips)
	esttab * using "`outstub'/horse_race_zipcode_trend_sq.tex", compress se replace 	///
	    order(F5D.ln_mw F4D.ln_mw F3D.ln_mw F2D.ln_mw FD.ln_mw D.ln_mw ///
		LD.ln_mw L2D.ln_mw L3D.ln_mw L4D.ln_mw L5D.ln_mw LD.ln_med_rent_psqft) ///        coeflabels(F3D.ln_mw "\Delta ln(MW)_{t-3}" F2D.ln_mw "\Delta ln(MW)_{t-2}" ///
        coeflabels(F5D.ln_mw "\Delta ln(MW)_{t-5}" F4D.ln_mw "\Delta ln(MW)_{t-4}" ///
		F3D.ln_mw "\Delta ln(MW)_{t-3}" F2D.ln_mw "\Delta ln(MW)_{t-2}" ///
		FD.ln_mw "\Delta ln(MW)_{t-1}" D.ln_mw "\Delta ln(MW)_{t}" ///
		LD.ln_mw "\Delta ln(MW)_{t+1}" L2D.ln_mw "\Delta ln(MW)_{t+2}" ///
		L3D.ln_mw "\Delta ln(MW)_{t+3}" L4D.ln_mw "\Delta ln(MW)_{t+4}" ///
		L5D.ln_mw "\Delta ln(MW)_{t+5}" LD.ln_med_rent_psqft "\Delta ln(y)_{t-1}") ////
		stats(r2 N, fmt(%9.3f %9.0g) 		///
		labels("R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		mtitles("DiD" "Distributed leads and lags" "Distributed Lags" ///
		"AB distributed leads and lags" "AB distributed lags") nonote
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
	
	eststo: qui reghdfe D.`depvar' L(-`w'/`w').D.ln_mw L.D.`depvar', 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe D.`depvar' L(0/`w').D.ln_mw L.D.`depvar', 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
end


main
