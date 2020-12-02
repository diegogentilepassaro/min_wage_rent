clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/rent_panel.dta", clear

	make_results_labels
	local estlabels "`r(estlabels)'"

	horse_race_models, depvar(ln_med_rent_psqft_sfcc) w(5) cluster(statefips)
	esttab * using "`outstub'/level_models.tex", compress se replace substitute(\_ _) 	///
	    order(F5.ln_mw F4.ln_mw F3.ln_mw F2.ln_mw F.ln_mw ln_mw ///
		L.ln_mw L2.ln_mw L3.ln_mw L4.ln_mw L5.ln_mw) ///
        coeflabels(`estlabels') ///
		stats(N, fmt(%9.0g) 		///
		labels("Observations")) star(* 0.10 ** 0.05 *** 0.01) 	///
		mtitles("Zipcode FE" "Zipcode FE" "Zipcode FE" ///
		"County FE" "County FE" "County FE" ///
		"State FE" "State FE" "State FE") nonote
end

program compare_level_with_baseline
    syntax, depvar(str) w(int) cluster(str) 
	
    eststo clear
	eststo: qui reghdfe `depvar' ln_mw,							///
		absorb(year_month zipcode) 												///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe `depvar' L(-`w'/`w').ln_mw, 			///
		absorb(year_month zipcode) 											///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe `depvar' L(0/`w').ln_mw, 			///
		absorb(year_month zipcode) 											///
		vce(cluster `cluster') nocons
		
    eststo clear
	eststo: qui reghdfe D.`depvar' D.ln_mw,							///
		absorb(year_month) 												///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(year_month) 											///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(year_month) 											///
		vce(cluster `cluster') nocons
end

program levels_with_county_or_state_fe
    syntax, depvar(str) w(int) cluster(str) 

	eststo: qui reghdfe `depvar' ln_mw,							///
		absorb(year_month county) 												///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe `depvar' L(-`w'/`w').ln_mw, 			///
		absorb(year_month county) 											///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe `depvar' L(0/`w').ln_mw, 			///
		absorb(year_month county) 											///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe `depvar' ln_mw,							///
		absorb(year_month statefip) 												///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe `depvar' L(-`w'/`w').ln_mw, 			///
		absorb(year_month statefip) 											///
		vce(cluster `cluster') nocons
		
	eststo: qui reghdfe `depvar' L(0/`w').ln_mw, 			///
		absorb(year_month statefip) 											///
		vce(cluster `cluster') nocons
end

program make_results_labels, rclass
		
		local estlabels `"            F5.ln_mw "$\ln(MW)_{t-5}$" F4.ln_mw "$\ln(MW)_{t-4}$""'
		local estlabels `"`estlabels' F3.ln_mw "$\ln(MW)_{t-3}$" F2.ln_mw "$\ln(MW)_{t-2}$""'
		local estlabels `"`estlabels' F.ln_mw "$\ln(MW)_{t-1}$" ln_mw "$\ln(MW)_{t}$""'
		local estlabels `"`estlabels' L.ln_mw "$\ln(MW)_{t+1}$" L2.ln_mw "$\ln(MW)_{t+2}$""'
		local estlabels `"`estlabels' L3.ln_mw "$\ln(MW)_{t+3}$" L4.ln_mw "$\ln(MW)_{t+4}$""'
		local estlabels `"`estlabels' L5.ln_mw "$\ln(MW)_{t+5}$""'

		return local estlabels "`estlabels'"
end 

main
