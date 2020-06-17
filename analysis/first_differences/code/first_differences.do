clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	use "../temp/fd_rent_panel.dta", clear
	
	* Static Model
	run_static_model, depvar(ln_med_rent_psqft) absorb(year_month) cluster(statefips)
	
	esttab * using "../output/fd_table.tex", keep(D.ln_mw) compress se replace 			///
		stats(zs_trend zs_trend_sq zs_trend_cu r2 N, fmt(%s3 %s3 %s3 %9.3f %9.0g) 		///
		labels("Zipcode-specifc linear trend" 											///
		"Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" 								///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote
	
	* Dynamic Model
	run_dynamic_model, depvar(ln_med_rent_psqft) absorb(year_month) cluster(statefips) w(5)
	
	esttab reg1 reg2 reg3 reg4 using "../output/fd_dynamic_table.tex", 					///
		keep(*.ln_mw) compress se replace 												///
		stats(zs_trend zs_trend_sq zs_trend_cu r2 N, fmt(%s3 %s3 %s3 %9.3f %9.0g) 		///
		labels("Zipcode-specifc linear trend" 											///
		"Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" 								///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote

	esttab lincom1 lincom2 lincom3 lincom4 using "../output/fd_dynamic_lincom_table.tex", ///
		compress se replace 															///
        stats(zs_trend zs_trend_sq zs_trend_cu N, fmt(%s3 %s3 %s3 %9.0g) 				///
		labels("Zipcode-specifc linear trend" 											///
	    "Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" "Observations")) 				///
		star(* 0.10 ** 0.05 *** 0.01) 													///
		nonote coeflabel((1) "Sum of MW effects")
end

program run_static_model
    syntax [if], depvar(str) absorb(str) cluster(str)
	
	eststo clear
	eststo: reghdfe D.`depvar' D.ln_mw `if',							///
		absorb(`absorb') 												///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No") trend_cu("No")

	eststo: reghdfe D.`depvar' D.ln_mw `if',							///
		absorb(`absorb' c.trend#i.zipcode) 								///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No") trend_cu("No")

	eststo: reghdfe D.`depvar' D.ln_mw `if',							///
		absorb(`absorb' c.trend#i.zipcode  c.trend_sq#i.zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("No")

	eststo: reghdfe D.`depvar' D.ln_mw, `if'							///
		absorb(`absorb' c.trend#i.zipcode  c.trend_sq#i.zipcode c.trend_cu#i.zipcode) ///
		vce(cluster `cluster') nocons
		comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("Yes")
end

program run_dynamic_model
	syntax [if], depvar(str) absorb(str) cluster(str) w(int)
	
	local lincomest_coeffs "D1.ln_mw + LD.ln_mw"
	 forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.ln_mw"
	}

	eststo clear
	eststo reg1: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if', 			///
		absorb(`absorb') 												///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No") trend_cu("No")
	
	coefplot, vertical base gen
	
	preserve
		keep __at __b __se
		rename (__at __b __se) (at b se)
		tset at
		gen cumsum_b = b[1]
		replace cumsum_b = cumsum_b[_n-1] + b[_n] if _n>1
		keep if !missing(at)

		gen b_lb = b - 2*se
		gen b_ub = b + 2*se

		twoway (scatter b at, mcol(navy)) ///
			(rcap b_lb b_ub at, col(navy)) ///
			(line cumsum at, lcol(olive)), ///
			yline(0, lcol(grey) lpat(dot)) ///
			graphregion(color(white)) bgcolor(white) ///
			xlabel(1 "F5D.ln_mw" 2 "F4D.ln_mw" 3 "F3D.ln_mw" 4 "F2D.ln_mw" ///
			5 "FD.ln_mw" 6 "D.ln_mw" 7 "LD.ln_mw" 8 "L2D.ln_mw" 9 "L3D.ln_mw" ///
			10 "L4D.ln_mw" 11 "L5D.ln_mw", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln rent per sqft (dollars)") ///
			legend(order(1 "Coefficient" 3 "Cumulative sum of coefficients"))
		graph export "../output/fd_dynamic.png", replace
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

program comment_table
	syntax, trend_lin(str) trend_sq(str) trend_cu(str)

	estadd local zs_trend 		"`trend_lin'"	
	estadd local zs_trend_sq 	"`trend_sq'"
	estadd local zs_trend_cu 	"`trend_cu'"
end

main
