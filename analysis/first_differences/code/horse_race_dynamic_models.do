clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	horse_race_models, depvar(ln_med_rent_psqft) w(2) ///
	    absorb(year_month) cluster(statefips)
	esttab * using "`outstub'/horse_race.tex", compress se replace 	///
	    order(F2D.ln_mw FD.ln_mw D.ln_mw LD.ln_mw L2D.ln_mw LD.ln_med_rent_psqft) ///
		stats(r2 N, fmt(%9.3f %9.0g) 		///
		labels("R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 	///
		mtitles("DiD" "Distributed leads and lags" "Distributed Lags" ///
		"AB distributed leads and lags" "AB distributed lags") nonote
		
	horse_race_models, depvar(ln_med_rent_psqft) w(2) ///
	    absorb(year_month zipcode) cluster(statefips)
	esttab * using "`outstub'/horse_race_zipcode_trend.tex", compress se replace 	///
	    order(F2D.ln_mw FD.ln_mw D.ln_mw LD.ln_mw L2D.ln_mw LD.ln_med_rent_psqft) ///
		stats(r2 N, fmt(%9.3f %9.0g) 		///
		labels("R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		mtitles("DiD" "Distributed leads and lags" "Distributed Lags" ///
		"AB distributed leads and lags" "AB distributed lags") nonote
		
	horse_race_models, depvar(ln_med_rent_psqft) w(2) ///
	    absorb(year_month zipcode c.trend_times2#i.zipcode) cluster(statefips)
	esttab * using "`outstub'/horse_race_zipcode_trend_sq.tex", compress se replace 	///
	    order(F2D.ln_mw FD.ln_mw D.ln_mw LD.ln_mw L2D.ln_mw LD.ln_med_rent_psqft) ///
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
