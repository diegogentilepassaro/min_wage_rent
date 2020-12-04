clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/rent_panel.dta", clear

	compare_level_with_baseline, depvar(ln_med_rent_psqft_sfcc) cluster(statefips)
	esttab * using "`outstub'/baseline_vs_level.tex", compress se replace substitute(\_ _) 	///
		stats(p_val_auto N, fmt(%9.4f %9.0gc) labels("P-value autocorrelation test" "Observations")) ////
		star(* 0.10 ** 0.05 *** 0.01) nonote ///
		coeflabels(ln_mw "$\ln \underline{w}_{it}$" D.ln_mw "$\Delta \underline{w}_{it}$") ///
		mtitles("Level" "First Difference")
		
    levels_with_county_or_state_fe, depvar(ln_med_rent_psqft_sfcc) cluster(statefips)
	esttab * using "`outstub'/different_FEs.tex", compress se replace substitute(\_ _) 	///
		stats(zs_trend N, labels("Zipcode-specific linear trends" "Observations")) ///
		mtitles("Zipcode FE" "County FE" "State FE" "State FE") ////
		star(* 0.10 ** 0.05 *** 0.01) nonote ///
		coeflabels(ln_mw "$\ln \underline{w}_{it}$")

end

program compare_level_with_baseline
    syntax, depvar(str) cluster(str) 
	
    eststo clear
	eststo: qui reghdfe `depvar' ln_mw,	///
		absorb(year_month zipcode) 	///
		vce(cluster `cluster') nocons
		
	eststo fd: qui reghdfe D.`depvar' D.ln_mw, ///
		absorb(year_month) ///
		vce(cluster `cluster') nocons ///
		residuals(fd_res)
	qui reg fd_res L.fd_res, cluster(statefip)
	qui test (L.fd_res = -0.5) 
	qui estadd scalar p_val_auto = r(p): fd
    drop fd_res
end

program levels_with_county_or_state_fe
    syntax, depvar(str) cluster(str) 

	eststo clear
	eststo: qui reghdfe `depvar' ln_mw,	///
		absorb(year_month zipcode) ///
		vce(cluster `cluster') nocons
	qui estadd local zs_trend "No"


	eststo: qui reghdfe `depvar' ln_mw,	///
		absorb(year_month county) ///
		vce(cluster `cluster') nocons
	qui estadd local zs_trend "No"

	eststo: qui reghdfe `depvar' ln_mw,	///
		absorb(year_month statefip) ///
		vce(cluster `cluster') nocons
	qui estadd local zs_trend "No"

	eststo: qui reghdfe `depvar' ln_mw, ///
		absorb(year_month statefip zipcode#c.trend) ///
		vce(cluster `cluster') nocons
	qui estadd local zs_trend "Yes"
end

main
