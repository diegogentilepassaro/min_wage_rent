clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	* Static Model
	run_static_model, depvar(ln_med_rent_psqft) absorb(year_month) 						///
		cluster(statefips)

	esttab * using "`outstub'/fd_table.tex", keep(D.ln_mw) compress se replace 			///
		stats(zs_trend zs_trend_sq zs_trend_cu r2 N, fmt(%s3 %s3 %s3 %9.3f %9.0g) 		///
		labels("Zipcode-specifc linear trend" 											///
		"Zipcode-specific linear and square trend" 								///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote
	
	* Dynamic Model
	run_dynamic_model, depvar(ln_med_rent_psqft) absorb(year_month) 					///
		cluster(statefips)
	
	esttab reg1 reg2 reg3 using "`outstub'/fd_dynamic_table.tex", 					///
		keep(*.ln_mw) compress se replace 												///
		stats(zs_trend zs_trend_sq zs_trend_cu r2 N, fmt(%s3 %s3 %s3 %9.3f %9.0g) 		///
		labels("Zipcode-specifc linear trend" 											///
		"Zipcode-specific linear and square trend"								///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote

	esttab lincom1 lincom2 lincom3 using "`outstub'/fd_dynamic_lincom_table.tex", ///
		compress se replace 															///
        stats(zs_trend zs_trend_sq zs_trend_cu N, fmt(%s3 %s3 %s3 %9.0g) 				///
		labels("Zipcode-specifc linear trend" 											///
	    "Zipcode-specific linear and square trend" ///
		"Observations")) 				///
		star(* 0.10 ** 0.05 *** 0.01) 													///
		nonote coeflabel((1) "Sum of MW effects")

	* Heterogeneity
	foreach var in med_hhinc20105 renthouse_share2010 college_share20105 				///
				black_share2010 nonwhite_share2010 work_county_share20105 {

		build_ytitle, var(`var')

		run_static_heterogeneity, depvar(ln_med_rent_psqft) absorb(year_month) 			///
			het_var(`var'_st_qtl) cluster(statefips) ytitle(`r(title)')
		graph export "`outstub'/fd_static_heter_`var'.png", replace
	}
end

program run_static_model
    syntax, depvar(str) absorb(str) cluster(str)

	eststo clear
	eststo reg1: reghdfe D.`depvar' D.ln_mw,							///
		absorb(`absorb') 												///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")
	
	scalar static_effect = _b[D.ln_mw]
	scalar static_effect_se = _se[D.ln_mw]

	eststo: reghdfe D.`depvar' D.ln_mw,									///
		absorb(`absorb' i.zipcode) 								///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")

	eststo: reghdfe D.`depvar' D.ln_mw,									///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")
end

program run_dynamic_model
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5)]
	
	local lincomest_coeffs "D1.ln_mw + LD.ln_mw"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.ln_mw"
	}

	eststo clear
	eststo reg1: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")
		
	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_full se_full)
		
		keep if !missing(at)

		gen b_full_lb = b_full - 1.96*se_full
		gen b_full_ub = b_full + 1.96*se_full
		
		gen static_path = 0 if at <= `w' 
		replace static_path = scalar(static_effect) if at > `w'
		gen static_path_lb = 0 if at <= `w'
		replace static_path_lb = scalar(static_effect) - 1.96*scalar(static_effect_se) if at > `w'
		gen static_path_ub = 0 if at <= `w'
		replace static_path_ub = scalar(static_effect) + 1.96*scalar(static_effect_se) if at > `w'
		
		save "../temp/plot_coeffs.dta", replace
    restore
		
	eststo lincom1: lincomest `lincomest_coeffs'
	comment_table, trend_lin("No") trend_sq("No")
	
	qui reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
			
	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_lags se_lags)
		tset at

	    keep if !missing(at)

		gen b_lags_lb = b_lags - 1.96*se_lags
		gen b_lags_ub = b_lags + 1.96*se_lags
		
		gen cumsum_b_lags = b_lags[1]
		replace cumsum_b_lags = cumsum_b_lags[_n-1] + b_lags[_n] if _n>1

		replace at = at + `w'
		
		merge 1:1 at using "../temp/plot_coeffs.dta", nogen
		replace cumsum_b_lags = 0 if at <= `w'
		sort at
		
		twoway (scatter b_full at, mcol(navy)) ///
			(rcap b_full_lb b_full_ub at, col(navy)) ///
			(scatter b_lags at, mcol(maroon)) ///
			(rcap b_lags_lb b_lags_ub at, col(maroon)) ///
			(line cumsum_b_lags at, lcol(maroon)) ///
			(line static_path at, lcol(green)), ///
			yline(0, lcol(grey) lpat(dot)) ///
			graphregion(color(white)) bgcolor(white) ///
			xlabel(1 "F5D.ln_mw" 2 "F4D.ln_mw" 3 "F3D.ln_mw" 4 "F2D.ln_mw" ///
			5 "FD.ln_mw" 6 "D.ln_mw" 7 "LD.ln_mw" 8 "L2D.ln_mw" 9 "L3D.ln_mw" ///
			10 "L4D.ln_mw" 11 "L5D.ln_mw", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln rent per sqft") ///
			legend(order(1 "Full dynamic model coefficients" 3 "Distributed lags model" ///
			5 "Effects path static model" 6 "Effects path distributed lags model") size(small))
		graph export "../output/fd_models.png", replace
	restore 
	
	eststo reg2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw  `if', 		///
		absorb(`absorb' i.zipcode) 							///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")

	eststo lincom2: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("No")
	
	eststo reg3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if',		///
		absorb(`absorb' i.zipcod c.trend_times2#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")

	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("Yes")
end

program run_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) het_var(str) ytitle(str) [qtles(int 5)]

    eststo clear
	reghdfe D.`depvar' c.d_ln_mw#i.`het_var',							///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) ///
		vce(cluster `cluster') nocons

	coefplot, base graphregion(color(white)) bgcolor(white)						///
	ylabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5")							///
	ytitle(`ytitle') 												///
	xtitle("Estimated effect of ln MW on ln rents")					///
	xline(0, lcol(grey) lpat(dot))
end

program build_ytitle, rclass
	syntax, var(str)

	if "`var'" == "med_hhinc20105" {
		return local title "Quintiles of 2010 state mean income distribution"
	}
	if "`var'" == "renthouse_share2010" {
		return local title "Quintiles of 2010 share of houses rent"
	}
	if "`var'" == "college_share20105" {
		return local title "Quintiles of 2010 college share"
	}
	if "`var'" == "black_share2010" {
		return local title "Quintiles of 2010 share of black individuals"
	}
	if "`var'" == "nonwhite_share2010" {
		return local title "Quintiles of 2010 share of non-white individuals"
	}
	if "`var'" == "work_county_share20105" {
		return local title "Quintiles of 2010 share who work in county"
	}		  
end

program comment_table
	syntax, trend_lin(str) trend_sq(str)

	estadd local zs_trend 		"`trend_lin'"	
	estadd local zs_trend_sq 	"`trend_sq'"
end

main
