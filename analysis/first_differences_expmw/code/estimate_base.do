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
	local estlabels_dyn            "`r(estlabels_dyn)'"
	local estlabels_static         "`r(estlabels_static)'"
	local estlablels_static_groups "`r(estlablels_static_groups)'"

	* Static Model - Experienced
	run_static_expgroup, depvar(ln_med_rent_psqft_sfcc) treatvar(Dln_exp_mw_totjob) absorb(year_month) ///
		cluster(statefips)

	esttab * using "`outstub'/fd_table_expmw_groups.tex", compress se replace substitute(\_ _) 	///
		coeflabels(`estlablels_static_groups') ///
		stats(zs_trend zs_trend_sq r2 N, fmt(%s3 %s3 %9.3f %9.0gc) ///
		labels("Zipcode-specifc linear trend" ///
		"Zipcode-specific quadratic trend"	///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) ///
		nonote nomtitles 
	
	run_static_exptot, depvar(ln_med_rent_psqft_sfcc) treatvar(ln_exp_mw_totjob) absorb(year_month) ///
		cluster(statefips)
	esttab * using "`outstub'/fd_table_expmw.tex", keep(D.ln_exp_mw_totjob) compress se replace substitute(\_ _) 	///
		coeflabels(`estlabels_static') ///
		stats(zs_trend zs_trend_sq r2 N, fmt(%s3 %s3 %9.3f %9.0gc) ///
		labels("Zipcode-specifc linear trend" ///
		"Zipcode-specific quadratic trend"	///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) ///
		nonote nomtitles

	* Dynamic Model

	run_dynamic_expgroup, depvar(ln_med_rent_psqft_sfcc) treatvar(Dln_exp_mw_totjob) absorb(year_month) ///
		cluster(statefips)

	/* run_dynamic_exptot, depvar(ln_med_rent_psqft_sfcc) treatvar(ln_exp_mw_totjob) absorb(year_month) ///
		cluster(statefips)
	esttab reg1 reg2 reg3 using "`outstub'/fd_dynamic_table_expmw.tex", ///
		keep(*.ln_exp_mw_totjob) compress se replace substitute(\_ _) ///
		coeflabels(`estlabels_dyn') ///
		stats(p_value_F zs_trend zs_trend_sq r2 N, fmt(%9.3f %s3 %s3 %9.3f %9.0gc) ///
		labels("P-value no pretrends" "Zipcode-specifc linear trend" ///
		"Zipcode-specific quadratic trend" ///
		"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) 	///
		nonote nomtitles

	esttab lincom1 lincom2 lincom3 using "`outstub'/fd_dynamic_lincom_table_expmw.tex", ///
		compress se replace ///
		stats(zs_trend zs_trend_sq cty_emp_wg N, fmt(%s3 %s3 %s3 %9.0gc) ///
		labels("Zipcode-specifc linear trend" ///
		"Zipcode-specific quadratic trend" ///
		"Observations")) ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		nonote coeflabel((1) "Sum of MW effects") nomtitles */

end

program run_static_exptot
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str)

	eststo clear
	eststo reg1: reghdfe D.`depvar' D.`treatvar', ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")
		
	//scalar static_effect = _b[`treatvar']
	//scalar static_effect_se = _se[`treatvar']

	eststo: reghdfe D.`depvar' D.`treatvar',	///
		absorb(`absorb' i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")

	eststo: reghdfe D.`depvar' D.`treatvar', ///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")
end

program run_static_expgroup
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str)

	eststo clear
	eststo reg1: reghdfe D.`depvar' c.`treatvar'#i.treat, ///
		absorb(`absorb' treat) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")
		
	//scalar static_effect = _b[`treatvar']
	//scalar static_effect_se = _se[`treatvar']

	eststo: reghdfe D.`depvar' c.`treatvar'#i.treat,	///
		absorb(`absorb' i.zipcode treat) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")

	eststo: reghdfe D.`depvar' c.`treatvar'#i.treat, ///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode treat) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")
end


program run_dynamic_exptot
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str) [w(int 5)]

	local lincomest_coeffs "D1.`treatvar' + LD.`treatvar'"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.`treatvar'"
	}

	eststo clear
	eststo reg1: reghdfe D.`depvar' L(-`w'/`w').D.`treatvar', ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")
	test (F5D.`treatvar' = 0) (F4D.`treatvar' = 0) (F3D.`treatvar' = 0) (F2D.`treatvar' = 0) (F1D.`treatvar' = 0)
	estadd scalar p_value_F = r(p)
			
	eststo lincom1: lincomest `lincomest_coeffs'
	comment_table, trend_lin("No") trend_sq("No")

	eststo reg2: reghdfe D.`depvar' L(-`w'/`w').D.`treatvar' `if', ///
		absorb(`absorb' i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")

	test (F5D.`treatvar' = 0) (F4D.`treatvar' = 0) (F3D.`treatvar' = 0) (F2D.`treatvar' = 0) (F1D.`treatvar' = 0)
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
				
	qui reghdfe D.`depvar' L(0/`w').D.`treatvar', ///
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
		save "../temp/plot_coeffs_base.dta", replace
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
		twoway (scatter b_full at_full, mcol(navy)) ///
			(rcap b_full_lb b_full_ub at_full, col(navy) lp(dash) lw(vthin)) ///
			(scatter b_lags at_lags, mcol(maroon)) ///
			(rcap b_lags_lb b_lags_ub at_lags, col(maroon) lp(dash) lw(vthin)) ///
			(line static_path at, lcol(gs4) lpat(dash)) ///
			(line cumsum_b_lags at, lcol(maroon)), ///
			yline(0, lcol(black)) ///
			xlabel(`xlab', labsize(small)) xtitle("Leads and lags of ln MW") ///
			ylabel(-0.2(0.05).4, grid labsize(small)) ytitle("Effect on ln rent per sqft") ///			
			legend(order(1 "Full dynamic model" 3 "Distributed lags model" ///
			5 "Effects path static model" 6 "Effects path distributed lags model") size(small))
		graph export "../output/fd_models.png", replace
	restore 

	eststo reg3: reghdfe D.`depvar' L(-`w'/`w').D.`treatvar' `if', ///
		absorb(`absorb' i.zipcod c.trend_times2#i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")

	test (F5D.`treatvar' = 0) (F4D.`treatvar' = 0) (F3D.`treatvar' = 0) (F2D.`treatvar' = 0) (F1D.`treatvar' = 0)
	estadd scalar p_value_F = r(p)

	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("Yes") 
end

program run_dynamic_expgroup
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str) [w(int 5)]

	tab treat, g(treat_dummy)
	g Dln_exp_mw_dir = `treatvar' * treat_dummy2
	g Dln_exp_mw_ind = `treatvar' * treat_dummy3

	local dyntreat_dir ""
	local dyntreat_ind ""
	forval t = `w'(-1)1 {
		g F`t'Dln_exp_mw_dir = F`t'.Dln_exp_mw_dir
		local dyntreat_dir `"`dyntreat_dir' F`t'Dln_exp_mw_dir"'
		g F`t'Dln_exp_mw_ind = F`t'.Dln_exp_mw_ind
		local dyntreat_ind `"`dyntreat_ind' F`t'Dln_exp_mw_ind"'
	}
	forval t = 0/`w' {
		g L`t'Dln_exp_mw_dir = L`t'.Dln_exp_mw_dir
		local dyntreat_dir `"`dyntreat_dir' L`t'Dln_exp_mw_dir"'
		g L`t'Dln_exp_mw_ind = L`t'.Dln_exp_mw_ind
		local dyntreat_ind `"`dyntreat_ind' L`t'Dln_exp_mw_ind"'		
	}


	/* local lincomest_coeffs "D1.`treatvar' + LD.`treatvar'"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.`treatvar'"
	} */

	eststo clear
	eststo reg1: reghdfe D.`depvar' `dyntreat_dir' `dyntreat_ind' , ///
		absorb(`absorb' zipcode treat) ///
		vce(cluster `cluster') nocons
STOP 
				
	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_ se_)
		tset at
		keep if !missing(at)

		local winlen = 2*`w' + 1
		g treat_type = "dir" if _n <=`winlen'
		replace treat_type = "ind" if _n > `winlen'
		replace at = at - `winlen' if at >`winlen'
		reshape wide b_ se_, i(at) j(treat_type) string
		
		foreach t in dir ind {
			gen b_`t'_lb = b_`t' - 1.645*se_`t'
			gen b_`t'_ub = b_`t' + 1.645*se_`t'
		}

		// To prevent lines from overlapping perfectly
		gen at_dir = at - 0.09
		gen at_ind = at + 0.09
	
		// Figure
		make_plot_xlabels, w(`w')
		local xlab "`r(xlab)'"
		twoway (scatter b_dir at_dir, mcol(edkblue)) ///
			(rcap b_dir_lb b_dir_ub at_dir, col(edkblue) lp(dash) lw(vthin)) ///
			(scatter b_ind at_ind, mcol(olive_teal)) ///
			(rcap b_ind_lb b_ind_ub at_ind, col(olive_teal) lp(dash) lw(vthin)), ///
			yline(0, lcol(black)) ///
			xlabel(`xlab', labsize(small)) xtitle("Leads and lags of {&Delta}ln(exp. MW)") ///
			ylabel(-0.2(0.05).25, grid labsize(small)) ytitle("Effect on {&Delta}ln(rent/SqFt)") ///			
			legend(order(1 "Direct" 3 "Indirect") size(small))
		graph export "../output/fd_models_expgroup.png", replace
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
		
	local estlabels_dyn `"            F5D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t-5}$" F4D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t-4}$""'
	local estlabels_dyn `"`estlabels_dyn' F3D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t-3}$" F2D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t-2}$""'
	local estlabels_dyn `"`estlabels_dyn' FD.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t-1}$" D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t}$""'
	local estlabels_dyn `"`estlabels_dyn' LD.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t+1}$" L2D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t+2}$""'
	local estlabels_dyn `"`estlabels_dyn' L3D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t+3}$" L4D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t+4}$""'
	local estlabels_dyn `"`estlabels_dyn' L5D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t+5}$""'

	return local estlabels_dyn "`estlabels_dyn'"	

	local estlabels_static `"D.ln_exp_mw_totjob "$\Delta \ln(exp MW)_{t}$""'
	return local estlabels_static "`estlabels_static'"

	local estlablels_static_groups `"0.treat#c.Dln_exp_mw_totjob "$\Delta \ln(exp MW)_{t} \times Treat_{t}= indirect$""'
	local estlablels_static_groups `"`estlablels_static_groups' 1.treat#c.Dln_exp_mw_totjob "$\Delta \ln(exp MW)_{t} \times Treat_{t} = direct$""'
	return local estlablels_static_groups "`estlablels_static_groups'"

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
