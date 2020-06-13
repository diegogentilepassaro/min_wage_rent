clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	use "../temp/fd_rent_panel.dta", clear
	
	* Static Model
	eststo clear
	eststo: reghdfe D.ln_medrentpricepsqft_sfcc D.ln_actual_mw,							///
		absorb(year_month) vce(cluster statefips) nocons
	comment_table, trend_lin("No") trend_sq("No") trend_cu("No")

	eststo: reghdfe D.ln_medrentpricepsqft_sfcc D.ln_actual_mw,							///
		absorb(year_month c.trend#i.zipcode) vce(cluster statefips) nocons
	comment_table, trend_lin("Yes") trend_sq("No") trend_cu("No")

	eststo: reghdfe D.ln_medrentpricepsqft_sfcc D.ln_actual_mw, 						///
		absorb(year_month c.trend#i.zipcode c.trend_sq#i.zipcode) 						///
		vce(cluster statefips) nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("No")

	eststo: reghdfe D.ln_medrentpricepsqft_sfcc D.ln_actual_mw, 						///
		absorb(year_month c.trend#i.zipcode c.trend_sq#i.zipcode c.trend_cu#i.zipcode) 	///
		vce(cluster statefips) nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("Yes")
	
 	esttab * using "../output/fd_table.tex", keep(D.ln_actual_mw) compress se replace 	///
        stats(zs_trend zs_trend_sq zs_trend_cu r2 N, fmt(%9.3f %9.0g) 					///
		labels("Zipcode-specifc linear trend" 											///
	    "Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" 								///
	    "R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote
	
	* Dynamic Model
	eststo clear
	eststo reg1: reghdfe D.ln_medrentpricepsqft_sfcc L(-6/6).D.ln_actual_mw, 			///
	    absorb(year_month) vce(cluster statefips) nocons
	comment_table, trend_lin("No") trend_sq("No") trend_cu("No")

	eststo lincom1: lincomest D1.ln_actual_mw + LD.ln_actual_mw + L2D.ln_actual_mw + 	///
	    L3D.ln_actual_mw + L4D.ln_actual_mw + L5D.ln_actual_mw + L6D.ln_actual_mw
	comment_table, trend_lin("No") trend_sq("No") trend_cu("No")
	
	eststo reg2: reghdfe D.ln_medrentpricepsqft_sfcc L(-6/6).D.ln_actual_mw, 			///
	    absorb(year_month c.trend#i.zipcode) vce(cluster statefips) nocons
	comment_table, trend_lin("Yes") trend_sq("No") trend_cu("No")

	eststo lincom2: lincomest D1.ln_actual_mw + LD.ln_actual_mw + L2D.ln_actual_mw + 	///
	    L3D.ln_actual_mw + L4D.ln_actual_mw + L5D.ln_actual_mw + L6D.ln_actual_mw
	comment_table, trend_lin("Yes") trend_sq("No") trend_cu("No")
	
	eststo reg3: reghdfe D.ln_medrentpricepsqft_sfcc L(-6/6).D.ln_actual_mw, 			///
	    absorb(year_month c.trend#i.zipcode c.trend_sq#i.zipcode) 						///
		vce(cluster statefips) nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("No")

	eststo lincom3: lincomest D1.ln_actual_mw + LD.ln_actual_mw + L2D.ln_actual_mw + 	///
	    L3D.ln_actual_mw + L4D.ln_actual_mw + L5D.ln_actual_mw + L6D.ln_actual_mw
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("No")

	eststo reg4: reghdfe D.ln_medrentpricepsqft_sfcc L(-6/6).D.ln_actual_mw, 			///
	    absorb(year_month c.trend#i.zipcode c.trend_sq#i.zipcode c.trend_cu#i.zipcode) 	///
		vce(cluster statefips) nocons
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("Yes")
	
	eststo lincom4: lincomest D1.ln_actual_mw + LD.ln_actual_mw + L2D.ln_actual_mw + 	///
	    L3D.ln_actual_mw + L4D.ln_actual_mw + L5D.ln_actual_mw + L6D.ln_actual_mw
	comment_table, trend_lin("Yes") trend_sq("Yes") trend_cu("Yes")
	
 	esttab reg1 reg2 reg3 reg4 using "../output/fd_dynamic_table.tex", 					///
 		keep(*.ln_actual_mw) compress se replace 										///
        stats(zs_trend zs_trend_sq zs_trend_cu r2 N, fmt(%9.3f %9.0g) 					///
		labels("Zipcode-specifc linear trend" 											///
	    "Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" 								///
	    "R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote

	esttab lincom1 lincom2 lincom3 lincom4 using "../output/fd_dynamic_lincom_table.tex", ///
		compress se replace 															///
        stats(zs_trend zs_trend_sq zs_trend_cu N, fmt(%9.0g) 							///
		labels("Zipcode-specifc linear trend" 											///
	    "Zipcode-specific linear and square trend" 										///
		"Zipcode-specific linear, square and cubic trend" "Observations")) 				///
		star(* 0.10 ** 0.05 *** 0.01) 													///
		nonote coeflabel((1) "Sum of MW effects")
end

program comment_table
	syntax, trend_lin(str) trend_sq(str) trend_cu(str)

	estadd local zs_trend 		"`trend_lin'"	
	estadd local zs_trend_sq 	"`trend_sq'"
	estadd local zs_trend_cu 	"`trend_cu'"
end

main
