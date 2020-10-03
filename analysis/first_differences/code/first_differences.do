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
		stats(zs_trend zs_trend_sq cty_emp_wg r2 N, fmt(%s3 %s3 %9.3f %9.0g) 		///
		labels("Zipcode-specifc linear trend" 											///
		"Zipcode-specific linear and square trend"								///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote

	run_static_model_control, depvar(ln_med_rent_psqft) absorb(year_month) 						///
		cluster(statefips)
	esttab * using "`outstub'/fd_table_control.tex", keep(D.ln_mw) compress se replace 			///
		stats(employment_cov establishment_cov avg_weekly_wage_cov new_building_cov r2 N, fmt(%s3 %s3 %s3 %s3 %9.3f %9.0g) 		///
		labels("Industry-level monthly employment" 											///
		"Industry-level quarterly establishment count"								///
		"Industry-level quarterly weekly wage"                                          ///
		"New housing permits and value"                                                ///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote


	* Dynamic Model
	run_dynamic_model, depvar(ln_med_rent_psqft) absorb(year_month) 					///
		cluster(statefips)
	
	esttab reg1 reg2 reg3 using "`outstub'/fd_dynamic_table.tex", 					///
		keep(*.ln_mw) compress se replace 												///
		stats(p_value_F zs_trend zs_trend_sq r2 N, fmt(%9.3f %s3 %9.3f %9.0g) 		///
		labels("P-value no pretrends" "Zipcode-specifc linear trend" 											///
		"Zipcode-specific linear and square trend"							///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote

	esttab lincom1 lincom2 lincom3 using "`outstub'/fd_dynamic_lincom_table.tex", ///
		compress se replace 															///
        stats(zs_trend zs_trend_sq cty_emp_wg N, fmt(%s3 %s3 %9.0g) 				///
		labels("Zipcode-specifc linear trend" 											///
	    "Zipcode-specific linear and square trend"                                      ///
		"Observations")) 				///
		star(* 0.10 ** 0.05 *** 0.01) 													///
		nonote coeflabel((1) "Sum of MW effects")

	run_dynamic_model_control, depvar(ln_med_rent_psqft) absorb(year_month) 					///
		cluster(statefips)
	
	esttab reg1 reg2 reg3 reg4 reg5 using "`outstub'/fd_dynamic_table_control.tex", 					///
		keep(*.ln_mw) compress se replace 												///
		stats(p_value_F employment_cov establishment_cov avg_weekly_wage_cov new_building_cov r2 N, fmt(%9.3f %s3 %s3 %s3 %s3 %9.3f %9.0g) 		///
		labels("P-value no pretrends" "Industry-level monthly employment" 											///
		"Industry-level quarterly establishment count"								///
		"Industry-level quarterly weekly wage"                                          ///
		"New housing permits and value"                                                ///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 						///
		nonote

	esttab lincom1 lincom2 lincom3 lincom4 lincom5 using "`outstub'/fd_dynamic_lincom_table_control.tex", ///
		compress se replace 															///
		stats(employment_cov establishment_cov avg_weekly_wage_cov new_building_cov N, fmt(%s3 %s3 %s3 %s3 %9.3f) 		///
		labels("Industry-level monthly employment" 											///
		"Industry-level quarterly establishment count"								///
		"Industry-level quarterly weekly wage"                                          ///
		"New housing permits and value"                                                ///
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

program run_static_model_control
	syntax, depvar(str) absorb(str) cluster(str)

	eststo clear
  	local emp_cont       "ln_emp_leis ln_emp_goodpr ln_emp_const ln_emp_transp ln_emp_bizserv ln_emp_eduhe ln_emp_fedgov ln_emp_info ln_emp_manu ln_emp_natres ln_emp_servpr ln_emp_stgov"
    local establish_cont "ln_estcount_leis ln_estcount_goodpr ln_estcount_const ln_estcount_transp ln_estcount_bizserv ln_estcount_eduhe ln_estcount_fedgov ln_estcount_info ln_estcount_manu ln_estcount_natres ln_estcount_servpr ln_estcount_stgov"
    local wage_cont      "ln_avgwwage_leis ln_avgwwage_goodpr ln_avgwwage_const ln_avgwwage_transp ln_avgwwage_bizserv ln_avgwwage_eduhe ln_avgwwage_fedgov ln_avgwwage_info ln_avgwwage_manu ln_avgwwage_natres ln_avgwwage_servpr ln_avgwwage_stgov"
    local housing_cont   "ln_u1rep_units ln_u1rep_value"

    eststo: reghdfe D.`depvar' D.ln_mw,									///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("No") est_cov("No") wage_cov("No") housing_cov("No")

    eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_cov'),									///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("No") wage_cov("No") housing_cov("No")

    eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_cont') D.(`establish_cont'),									///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("No") housing_cov("No")

    eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_cont') D.(`establish_cont') D.(`wage_cont'),									///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("No")

    eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_cont') D.(`establish_cont') D.(`wage_cont') D.(`housing_cont'),									///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("Yes")

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
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)

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
		replace cumsum_b_lags = cumsum_b_lags[_n-1] + b_lags[_n] if _n > 1
		
		replace at = at + `w'
		
		merge 1:1 at using "../temp/plot_coeffs.dta", nogen
		replace cumsum_b_lags = 0 if at <= `w'
		sort at
		
		// To avoid the lines overlapping perfectly
		gen at_full = at - 0.09
		gen at_lags = at + 0.09
		replace at_full = at if _n <= `w'
		replace at_lags = at if _n <= `w'

		replace cumsum_b_lags = cumsum_b_lags - 0.00007 if _n <= `w'
		replace static_path = static_path + 0.00007 if _n <= `w'

		// Figure
		twoway (scatter b_full at_full, mcol(navy)) 				///
			(rcap b_full_lb b_full_ub at_full, col(navy)) 			///
			(scatter b_lags at_lags, mcol(maroon)) 					///
			(rcap b_lags_lb b_lags_ub at_lags, col(maroon)) 		///
			(line static_path at, lcol(gs4) lpat(dash)) 			///
			(line cumsum_b_lags at, lcol(maroon)), 					///
			yline(0, lcol(grey) lpat(dot)) 							///
			graphregion(color(white)) bgcolor(white) 				///
			xlabel(1 "F5D.ln_mw" 2 "F4D.ln_mw" 3 "F3D.ln_mw" 4 "F2D.ln_mw" ///
			5 "FD.ln_mw" 6 "D.ln_mw" 7 "LD.ln_mw" 8 "L2D.ln_mw" 9 "L3D.ln_mw" ///
			10 "L4D.ln_mw" 11 "L5D.ln_mw", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln rent per sqft") 					///
			legend(order(1 "Full dynamic model" 3 "Distributed lags model" ///
			5 "Effects path static model" 6 "Effects path distributed lags model") size(small))
		graph export "../output/fd_models.png", replace
	restore 
	
	eststo reg2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if', 		///
		absorb(`absorb' i.zipcode) 							///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)
	
	eststo lincom2: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("No")
	
	eststo reg3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if',		///
		absorb(`absorb' i.zipcod c.trend_times2#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")

	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)
	
	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("Yes") 
end

program run_dynamic_model_control
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5)]
	
	eststo clear
  	local emp_cont       "ln_emp_leis ln_emp_goodpr ln_emp_const ln_emp_transp ln_emp_bizserv ln_emp_eduhe ln_emp_fedgov ln_emp_info ln_emp_manu ln_emp_natres ln_emp_servpr ln_emp_stgov"
    local establish_cont "ln_estcount_leis ln_estcount_goodpr ln_estcount_const ln_estcount_transp ln_estcount_bizserv ln_estcount_eduhe ln_estcount_fedgov ln_estcount_info ln_estcount_manu ln_estcount_natres ln_estcount_servpr ln_estcount_stgov"
    local wage_cont      "ln_avgwwage_leis ln_avgwwage_goodpr ln_avgwwage_const ln_avgwwage_transp ln_avgwwage_bizserv ln_avgwwage_eduhe ln_avgwwage_fedgov ln_avgwwage_info ln_avgwwage_manu ln_avgwwage_natres ln_avgwwage_servpr ln_avgwwage_stgov"
    local housing_cont   "ln_u1rep_units ln_u1rep_value"


	local lincomest_coeffs "D1.ln_mw + LD.ln_mw"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.ln_mw"
	}

	eststo clear
	eststo reg1: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if',		///
		absorb(`absorb' i.zipcod c.trend_times2#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("No") est_cov("No") wage_cov("No") housing_cov("No")
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)

	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_base se_base)
		
		keep if !missing(at)

		gen b_base_lb = b_base - 1.96*se_base
		gen b_base_ub = b_base + 1.96*se_base
		
		save "../temp/plot_coeffs_base.dta", replace
    restore
		
	eststo lincom1: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("No") est_cov("No") wage_cov("No") housing_cov("No")
	
	eststo reg2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_cont') `if',		///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("No") wage_cov("No") housing_cov("No")
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)

    preserve
		coefplot, vertical base gen
		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep __at __b __se
		rename (__at __b __se) (at b_emp se_emp)
		
		keep if !missing(at)

		gen b_emp_lb = b_emp - 1.96*se_emp
		gen b_emp_ub = b_emp + 1.96*se_emp
		
		save "../temp/plot_coeffs_emp.dta", replace
    restore
	
	eststo lincom2: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("Yes") est_cov("No") wage_cov("No") housing_cov("No")
	
	eststo reg3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_cont') D.(`establish_cont') `if',		///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("No") housing_cov("No")
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)

    preserve
		coefplot, vertical base gen
		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep __at __b __se
		rename (__at __b __se) (at b_est se_est)
		
		keep if !missing(at)

		gen b_est_lb = b_est - 1.96*se_est
		gen b_est_ub = b_est + 1.96*se_est
		
		save "../temp/plot_coeffs_est.dta", replace
    restore
	
	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("No") housing_cov("No")

	eststo reg4: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_cont') D.(`establish_cont') D.(`wage_cont') `if',		///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("No")
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)

    preserve
		coefplot, vertical base gen
		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep __at __b __se
		rename (__at __b __se) (at b_wage se_wage)
		
		keep if !missing(at)

		gen b_wage_lb = b_wage - 1.96*se_wage
		gen b_wage_ub = b_wage + 1.96*se_wage
		
		save "../temp/plot_coeffs_wage.dta", replace
    restore
	
	eststo lincom4: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("No")

	eststo reg5: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_cont') D.(`establish_cont') D.(`wage_cont') D.(`housing_cont') `if',		///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("Yes")
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)

    preserve
		coefplot, vertical base gen
		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep __at __b __se
		rename (__at __b __se) (at b_house se_house)
		
		keep if !missing(at)

		gen b_house_lb = b_house - 1.96*se_house
		gen b_house_ub = b_house + 1.96*se_house

		merge 1:1 at using "../temp/plot_coeffs_base.dta", nogen
		merge 1:1 at using "../temp/plot_coeffs_emp.dta", nogen
		merge 1:1 at using "../temp/plot_coeffs_est.dta", nogen
		merge 1:1 at using "../temp/plot_coeffs_wage.dta", nogen

		sort at 

		g at_emp   = at - 0.2
		g at_est   = at - 0.1
		g at_wage  = at + 0.1
		g at_house = at + 0.2

		twoway (scatter b_base at, mc(black))        (rcap b_base_lb b_base_ub at, lc(black) lp(dash) lw(vthin))          ///
			   (scatter b_emp at_emp, mc(edkblue))     (rcap b_emp_lb b_emp_ub at_emp, lc(edkblue) lp(dash) lw(vthin))        ///
			   (scatter b_est at_est, mc(lavender))     (rcap b_est_lb b_est_ub at_est, lc(lavender) lp(dash) lw(vthin))        ///
			   (scatter b_wage at_wage, mc(dkorange))   (rcap b_wage_lb b_wage_ub at_wage, lc(dkorange) lp(dash) lw(vthin))     ///
			   (scatter b_house at_house, mc(gs10)) (rcap b_house_lb b_house_ub at_house, lc(gs10) lp(dash) lw(vthin)), /// 
			yline(0, lcol(grey) lpat(dot)) 							///
			graphregion(color(white)) bgcolor(white) 				///
			xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" ///
			5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" ///
			10 "4" 11 "5", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln rent per sqft") 					///
			legend(order(1 "baseline" 3 "employment" ///
			5 "establishment" 7 "wage" 9 "building") size(small))
		graph export "../output/fd_models_control.png", replace
    restore
	
	eststo lincom5: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("Yes")

end

program run_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) het_var(str) ytitle(str) [qtles(int 4)]

    eststo clear
	reghdfe D.`depvar' c.d_ln_mw#i.`het_var',							///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	coefplot, base graphregion(color(white)) bgcolor(white)						///
	ylabel(1 "1" 2 "2" 3 "3" 4 "4")							///
	ytitle(`ytitle') 												///
	xtitle("Estimated effect of ln MW on ln rents")					///
	xline(0, lcol(grey) lpat(dot))
end

program build_ytitle, rclass
	syntax, var(str)

	if "`var'" == "med_hhinc20105" {
		return local title "Quintiles of within state 2010 median household income"
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

program comment_table_control
	syntax, emp_cov(str) est_cov(str) wage_cov(str) housing_cov(str)

	estadd local employment_cov      "`emp_cov'"
	estadd local establishment_cov   "`est_cov'"
	estadd local avg_weekly_wage_cov "`wage_cov'"
	estadd local new_building_cov    "`housing_cov'"

end 

main
