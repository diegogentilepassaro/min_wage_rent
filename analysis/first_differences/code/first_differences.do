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
		"Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" 								///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote
	
	* Dynamic Model
	run_dynamic_model, depvar(ln_med_rent_psqft) absorb(year_month) 					///
		cluster(statefips)
	
	esttab reg1 reg2 reg3 reg4 using "`outstub'/fd_dynamic_table.tex", 					///
		keep(*.ln_mw) compress se replace 												///
		stats(zs_trend zs_trend_sq zs_trend_cu r2 N, fmt(%s3 %s3 %s3 %9.3f %9.0g) 		///
		labels("Zipcode-specifc linear trend" 											///
		"Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" 								///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote

	esttab lincom1 lincom2 lincom3 lincom4 using "`outstub'/fd_dynamic_lincom_table.tex", ///
		compress se replace 															///
        stats(zs_trend zs_trend_sq zs_trend_cu N, fmt(%s3 %s3 %s3 %9.0g) 				///
		labels("Zipcode-specifc linear trend" 											///
	    "Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" "Observations")) 				///
		star(* 0.10 ** 0.05 *** 0.01) 													///
		nonote coeflabel((1) "Sum of MW effects")

	* Heterogeneity
	run_static_heterogeneity, depvar(ln_med_rent_psqft) absorb(year_month) 				///
		het_var(med_hhinc20105_st_qtl) cluster(statefips)
	graph export "`outstub'/fd_static_heterogeneity.png", replace	
end

program run_static_model
    syntax, depvar(str) absorb(str) cluster(str)

	eststo clear
	eststo reg1: reghdfe D.`depvar' D.ln_mw,							///
		absorb(`absorb') 												///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No") trend_cu("No")
	
	scalar static_effect = _b[D.ln_mw]
	scalar static_effect_se = _se[D.ln_mw]

	eststo: reghdfe D.`depvar' D.ln_mw,									///
		absorb(`absorb' c.trend#i.zipcode) 								///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No") trend_cu("No")

	eststo: reghdfe D.`depvar' D.ln_mw,									///
		absorb(`absorb' c.trend#i.zipcode  c.trend_sq#i.zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("No")

	eststo: reghdfe D.`depvar' D.ln_mw,									///
		absorb(`absorb' c.trend#i.zipcode  c.trend_sq#i.zipcode c.trend_cu#i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("Yes")
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
	comment_table, trend_lin("No") trend_sq("No") trend_cu("No")
	
	coefplot, vertical base gen
	
	preserve
		keep __at __b __se
		rename (__at __b __se) (at b se)
		tset at
		
		gen static_path = 0 if at <= 5 
		replace static_path = scalar(static_effect) if at > 5
		gen static_path_lb = 0 if at <= 5
		replace static_path_lb = scalar(static_effect) - 1.96*scalar(static_effect_se) if at > 5
		gen static_path_ub = 0 if at <= 5
		replace static_path_ub = scalar(static_effect) + 1.96*scalar(static_effect_se) if at > 5
		
		gen cumsum_b = b[1]
		replace cumsum_b = cumsum_b[_n-1] + b[_n] if _n>1
		keep if !missing(at)

		gen b_lb = b - 1.96*se
		gen b_ub = b + 1.96*se

		twoway (scatter b at, mcol(navy)) ///
			(rcap b_lb b_ub at, col(navy)) ///
			(line cumsum at, lcol(green)) ///
			(line static_path at, lcol(maroon)), ///
			yline(0, lcol(grey) lpat(dot)) ///
			graphregion(color(white)) bgcolor(white) ///
			xlabel(1 "F5D.ln_mw" 2 "F4D.ln_mw" 3 "F3D.ln_mw" 4 "F2D.ln_mw" ///
			5 "FD.ln_mw" 6 "D.ln_mw" 7 "LD.ln_mw" 8 "L2D.ln_mw" 9 "L3D.ln_mw" ///
			10 "L4D.ln_mw" 11 "L5D.ln_mw", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln rent per sqft") ///
			legend(order(1 "Dynamic model coefficients" 3 "Cumulative sum: dynamic model" ///
			4 "Implied cumulative sum: static model") size(small))
		graph export "../output/fd_models.png", replace
	restore
	
	eststo lincom1: lincomest `lincomest_coeffs'
	comment_table, trend_lin("No") trend_sq("No") trend_cu("No")
	
	eststo reg2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw  `if', 		///
		absorb(`absorb' c.trend#i.zipcode) 							///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No") trend_cu("No")

	eststo lincom2: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("No") trend_cu("No")
	
	eststo reg3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if',		///
		absorb(`absorb' c.trend#i.zipcode c.trend_sq#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("No")

	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("No")

	eststo reg4: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if',		///
		absorb(`absorb' c.trend#i.zipcode c.trend_sq#i.zipcode c.trend_cu#i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("Yes")
	
	eststo lincom4: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("Yes")
end

program run_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) het_var(str) [w(int 5)]

	eststo clear

	mat A = J(5, 3, .)
	mat colnames A = coeff ci_low ci_high

	forvalues i = 1(1)5 {
		quietly reghdfe D.`depvar' D.ln_mw if `het_var' == `i',							///
			absorb(`absorb' c.trend#i.zipcode c.trend_sq#i.zipcode c.trend_cu#i.zipcode) ///
			vce(cluster `cluster') nocons

		mat B = e(b)
		mat V = e(V)

		mat A[`i', 1] = B[1, 1]
		mat A[`i', 2] = B[1, 1] - 1.96*(V[1, 1]^.5)
		mat A[`i', 3] = B[1, 1] + 1.96*(V[1, 1]^.5)
	}

	mat tA = A'

	coefplot matrix(tA[1]), ci((tA[2] tA[3])) 							///
		graphregion(color(white)) bgcolor(white)						///
		ylabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5")							///
		ytitle("Quintiles of state mean income distribution") 			///
		xtitle("Estimated effect of ln MW on ln rents")					///
		xline(0, lcol(grey) lpat(dot))
end

program comment_table
	syntax, trend_lin(str) trend_sq(str) trend_cu(str)

	estadd local zs_trend 		"`trend_lin'"	
	estadd local zs_trend_sq 	"`trend_sq'"
	estadd local zs_trend_cu 	"`trend_cu'"
end

main
