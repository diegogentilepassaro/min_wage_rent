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
	local estlabels_dyn "`r(estlabels_dyn)'"
	local estlabels_static "`r(estlabels_static)'"

	* Static Model
	run_static_placebo, depvar(ln_med_rent_psqft_sfcc) placebovar(ln_n_listings_sfcc) covars(ln_med_list_psqft_sfcc) ///
						absorb(year_month i.zipcode) cluster(statefips)		
						
	esttab * using "`outstub'/fd_table_placebo.tex", keep(D.ln_mw) compress se replace substitute(\_ _) 	///
			coeflabels(`estlabels_static') ///
			stats(r2 N, fmt(%9.3f %9.0gc) ///
			labels("R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) ///
			mgroups("$\Delta y_{it}=\Delta$ ln(Median rent)" "$\Delta y_{it}=\Delta$ ln(No. listings)", pattern(1 0 1 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
			nonote nomtitles 


	plot_dynamic_placebo, depvar(ln_med_rent_psqft_sfcc) placebovar(ln_n_listings_sfcc) covars(ln_med_list_psqft_sfcc) ///
						absorb(year_month i.zipcode) cluster(statefips)


end

program run_static_model
	syntax, depvar(str) absorb(str) cluster(str)

	eststo clear
	eststo reg1: reghdfe D.`depvar' D.ln_mw, ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")
		
	scalar static_effect = _b[D.ln_mw]
	scalar static_effect_se = _se[D.ln_mw]

	eststo: reghdfe D.`depvar' D.ln_mw,	///
		absorb(`absorb' i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")

	eststo: reghdfe D.`depvar' D.ln_mw, ///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")
end

program run_static_model_controls
	syntax, depvar(str) absorb(str) cluster(str)

	eststo clear

	define_controls
	local emp_cont "`r(emp_cont)'"
	local establish_cont "`r(establish_cont)'"
	local wage_cont "`r(wage_cont)'"
	local housing_cont "`r(housing_cont)'"

	eststo: reghdfe D.`depvar' D.ln_mw D.ln_med_list_psqft_sfcc,	///
		absorb(`absorb' zipcode) ///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("No") est_cov("No") wage_cov("No") housing_cov("No")

	eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_cont') D.ln_med_list_psqft_sfcc, ///
		absorb(`absorb' zipcode) ///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("No") wage_cov("No") housing_cov("No")

	eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_cont') D.(`establish_cont') D.ln_med_list_psqft_sfcc, ///
		absorb(`absorb' zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("No") housing_cov("No")

	eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_cont') D.(`establish_cont') D.(`wage_cont') D.ln_med_list_psqft_sfcc, ///
		absorb(`absorb' zipcode) 		///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("No")

	eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_cont') D.(`establish_cont') D.(`wage_cont') `housing_cont' D.ln_med_list_psqft_sfcc, ///
		absorb(`absorb' zipcode) ///
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
	eststo reg1: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.ln_med_list_psqft_sfcc, ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")
		
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
	estadd scalar p_value_F = r(p)
			
	eststo lincom1: lincomest `lincomest_coeffs'
	comment_table, trend_lin("No") trend_sq("No")

	eststo reg2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if' D.ln_med_list_psqft_sfcc, ///
		absorb(`absorb' i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")

	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
	estadd scalar p_value_F = r(p)

	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_full se_full)
		
		keep if !missing(at)

		gen b_full_lb = b_full - 1.645*se_full
		gen b_full_ub = b_full + 1.645*se_full
			
		gen static_path = 0 if at <= `w' 
		replace static_path = scalar(static_effect) if at > `w'
		gen static_path_lb = 0 if at <= `w'
		replace static_path_lb = scalar(static_effect) - 1.645*scalar(static_effect_se) if at > `w'
		gen static_path_ub = 0 if at <= `w'
		replace static_path_ub = scalar(static_effect) + 1.645*scalar(static_effect_se) if at > `w'
			
		save "../temp/plot_coeffs.dta", replace
	restore

	eststo lincom2: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("No")
				
	qui reghdfe D.`depvar' L(0/`w').D.ln_mw D.ln_med_list_psqft_sfcc, ///
		absorb(`absorb' zipcode) ///
		vce(cluster `cluster') nocons
				
	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_lags se_lags)
		tset at

		keep if !missing(at)

		gen b_lags_lb = b_lags - 1.645*se_lags
		gen b_lags_ub = b_lags + 1.645*se_lags
			
		gen cumsum_b_lags = b_lags[1]
		replace cumsum_b_lags = cumsum_b_lags[_n-1] + b_lags[_n] if _n > 1
			
		replace at = at + `w'
			
		merge 1:1 at using "../temp/plot_coeffs.dta", nogen
		replace cumsum_b_lags = 0 if at <= `w'
		sort at
			
		// To prevent lines from overlapping perfectly
		gen at_full = at - 0.09
		gen at_lags = at + 0.09
		replace at_full = at if _n <= `w'
		replace at_lags = at if _n <= `w'

		replace cumsum_b_lags = cumsum_b_lags - 0.00007 if _n <= `w'
		replace static_path = static_path + 0.00007 if _n <= `w'

		// Figure
		make_plot_xlabels, w(`w')
		local xlab "`r(xlab)'"
		twoway (connected b_full at_full, mcol(navy) lcol(navy) lw(thin)) ///
			(rcap b_full_lb b_full_ub at_full, col(navy) lp(dash) lw(vthin)), ///
			yline(0, lcol(black)) ///
			xlabel(`xlab', labsize(small)) xtitle("Leads and lags of ln MW") ///
			ylabel(-0.3(0.1).5, grid labsize(small) angle(90)) ytitle("Effect on ln number of listings") ///			
			legend(off)
		graph export "../output/fd_models_nlist.png", replace
	restore 

	eststo reg3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if' D.ln_med_list_psqft_sfcc, ///
		absorb(`absorb' i.zipcod c.trend_times2#i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")

	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
	estadd scalar p_value_F = r(p)

	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("Yes") 
end

program run_dynamic_model_controls
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5)]
	
	eststo clear
	define_controls
	local emp_cont "`r(emp_cont)'"
	local establish_cont "`r(establish_cont)'"
	local wage_cont "`r(wage_cont)'"
	local housing_cont "`r(housing_cont)'"

	local lincomest_coeffs "D1.ln_mw + LD.ln_mw"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.ln_mw"
	}

	eststo clear
	eststo reg1: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if', ///
		absorb(`absorb' i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("No") est_cov("No") wage_cov("No") housing_cov("No")
		
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
	estadd scalar p_value_F = r(p)

	store_dynamic_coeffs, model(base) w(`w')
			
	eststo lincom1: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("No") est_cov("No") wage_cov("No") housing_cov("No")

	eststo reg2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_cont') `if', ///
		absorb(`absorb' i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("No") wage_cov("No") housing_cov("No")

	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
	estadd scalar p_value_F = r(p)

	store_dynamic_coeffs, model(emp) w(`w')

	eststo lincom2: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("Yes") est_cov("No") wage_cov("No") housing_cov("No")

	eststo reg3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_cont') D.(`establish_cont') `if',		///
		absorb(`absorb' i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("No") housing_cov("No")

	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
	estadd scalar p_value_F = r(p)

	store_dynamic_coeffs, model(est) w(`w')

	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("No") housing_cov("No")

	eststo reg4: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_cont') D.(`establish_cont') D.(`wage_cont') `if',		///
		absorb(`absorb' i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("No")

	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
	estadd scalar p_value_F = r(p)

	store_dynamic_coeffs, model(wage) w(`w')

	eststo lincom4: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("No")

	eststo reg5: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_cont') D.(`establish_cont') D.(`wage_cont') `housing_cont' `if',		///
		absorb(`absorb' i.zipcode) 	///
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

		gen b_house_lb = b_house - 1.645*se_house
		gen b_house_ub = b_house + 1.645*se_house

		merge 1:1 at using "../temp/plot_coeffs_base.dta", nogen
		merge 1:1 at using "../temp/plot_coeffs_emp.dta", nogen
		merge 1:1 at using "../temp/plot_coeffs_est.dta", nogen
		merge 1:1 at using "../temp/plot_coeffs_wage.dta", nogen

		sort at 

		g at_emp   = at - 0.2
		g at_est   = at - 0.1
		g at_wage  = at + 0.1
		g at_house = at + 0.2

		local period0 = `w' + 1

		twoway (scatter b_base at, mc(black))        (rcap b_base_lb b_base_ub at, lc(black) lp(dash) lw(vthin)) ///
			   (scatter b_emp at_emp, mc(edkblue))    (rcap b_emp_lb b_emp_ub at_emp, lc(edkblue) lp(dash) lw(vthin)) ///
			   (scatter b_est at_est, mc(lavender))   (rcap b_est_lb b_est_ub at_est, lc(lavender) lp(dash) lw(vthin)) ///
			   (scatter b_wage at_wage, mc(dkorange)) (rcap b_wage_lb b_wage_ub at_wage, lc(dkorange) lp(dash) lw(vthin)) ///
			   (scatter b_house at_house, mc(gs10)) (rcap b_house_lb b_house_ub at_house, lc(gs10) lp(dash) lw(vthin)), /// 
			yline(0, lcol(black)) xline(`period0', lcol(black)) ///
			graphregion(color(white)) bgcolor(white) ///
			xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" ///
			5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" ///
			10 "4" 11 "5", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln number of listings") ylabel(-0.3(0.05).5, grid labsize(small) angle(90))	///
			legend(order(1 "baseline" 3 "employment" ///
			5 "establishment" 7 "wage" 9 "building") size(small) rows(1))
		graph export "../output/fd_models_control_nlist.png", replace
	restore

	eststo lincom5: lincomest `lincomest_coeffs'
	comment_table_control, emp_cov("Yes") est_cov("Yes") wage_cov("Yes") housing_cov("Yes")
end


program run_static_placebo
	syntax, depvar(str) placebovar(str) absorb(str) cluster(str) [covars(str)]

	eststo clear
	eststo: reghdfe D.`depvar' D.ln_mw, ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	eststo: reghdfe D.`depvar' D.ln_mw D.(`placebovar'), ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons	
	
	eststo: reghdfe D.`placebovar' D.ln_mw,	///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	eststo: reghdfe D.`placebovar' D.ln_mw D.(`covars'), ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons
end

program plot_dynamic_placebo 
	syntax, depvar(str) placebovar(str) absorb(str) cluster(str) [covars(str) w(int 5)]

	eststo clear
	eststo: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`placebovar'), ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons
	store_dynamic_coeffs, model(base) w(`w')

	eststo: reghdfe D.`placebovar' L(-`w'/`w').D.ln_mw, ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons
	store_dynamic_coeffs, model(placebo0) w(`w')

	eststo: reghdfe D.`placebovar' L(-`w'/`w').D.ln_mw D.(`covars'), ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons


	preserve
		coefplot, vertical base gen
		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep __at __b __se
		rename (__at __b __se) (at b_placebo1 se_placebo1)
		keep if !missing(at)

		gen b_placebo1_lb = b_placebo1 - 1.645*se_placebo1
		gen b_placebo1_ub = b_placebo1 + 1.645*se_placebo1

		merge 1:1 at using "../temp/plot_coeffs_base.dta", nogen		
		merge 1:1 at using "../temp/plot_coeffs_placebo0.dta", nogen

		sort at 

		g at_placebo0   = at - 0.1
		g at_placebo1 = at + 0.1

		local period0 = `w' + 1

		twoway (connected b_base at, mc(edkblue) lc(edkblue) lw(thin))        (rcap b_base_lb b_base_ub at, lc(edkblue) lp(dash) lw(vthin)), ///
			graphregion(color(white)) bgcolor(white) ///
			xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" ///
			5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" ///
			10 "4" 11 "5", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln rent") ///
			ylabel(-0.06(0.02).08, grid labsize(small) angle(90)) ///
			yline(0, lcol(black)) legend(off)
		graph export "../output/fd_model_nlistcontrol.png", replace

		twoway (connected b_placebo0 at_placebo0, mc(gs10) lc(gs10) lw(thin)) (rcap b_placebo0_lb b_placebo0_ub at_placebo0, lc(gs10) lp(dash) lw(vthin)) ///
			(connected b_placebo1 at_placebo1, mc(edkblue) lc(edkblue) lw(thin)) (rcap b_placebo1_lb b_placebo1_ub at_placebo1, lc(edkblue) lp(dash) lw(vthin)), /// 
			graphregion(color(white)) bgcolor(white) ///
			xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" ///
			5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" ///
			10 "4" 11 "5", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln No. listings") ylabel(-0.3(0.1).5, grid labsize(small) angle(90))	///
			yline(0, lcol(black)) ///
			legend(order(1 "No Covariates" 3 "{&Delta}X{subscript: it} = {&Delta} ln median listing price"))
		graph export "../output/fd_placebo_comparison.png", replace
	restore

end 

program define_controls, rclass
	
  	local emp_cont             "ln_emp_leis ln_emp_goodpr ln_emp_const ln_emp_transp"
  	local emp_cont `"`emp_cont' ln_emp_bizserv ln_emp_eduhe ln_emp_fedgov ln_emp_info"'
  	local emp_cont `"`emp_cont' ln_emp_manu ln_emp_natres ln_emp_servpr ln_emp_stgov"'
  	return local emp_cont "`emp_cont'"

	local establish_cont 				   "ln_estcount_leis ln_estcount_goodpr ln_estcount_const ln_estcount_transp"
	local establish_cont `"`establish_cont' ln_estcount_bizserv ln_estcount_eduhe ln_estcount_fedgov ln_estcount_info"'
	local establish_cont `"`establish_cont' ln_estcount_manu ln_estcount_natres ln_estcount_servpr ln_estcount_stgov"'
	return local establish_cont "`establish_cont'"

	local wage_cont      		 "ln_avgwwage_leis ln_avgwwage_goodpr ln_avgwwage_const ln_avgwwage_transp"
	local wage_cont `"`wage_cont' ln_avgwwage_bizserv ln_avgwwage_eduhe ln_avgwwage_fedgov ln_avgwwage_info"'
	local wage_cont `"`wage_cont' ln_avgwwage_manu ln_avgwwage_natres ln_avgwwage_servpr ln_avgwwage_stgov"'
	return local wage_cont "`wage_cont'"

	local housing_cont   "ln_u1rep_units ln_u1rep_value"
	return local housing_cont "`housing_cont'"
end 

program comment_table
	syntax, trend_lin(str) trend_sq(str)

	estadd local zs_trend 		"`trend_lin'"	
	estadd local zs_trend_sq 	"`trend_sq'"
end

program comment_table_control
	syntax, emp_cov(str) est_cov(str) wage_cov(str) housing_cov(str)

	estadd local ctrl_emp      "`emp_cov'"
	estadd local ctrl_estab   "`est_cov'"
	estadd local ctrl_wage "`wage_cov'"
	estadd local ctrl_building    "`housing_cov'"
end 

program store_dynamic_coeffs
	syntax, model(str) w(int)
	preserve
		coefplot, vertical base gen
		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep __at __b __se
		rename (__at __b __se) (at b_`model' se_`model')
	
		keep if !missing(at)

		gen b_`model'_lb = b_`model' - 1.645*se_`model'
		gen b_`model'_ub = b_`model' + 1.645*se_`model'
	
		save "../temp/plot_coeffs_`model'.dta", replace
	restore
end 

program make_results_labels, rclass
		
		local estlabels_dyn `"            F5D.ln_mw "$\Delta \ln(MW)_{t-5}$" F4D.ln_mw "$\Delta \ln(MW)_{t-4}$""'
		local estlabels_dyn `"`estlabels_dyn' F3D.ln_mw "$\Delta \ln(MW)_{t-3}$" F2D.ln_mw "$\Delta \ln(MW)_{t-2}$""'
		local estlabels_dyn `"`estlabels_dyn' FD.ln_mw "$\Delta \ln(MW)_{t-1}$" D.ln_mw "$\Delta \ln(MW)_{t}$""'
		local estlabels_dyn `"`estlabels_dyn' LD.ln_mw "$\Delta \ln(MW)_{t+1}$" L2D.ln_mw "$\Delta \ln(MW)_{t+2}$""'
		local estlabels_dyn `"`estlabels_dyn' L3D.ln_mw "$\Delta \ln(MW)_{t+3}$" L4D.ln_mw "$\Delta \ln(MW)_{t+4}$""'
		local estlabels_dyn `"`estlabels_dyn' L5D.ln_mw "$\Delta \ln(MW)_{t+5}$""'

		return local estlabels_dyn "`estlabels_dyn'"	

		local estlabels_static `"D.ln_mw "$\Delta \ln(MW)_{t}$""'
		return local estlabels_static "`estlabels_static'"
end 

program make_plot_xlabels, rclass 
	syntax, w(int)

	local xlab ""
	forval lead = 1/`w' {
		local leadlab = `lead' - `w' - 1
		local xlab `"`xlab' `lead' "`leadlab'""'
	}
	local zero = `w' + 1
	local xlab `"`xlab' `zero' "0""'
	forval lag = 1/`w' {
		local coeflag = `zero' + `lag'
		local xlab `"`xlab' `coeflag' "`lag'""'
	}

	return local xlab `xlab'
end 

main
