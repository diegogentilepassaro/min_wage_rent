clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main 
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	//het_desc
	//run_dynamic_model, depvar(ln_med_rent_psqft) absorb(year_month) cluster(statefips)
	
	//dynamic_het_model_0, depvar(ln_med_rent_psqft) absorb(year_month zipcode) cluster(statefips) het_char(rent_inc_ratio_qt) outstub(`outstub') n_qtl(4)
	//dynamic_het_model_bygroups, depvar(ln_med_rent_psqft) absorb(year_month zipcode) cluster(statefips) het_char(rent_inc_ratio_qt) outstub(`outstub') n_qtl(4)
	//dynamic_het_cumulpost_bygroups, depvar(ln_med_rent_psqft) absorb(year_month zipcode) cluster(statefips) het_char(rent_inc_ratio_qtl) outstub(`outstub') n_qtl(4)
	
	local geolevel = "st"
	local het_varlist = "med_hhinc20105_`geolevel'_qtl college_share20105_`geolevel'_qtl black_share2010_`geolevel'_qtl renthouse_share2010_`geolevel'_qtl poor_share20105_`geolevel'_qtl lo_hhinc_share20105_`geolevel'_qtl unemp_share20105_`geolevel'_qtl youngadult_share2010_`geolevel'_qtl employee_share20105_`geolevel'_qtl sh_mww_all2_`geolevel'_qtl sh_mww_renter_all2_`geolevel'_qtl mww_shrenter_all2_`geolevel'_qtl sh_mww_wmean_`geolevel'_qtl mww_shrenter_wmean_`geolevel'_qtl mww_shsub25_all2_`geolevel'_qtl mww_shsub25_all1_`geolevel'_qtl mww_shblack_all2_`geolevel'_qtl"
	//local het_varlist = "mww_shrenter_all2_`geolevel'_qtl sh_mww_wmean_`geolevel'_qtl mww_shrenter_wmean_`geolevel'_qtl"
	foreach var in `het_varlist' {
		
		//dynamic_het_model_0, depvar(ln_med_rent_psqft) absorb(year_month zipcode) cluster(statefips) het_char(`var') outstub(`outstub')	
		
		//dynamic_het_model_bygroups, depvar(ln_med_rent_psqft) absorb(year_month zipcode) cluster(statefips) het_char(`var') outstub(`outstub') n_qtl(4)
		
		//dynamic_het_cumulpost_bygroups, depvar(ln_med_rent_psqft) absorb(year_month zipcode) cluster(statefips) het_char(`var') outstub(`outstub') n_qtl(4)

	dynamic_het_cumulpost, depvar(ln_med_rent_psqft) absorb(year_month zipcode) cluster(statefips) het_char(`var') outstub(`outstub') w(5)
	}

	

end 


program het_desc
	hist rent_inc_ratio if year_month==tm(2010m1), bc(ebblue%70)

	binscatter rent_inc_ratio med_hhinc20105 if year_month==tm(2012m1), absorb(msa) control(i.state i.countyfips)
end 


program dynamic_het_model_0
	syntax, depvar(str) absorb(str) cluster(str) het_char(str) outstub(str) [w(int 5) n_qtl(int 4)]

	/* reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(`absorb' i.zipcode) 											///
		vce(cluster `cluster') nocons

	coefplot, vertical xline(6) yline(0) recast(connected) ylabel(-.1(.05).1, grid) */


	reghdfe D.`depvar' c.L(0/`w').d_ln_mw#ib(1).`het_char' L(-`w'/`w').d_ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons


		preserve
		qui coefplot, vertical base gen omit
		keep __at __b __se
		rename (__at __b __se) (at b se)
		tset at
	    keep if !missing(at)
	    local t_periods = (2*`w' + 1)
	    local coefkeep = `t_periods'*`n_qtl'
	    drop if _n > `coefkeep'
	    egen gr = seq(), from(1) to(`n_qtl')
	    egen t = seq(), from(1) to(`t_periods') block(`n_qtl')

	    local t_start = - `w'
	    local t_label ""
	    forval x = 1/`t_periods' {
	    	local t_label = `"`t_label' `x' "`t_start'""'
	    	local t_start = `t_start' + 1
	    }
	    local zero_label = `w' + 1

	    gen ci_lb = b - 1.96*se
		gen ci_ub = b + 1.96*se

		*jitter plots
		replace t = t - 0.1 if gr==2
		replace t = t - 0.05 if gr==3
		replace t = t + 0.05 if gr==4
		replace t = t + 0.1 if gr==5

		if `n_qtl'==2 {
			twoway (connected b t if gr==2, mc(ebblue%50) lc(ebblue) msize(vsmall)) (rcap ci_lb ci_ub t if gr==2, lc(ebblue) lp(dash) lw(vthin)) ///
		    	   , xlabel(`t_label') xline(`zero_label', lc(black)) xtitle("Month t relative to MW change") ///
		    	   ylabel(, grid) yline(0, lc(black)) ytitle("Change in rent relative to below median zipcodes") ///
		    	   legend(off) 
		}
	 	if `n_qtl'==4 {
		   	twoway (connected b t if gr==2, mc(ebblue%50) lc(ebblue) msize(vsmall)) (rcap ci_lb ci_ub t if gr==2, lc(ebblue) lp(dash) lw(vthin)) ///
		    	   (connected b t if gr==3, mc(red%50) lc(red) msize(vsmall)) (rcap ci_lb ci_ub t if gr==3, lc(red) lp(dash) lw(vthin)) ///
		    	   (connected b t if gr==4, mc(gs11%50) lc(gs11) msize(vsmall)) (rcap ci_lb ci_ub t if gr==4, lc(gs11) lp(dash) lw(vthin)) ///
		    	   , xlabel(`t_label') xline(`zero_label', lc(black)) xtitle("Month t relative to MW change") ///
		    	   ylabel(, grid) yline(0, lc(black)) ytitle("Change in rent relative to 1st quartile") ///
		    	   legend(order(1 "2nd" 3 "3rd" 5 "4th") rows(1))
	 	}

	 	if `n_qtl'==5 {
	    twoway (connected b t if gr==2, mc(ebblue%50) lc(ebblue) msize(vsmall)) (rcap ci_lb ci_ub t if gr==2, lc(ebblue) lp(dash) lw(vthin)) ///
	    	   (connected b t if gr==3, mc(red%50) lc(red) msize(vsmall)) (rcap ci_lb ci_ub t if gr==3, lc(red) lp(dash) lw(vthin)) ///
	    	   (connected b t if gr==4, mc(gs11%50) lc(gs11) msize(vsmall)) (rcap ci_lb ci_ub t if gr==4, lc(gs11) lp(dash) lw(vthin)) ///
	    	   (connected b t if gr==5, mc(green%50) lc(green) msize(vsmall)) (rcap ci_lb ci_ub t if gr==5, lc(green) lp(dash) lw(vthin)) ///
	    	   , xlabel(`t_label') xline(`zero_label', lc(black)) xtitle("Month t relative to MW change") ///
	    	   ylabel(, grid) yline(0, lc(black)) ytitle("Change in rent relative to 1st quintile") ///
	    	   legend(order(1 "2nd" 3 "3rd" 5 "4th" 7 "5th") rows(1))

	 	}
	    graph export `outstub'/fd_het_`het_char'_qt`n_qtl'.png, replace	    
	    restore
end 

program dynamic_het_model_bygroups
	syntax, depvar(str) absorb(str) cluster(str) het_char(str) outstub(str) [w(int 5) n_qtl(int 4)]

	levelsof `het_char', local(het_gr)
	local plot_legend ""
	local n_plot = 2
	foreach g of local het_gr {
		eststo fd_het_gr`g': reghdfe D.`depvar' L(-`w'/`w').d_ln_mw if `het_char'==`g', 			///
			absorb(`absorb') 											///
			vce(cluster `cluster') nocons

		local plot_legend `"`plot_legend' `n_plot' "qt `g'""'
		local n_plot = `n_plot' + 2
	}

	local t_periods = (2*`w' + 1)
	local t_start = - `w'
    local t_label ""
    forval x = 1/`t_periods' {
    	local t_label = `"`t_label' `x' "`t_start'""'
    	local t_start = `t_start' + 1
    }
    local zero_label = `w' + 1

    coefplot (fd_het_gr1, recast(connected) msize(small) mc(ebblue) lc(ebblue) ciopts(recast(rcap) lc(ebblue) lp(dash) lw(vthin))) ///
    		 (fd_het_gr2, recast(connected) msize(small) mc(red) lc(red) ciopts(recast(rcap) lc(red) lp(dash) lw(vthin)))  ///
			 (fd_het_gr3, recast(connected) msize(small) mc(gs11) lc(gs11) ciopts(recast(rcap) lc(gs11) lp(dash) lw(vthin)))  ///
			 (fd_het_gr4, recast(connected) msize(small) mc(green) lc(green) ciopts(recast(rcap) lc(green) lp(dash) lw(vthin)))  ///
    		 , vertical xlabel(`t_label') xline(`zero_label', lc(black)) yline(0, lc(black)) ylabel(, grid) ///
    		 xtitle("Month t relative to MW change") legend(order(`plot_legend'))
	 graph export `outstub'/fd_hetbygr_`het_char'_qt`n_qtl'.png, replace
end 

program dynamic_het_cumulpost 
	syntax, depvar(str) absorb(str) cluster(str) het_char(str) outstub(str) [w(int 5) n_qtl(int 4)]

	di "`het_char'"

	forval q = 2/4 {

		local lincom_formula "c.L0.d_ln_mw#i`q'.`het_char'"
		forval t = 1/`w' {
			local lincom_formula `"`lincom_formula' + c.L`t'.d_ln_mw#i`q'.`het_char'"'
		}
		
		qui reghdfe D.`depvar' c.L(0/`w').d_ln_mw#ib(1).`het_char' L(0/`w').d_ln_mw, 			///
			absorb(`absorb') 											///
			vce(cluster `cluster') nocons
	
		lincomest `lincom_formula'
	}	
	
end 

program dynamic_het_cumulpost_bygroups
	syntax, depvar(str) absorb(str) cluster(str) het_char(str) outstub(str) [w(int 5) n_qtl(int 4)]

	levelsof `het_char', local(het_gr)
	
	foreach g of local het_gr {
		qui reghdfe D.`depvar' L(0/`w').d_ln_mw if `het_char'==`g', 			///
			absorb(`absorb') 											///
			vce(cluster `cluster') nocons
		
		local lincomest_coeffs "d_ln_mw"
		forvalues i = 1(1)`w'{
			local lincomest_coeffs "`lincomest_coeffs' + L`i'.d_ln_mw"
		}	
		qui eststo cumulpost`g': lincomest `lincomest_coeffs'	
	}

	//esttab cumulpost1 cumulpost2 cumulpost3 cumulpost4, ///	  
	esttab cumulpost1 cumulpost2 cumulpost3 cumulpost4 using `outstub'/fd_het_cumulpost_`het_char'_qt`n_qtl'.tex, ///
	  replace nonumbers mtitles("1st" "2nd" "3rd" "4rd") coef((1) "`het_char'") ///
	  title("Cumulative Effect by Demographics' quartiles") se ///
	  star(+ 0.10 * 0.05 ** 0.01 * 0.001)
end 


program run_dynamic_model
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5)]
	
	local lincomest_coeffs "D1.ln_mw + LD.ln_mw"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.ln_mw"
	}

	eststo clear
	eststo reg1: reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)
	

	eststo lincom1: lincomest `lincomest_coeffs'
	comment_table, trend_lin("No") trend_sq("No")
			
	
	eststo reg2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 		///
		absorb(`absorb' i.zipcode) 							///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")
	
	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)
	
	eststo lincom2: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("No")
	
	eststo reg3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw,		///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 	///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")

	test (F5D.ln_mw = 0) (F4D.ln_mw = 0) (F3D.ln_mw = 0) (F2D.ln_mw = 0) (F1D.ln_mw = 0)
    estadd scalar p_value_F = r(p)
	
	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table, trend_lin("Yes") trend_sq("Yes")
end


main 