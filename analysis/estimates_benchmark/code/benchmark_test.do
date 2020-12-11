clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 


program main 
	local instub "../temp"
	local instub_wage "../../../derived/benchmark/output"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	

	make_qcew_regression_col, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) cluster(statefips) wagevar(avg_d_ln_mwage) instub_wage(`instub_wage') outstub(`outstub')
	make_dube_col, depvar(ln_med_rent_psqft_sfcc) treatvar(ln_expmw) absorb(year_month) mww_share_stub(sh_mww) cluster(statefips) outstub(`outstub')
	esttab * using "`outstub'/incidence_table.tex", cells(none) noobs replace substitute(\_ _) posthead("") ///
		stats(space space space ///
			  effect_rent_mw effect_wage_mw avg_ratio_mw ///
			  space space space     ///
			  effect_rent_expmw effect_wage_expmw avg_ratio_expmw, ///
			  fmt(%s1 %s1 %s1 ///
			  	%9.3f %9.3f %9.3f ///
				%s1 %s1 %s1 ///
			  	%9.3f %9.3f %9.3f) ///
			  labels("\vspace{-2mm}" "\textit{\textbf{Panel A: Statutory MW}}" "\hline" ///
			  	"Rent Elasticity" "Avg. Wage Elasticity" "Pass-Through" ///
			  	"\vspace{1mm}" "\textit{\textbf{Panel B: Experienced MW}}" "\hline" ///
			  	"Rent Elasticity" "Avg. Wage Elasticity" "Pass-Through")) ///
		mtitles("\shortstack{QCEW \\ regression}" ///
		    "\shortstack{Dube et \\al. (2019)}") ///
	star(* 0.10 ** 0.05 *** 0.01)
 
	

	****OLD STUFF
	//incidence_formula_dist, depvar(ln_med_rent_psqft_sfcc) treatvar(ln_mw) absorb(year_month) cluster(statefips) mww_share_stub(sh_mww) outstub(`outstub')


	/* foreach win in 5 {
		benchmark_plot_all2, depvar(ln_med_rent_psqft) w(`win') absorb(year_month zipcode) cluster(statefips) outstub(`outstub') ///
							 beta_low(`beta_low') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k')
		graph export `outstub'/benchmark_all2_w`win'_ziptrend_base.png, replace

		benchmark_plot_wmean, depvar(ln_med_rent_psqft) w(`win') absorb(year_month zipcode) cluster(statefips) outstub(`outstub') ///
							 beta_low(`beta_low') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k')
		graph export `outstub'/benchmark_wmean2_w`win'_ziptrend_base.png, replace	
	} */	
end 


program make_dube_col 
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str) mww_share_stub(str) outstub(str) [w(int 5) dynamic(str)]
	
	*PANEL A: ACTUAL MW 
	incidence_comparison_dube2019, depvar(ln_med_rent_psqft_sfcc) ///
	treatvar(ln_mw) absorb(year_month) mww_share_stub(sh_mww) ///
	cluster(statefips) outstub(`outstub')
   	
   	*PANEL B: EXPERIENCED MW 	
	incidence_comparison_dube2019, depvar(ln_med_rent_psqft_sfcc) ///
	treatvar(ln_expmw) absorb(year_month) mww_share_stub(sh_mww) ///
	cluster(statefips) outstub(`outstub')

	estadd local space ""

end


program make_qcew_regression_col
	syntax, depvar(str) absorb(str) cluster(str) wagevar(str) instub_wage(str) outstub(str) [w(int 5) dynamic(str)]	

	*PANEL A: ACTUAL MW 
	incidence_formula_avg_reg, depvar(`depvar') treatvar(ln_mw) ///
							   absorb(`absorb') cluster(`cluster') wagevar(`wagevar') ///
							   instub_wage(`instub_wage') outstub(`outstub')
	
   	*PANEL B: EXPERIENCED MW 
	incidence_formula_avg_reg, depvar(`depvar') treatvar(ln_expmw) ///
							   absorb(`absorb') cluster(`cluster') wagevar(`wagevar') ///
							   instub_wage(`instub_wage') outstub(`outstub')

   	estadd local space ""
end

program incidence_comparison_dube2019
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str) mww_share_stub(str) outstub(str) [w(int 5) dynamic(str)]

	if "`treatvar'"=="ln_mw" {
		eststo dube: reghdfe D.`depvar' D.`treatvar', ///
				absorb(`absorb')        ///
				vce(cluster `cluster') nocons		
	}
	else {
		qui reghdfe D.`depvar' D.`treatvar', ///
				absorb(`absorb')        ///
				vce(cluster `cluster') nocons				
	}
	local r = _b[D.`treatvar']

	cap g estsample = e(sample)
	local treatsamp   = subinstr("`treatvar'", "ln_", "", .)
	local eventsample = "D.`treatsamp'>0 & estsample==1"

	local Daffected_wages = 0.068
	local Affected_jobs   = 0.086
	local avg_Dmw     = 10.1

	qui sum `mww_share_stub' if `eventsample'
	local avg_sh_mww  = r(mean)

	local effect_wage = ((`Daffected_wages' / `avg_Dmw')*`avg_sh_mww') * 100
	local avg_ratio = `r' / `effect_wage'

	if "`treatvar'"=="ln_mw" {
		estadd scalar effect_rent_mw `r' : dube
		estadd scalar effect_wage_mw `effect_wage' : dube 
		estadd scalar avg_ratio_mw `avg_ratio' : dube
	}
	else if "`treatvar'"=="ln_expmw" {
		estadd scalar effect_rent_expmw `r' : dube
		estadd scalar effect_wage_expmw `effect_wage' : dube
		estadd scalar avg_ratio_expmw `avg_ratio' : dube
	}
end 

program incidence_formula_avg_reg
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str) wagevar(str) instub_wage(str) outstub(str) [w(int 5) dynamic(str)]
	
	qui reghdfe D.`depvar' D.`treatvar', ///
			absorb(`absorb')        ///
			vce(cluster `cluster') nocons
	local r = _b[D.`treatvar']

	preserve
	keep countyfips 
	duplicates drop 
	tempfile samplecty 
	save "`samplecty'", replace 
	use `instub_wage'/mw_wage_panel.dta, clear 
	merge m:1 countyfips using `samplecty', nogen assert(1 2 3) keep(3)
	sort countyfips quarter
	reghdfe `wagevar' d_`treatvar', absorb(quarter countyfips statefips) nocons
	local effect_wage = _b[d_`treatvar']
	restore

	local avg_ratio = `r' / `effect_wage'

	if "`treatvar'"=="ln_mw" {
		eststo qcew_reg: qui reghdfe D.`depvar' D.`treatvar', ///
				absorb(`absorb')        ///
				vce(cluster `cluster') nocons		
	}
	else {
		qui reghdfe D.`depvar' D.`treatvar', ///
				absorb(`absorb')        ///
				vce(cluster `cluster') nocons				
	}
	if "`treatvar'"=="ln_mw" {	
		estadd scalar effect_rent_mw `r' : qcew_reg
		estadd scalar effect_wage_mw `effect_wage' : qcew_reg
		estadd scalar avg_ratio_mw `avg_ratio' : qcew_reg
	}
	else if "`treatvar'"=="ln_expmw" {
		estadd scalar effect_rent_expmw `r' : qcew_reg
		estadd scalar effect_wage_expmw `effect_wage' : qcew_reg
		estadd scalar avg_ratio_expmw `avg_ratio' : qcew_reg
	}
end 


program incidence_formula_avg
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str) mww_share_stub(str) outstub(str) [w(int 5) dynamic(str)]

	eststo: qui reghdfe D.`depvar' D.`treatvar', ///
			absorb(`absorb')        ///
			vce(cluster `cluster') nocons
	local r = _b[D.`treatvar']

	if "`dynamic'"=="yes" {
		eststo: qui reghdfe D.`depvar' L(0/`w').D.`treatvar', ///
			absorb(`absorb') ///
			vce(cluster `cluster') nocons		
		qui lincomest D1.`treatvar' + LD.`treatvar' + L2D.`treatvar' + L3D.`treatvar' + L4D.`treatvar' + L5D.`treatvar' 
		matrix A = e(b)
		local r = A[1,1]	
	}
	cap g estsample = e(sample)
	local treatsamp   = subinstr("`treatvar'", "ln_", "", .)
	local eventsample = "D.`treatsamp'>0 & estsample==1"



	qui sum dactual_mw if `eventsample'
	local avg_Dmw = r(mean)

	local avg_Dmmw_ft = `avg_Dmw' * 40 * 4.35
	local avg_Dmmw_pt = `avg_Dmw' * 20 * 4.35

	/* foreach mww_type in ft pt {
		qui g mww_`mww_type' = `mww_share_stub'_`mww_type' * workers_`mww_type' 
		qui sum mww_`mww_type' if `eventsample'
		local avg_mww_`mww_type' r(mean)
		local avg_Dincome_`mww_type' = `avg_Dmmw_`mww_type'' * `avg_mww_`mww_type''		
	} */
	cap g tot_pinc_month    = tot_pinc20105 / 12 
	qui sum tot_pinc_month if F.`treatsamp'>0 & estsample==1
	local avg_tot_pinc20105 = r(mean)

	//local avg_Dincome_pct = ((`avg_Dincome_ft' + `avg_Dincome_pt') / `avg_tot_pinc20105')*100

	*instead of averaging all quantities first, I compute the pct change in total wage bill at the zipcode level, and take only one avg in the end
	qui g Dmmw_ft = dactual_mw * 40 * 4.35
	qui g Dmmw_pt = dactual_mw * 20 * 4.35
	foreach mww_type in ft pt {
		qui g mww_`mww_type' = `mww_share_stub'_`mww_type' * workers_`mww_type' 
		qui g Dincome_`mww_type' = Dmmw_`mww_type' * mww_`mww_type'
		qui sum Dincome_`mww_type' if `eventsample'
		local avg_Dincome_`mww_type' = r(mean)
	}
	g Dincome_pct = ((Dincome_ft + Dincome_pt) / tot_pinc_month)*100
	sum Dincome_pct if `eventsample'
	local avg_Dincome_pct = r(mean)
	

	sum d_`treatvar' if `eventsample'
	local avg_Dmw_pct = r(mean)*100
	local avg_r       = `r' * `avg_Dmw_pct'

	local avg_ratio = `avg_r' / `avg_Dincome_pct'

	estadd scalar effect_rent `avg_r'
	estadd scalar effect_wage `avg_Dincome_pct'
	estadd scalar avg_ratio `avg_ratio'
end  

program incidence_formula_avg1pct
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str) mww_share_stub(str) outstub(str) [w(int 5) dynamic(str)]

	eststo: qui reghdfe D.`depvar' D.`treatvar', ///
			absorb(`absorb')        ///
			vce(cluster `cluster') nocons
	local r = _b[D.`treatvar']
	 if "`dynamic'"=="yes" {
		eststo: qui reghdfe D.`depvar' L(0/`w').D.`treatvar', ///
			absorb(`absorb') ///
			vce(cluster `cluster') nocons		
		qui lincomest D1.`treatvar' + LD.`treatvar' + L2D.`treatvar' + L3D.`treatvar' + L4D.`treatvar' + L5D.`treatvar' 
		matrix A = e(b)
		local r = A[1,1]	
	}
	cap g estsample   = e(sample)
	local treatsamp   = subinstr("`treatvar'", "ln_", "", .)
	local eventsample = "D.`treatsamp'>0 & estsample==1"
	
	g Dmw_1pct       = L.`treatsamp'            if `eventsample'
	replace Dmw_1pct = Dmw_1pct*1.01            if `eventsample'
	replace Dmw_1pct = Dmw_1pct - L.`treatsamp' if `eventsample'
	qui sum Dmw_1pct if `eventsample'
	local avg_Dmw    = r(mean)

	/* local avg_Dmmw_ft = `avg_Dmw' * 40 * 4.35
	local avg_Dmmw_pt = `avg_Dmw' * 20 * 4.35

	foreach mww_type in ft pt {
		qui cap g mww_`mww_type' = `mww_share_stub'_`mww_type' * workers_`mww_type' 
		qui sum mww_`mww_type' if `eventsample'
		local avg_mww_`mww_type' r(mean)
		local avg_Dincome_`mww_type' = `avg_Dmmw_`mww_type'' * `avg_mww_`mww_type''		
	} */
	cap g tot_pinc_month    = tot_pinc20105 / 12 
	qui sum tot_pinc_month  if F.`treatsamp'>0 & estsample==1
	local avg_tot_pinc20105 = r(mean)

	qui g Dmmw_ft = Dmw_1pct * 40 * 4.35
	qui g Dmmw_pt = Dmw_1pct * 20 * 4.35
	foreach mww_type in ft pt {
		qui g mww_`mww_type' = `mww_share_stub'_`mww_type' * workers_`mww_type' 
		qui g Dincome_`mww_type' = Dmmw_`mww_type' * mww_`mww_type'
		qui sum Dincome_`mww_type' if `eventsample'
		local avg_Dincome_`mww_type' = r(mean)
	}
	g Dincome_pct = ((Dincome_ft + Dincome_pt) / tot_pinc_month)*100
	sum Dincome_pct if `eventsample'
	local avg_Dincome_pct = r(mean)

	//local avg_Dincome_pct = ((`avg_Dincome_ft' + `avg_Dincome_pt') / `avg_tot_pinc20105')*100

	local avg_ratio = `r' / `avg_Dincome_pct'

	estadd scalar effect_rent `r'
	estadd scalar effect_wage `avg_Dincome_pct'
	estadd scalar avg_ratio `avg_ratio'
end  

program incidence_formula_dist
	syntax, depvar(str) treatvar(str) absorb(str) cluster(str) mww_share_stub(str) outstub(str) [w(int 5) dynamic(str)]

	qui reghdfe D.`depvar' D.`treatvar', ///
			absorb(`absorb')        ///
			vce(cluster `cluster') nocons
	local r = _b[D.`treatvar']

	if "`dynamic'"=="yes" {
		qui reghdfe D.`depvar' L(0/`w').D.`treatvar', ///
			absorb(`absorb') ///
			vce(cluster `cluster') nocons		
		lincomest D1.`treatvar' + LD.`treatvar' + L2D.`treatvar' + L3D.`treatvar' + L4D.`treatvar' + L5D.`treatvar' 
		matrix A = e(b)
		local r = A[1,1]	
	}
	g estsample = e(sample)
	local treatsamp   = subinstr("`treatvar'", "ln_", "", .)
	local eventsample = "D.`treatsamp'>0 & estsample==1"

 	/* order actual_mw, last
	g Dmw_1pct = actual_mw * 1.01
	replace Dmw_1pct = Dmw_1pct - L.actual_mw - dactual_mw
	sum d_ln_mw if dactual_mw>0 & estsample==1 */

	g Dmmw_ft = D.`treatsamp' * 40 * 4.35 if `eventsample'
	g Dmmw_pt = D.`treatsamp' * 20 * 4.35 if `eventsample'

	g Dincome_ft = Dmmw_ft * `mww_share_stub'_ft * workers_ft if `eventsample'
	g Dincome_pt = Dmmw_pt * `mww_share_stub'_pt * workers_pt if `eventsample'

	g tot_pinc_month = tot_pinc20105 / 12 
	g Dincome_pct    = ((Dincome_ft + Dincome_pt) / L.tot_pinc_month)*100 if `eventsample'

	g r_pct = d_`treatvar' * 100 * `r'

	g ratio = r_pct / Dincome_pct

	winsor2 ratio, replace cuts(0 95)

	qui sum ratio
	local ratiomean = r(mean) 
	local ratiomean = round(`ratiomean', .01)
	local xratiolabel = `ratiomean' + 0.2
	twoway (hist ratio, color(edkblue%50)), xline(`ratiomean') text(1.5 `xratiolabel' "Average: `ratiomean'", size(small)) ylabel(, grid)
	graph export `outstub'/`treatsamp'_totwage_ratio_dist.png, replace
end

*#############################################
program benchmark_plot_all2
    syntax, depvar(str) w(int) absorb(str) cluster(str) outstub(str) beta_low(str) gamma_low(str) gamma_hi(str) k(str)
	
   local lincom_coeffs "L0.D.ln_mw"
    forval x = 1 / 1 {
    	local lincom_coeffs `"`lincom_coeffs' + L`x'.D.ln_mw"'
    }

    *Model 1 - DD static
    eststo model1: reghdfe D.`depvar' D.ln_mw,  ///
    					absorb(`absorb')         ///
    					vce(cluster `cluster') nocons

    *Model 2 - lags and leads
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model2: lincomest `lincom_coeffs'

	*model 3: lags only 
	reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model3: lincomest `lincom_coeffs'

	*benchmarks
	sum mww_shrenter_all1 if e(sample)
	local mww_share_rent1 = r(mean)
	sum mww_shrenter_all2 if e(sample)
	local mww_share_rent2 = r(mean)
	sum mww_shrenter_wmean2 if e(sample)
	local mww_share_rentm = r(mean)

	compute_benchmark, beta_low(`beta_low') s_low(`mww_share_rent1') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(total)
	local mod_rent1  = r(benchmark_total)
	compute_benchmark, beta_low(`beta_low') s_low(`mww_share_rent2') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(total_rent)
	local mod_rent2 = r(benchmark_total_rent)
	compute_benchmark, beta_low(`beta_low') s_low(`mww_share_rentm') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(rent)
	local mod_rentm = r(benchmark_rent)

	coefplot (model1, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename(D.ln_mw = "Static") keep(D.ln_mw))     ///
			 (model2, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Leads and lags"))          ///
	         (model3, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Lags only")), ///
 	yline(0, lc(gs11)) ylabel(-.05(0.05).1) legend(off) asequation vertical recast(bar)                           ///
 	citop barwidth(0.3) fcolor(*.5) nooffsets               													  ///
	yline(`mod_rentm', lcolor(cranberry) lp(shortdash)) 
	/* yline(`mod_rent2', lcolor(orange) lp(shortdash))          ///
	yline(`mod_rentm', lcolor(mint) lp(shortdash)) */
end

program benchmark_plot_wmean
    syntax, depvar(str) w(int) absorb(str) cluster(str) outstub(str) beta_low(str) gamma_low(str) gamma_hi(str) k(str)
	
    local lincom_coeffs "L0.D.ln_mw"
    forval x = 1 / 1 {
    	local lincom_coeffs `"`lincom_coeffs' + L`x'.D.ln_mw"'
    }

    *Model 1 - DD static
    eststo model1: reghdfe D.`depvar' D.ln_mw,  ///
    					absorb(`absorb')         ///
    					vce(cluster `cluster') nocons

    *Model 2 - lags and leads
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model2: lincomest `lincom_coeffs'

	*model 3: lags only 
	reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model3: lincomest `lincom_coeffs'

	*benchmarks
	sum medrentprice_sfcc if e(sample)
	local rent_month = r(mean)
	local week_hours = 40
	local mw_workers = 2
	sum actual_mw if e(sample)
	*** CHANGE HERE:
	local mw_month = r(mean) * `week_hours' * 4.35 * `mw_workers'
	//local mw_month = (r(mean) * `week_hours' * 4.35)*
	*******************
	local alpha = `mw_month' / `rent_month'
	
	sum mww_shrenter_all1 if e(sample)
	local mww_share_rent1 = r(mean)
	sum mww_shrenter_all2 if e(sample)
	local mww_share_rent2 = r(mean)
	sum mww_shrenter_wmean2 if e(sample)
	local mww_share_rentm = r(mean)

	compute_benchmark, beta_low(`beta_low') s_low(`mww_share_rent1') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(total)
	local mod_rent1  = r(benchmark_total)
	compute_benchmark, beta_low(`beta_low') s_low(`mww_share_rent2') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(total_rent)
	local mod_rent2 = r(benchmark_total_rent)
	compute_benchmark, beta_low(`beta_low') s_low(`mww_share_rentm') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(rent)
	local mod_rentm = r(benchmark_rent)

	coefplot (model1, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename(D.ln_mw = "Static") keep(D.ln_mw))     ///
			 (model2, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Leads and lags"))          ///
	         (model3, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Lags only")), ///
 	yline(0, lc(gs11)) ylabel(-.05(0.05).1) legend(off) asequation vertical recast(bar)                           ///
 	citop barwidth(0.3) fcolor(*.5) nooffsets               													  ///
	yline(`mod_rentm', lcolor(cranberry) lp(shortdash)) 
end

program benchmark_plot 
    syntax, depvar(str) w(int) absorb(str) cluster(str) outstub(str)
	
   local lincom_coeffs "L0.D.ln_mw"
    forval x = 1 / 1 {
    	local lincom_coeffs `"`lincom_coeffs' + L`x'.D.ln_mw"'
    }

    *Model 1 - DD static
    eststo model1: reghdfe D.`depvar' D.ln_mw,  ///
    					absorb(`absorb')         ///
    					vce(cluster `cluster') nocons

	*model 2: lags only 
	reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model2: lincomest `lincom_coeffs'

	*benchmarks
	qui sum sh_mww if e(sample)
	local sh_mww = r(mean)

	* Baseline parameters
	local beta_low = 0.471
	*From Albouy 2016 
	local gamma_low = - 0.719
	local gamma_hi = - 0.719
	*from Diamond
	local k = 0.1

	compute_benchmark, beta_low(`beta_low') s_low(`sh_mww') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(main)
	local bench_main = r(benchmark_main)
	compute_benchmark, beta_low(`beta_low') s_low(`sh_mww') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(hughes)
	local bench_hughes = r(benchmark_hughes)



	coefplot (model1, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename(D.ln_mw = "Static") keep(D.ln_mw))     ///
	         (model2, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Lags only")), ///
 	yline(0, lc(gs11)) ylabel(-.05(0.05).1) legend(off) asequation vertical recast(bar)                           ///
 	citop barwidth(0.3) fcolor(*.5) nooffsets               													  ///
	yline(`bench_main', lcolor(cranberry) lp(shortdash)) 
end 


program compute_benchmark, rclass
	syntax, beta_low(str) s_low(str) gamma_low(str) gamma_hi(str) k(str) name(str)

	local s_hi = 1 - `s_low'	

	local benchmark = (`beta_low' * `s_low') / (-(`gamma_low' * `s_low') - (`gamma_hi' * `s_hi') + `k')

	return scalar benchmark_`name' = `benchmark'
end 

main 