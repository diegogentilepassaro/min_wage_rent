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
	run_static_placebo, depvar(ln_med_rent_psqft_sfcc) placebovar(ln_n_listings_sfcc) controls(ln_med_list_psqft_sfcc) ///
						absorb(year_month i.zipcode) cluster(statefips)		
						
	esttab * using "`outstub'/fd_table_placebo.tex", keep(D.ln_mw) compress se replace substitute(\_ _) 	///
			coeflabels(`estlabels_static') ///
			stats(r2 N, fmt(%9.3f %9.0gc) ///
			labels("R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) ///
			mgroups("$\Delta$ ln(Median rent)" "$\Delta$ ln(No. listings)", pattern(1 0 1 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
			nonote nomtitles 

	plot_dynamic_placebo, depvar(ln_med_rent_psqft_sfcc) placebovar(ln_n_listings_sfcc) controls(ln_med_list_psqft_sfcc) ///
						absorb(year_month i.zipcode) cluster(statefips)



end


program run_static_placebo
	syntax, depvar(str) placebovar(str) absorb(str) cluster(str) [controls(str)]

	eststo clear
	eststo: reghdfe D.`depvar' D.ln_mw, ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	eststo: reghdfe D.`placebovar' D.ln_mw,	///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

end

program plot_dynamic_placebo 
	syntax, depvar(str) placebovar(str) absorb(str) cluster(str) [controls(str) w(int 5)]

	eststo clear
	
	eststo: reghdfe D.`placebovar' L(-`w'/`w').D.ln_mw, ///
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

		sort at 

		local period0 = `w' + 1

		twoway (connected b_placebo1 at, mc(edkblue) lc(edkblue) lw(thin)) (rcap b_placebo1_lb b_placebo1_ub at, lc(edkblue) lp(dash) lw(vthin)), /// 
			graphregion(color(white)) bgcolor(white) ///
			xlabel(1 "-5" 2 "-4" 3 "-3" 4 "-2" ///
			5 "-1" 6 "0" 7 "1" 8 "2" 9 "3" ///
			10 "4" 11 "5", labsize(vsmall)) xtitle("Leads and lags of ln MW") ///
			ytitle("Effect on ln No. listings") ylabel(-0.3(0.1).5, grid labsize(small) angle(90))	///
			yline(0, lcol(black)) ///
			legend(off)
		graph export "../output/fd_placebo.png", replace
	restore

end 

program comment_table
	syntax, trend_lin(str) trend_sq(str)

	estadd local zs_trend 		"`trend_lin'"	
	estadd local zs_trend_sq 	"`trend_sq'"
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
