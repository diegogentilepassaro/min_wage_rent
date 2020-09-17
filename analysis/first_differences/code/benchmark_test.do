clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 


program main 
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	local beta_low = 0.1
	local gamma_low = 0.7
	local gamma_hi = 0.5
	local k = 0.1

	foreach win in 2 5 {
	benchmark_plot_all2, depvar(ln_med_rent_psqft) w(`win') absorb(year_month zipcode) cluster(statefips) outstub(`outstub') ///
						 beta_low(`beta_low') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k')
	graph export `outstub'/benchmark_all2_w`win'_ziptrend.png, replace
	benchmark_plot_all2, depvar(ln_med_rent_psqft) w(`win') absorb(year_month zipcode i.zipcode#c.trend_sq) cluster(statefips) outstub(`outstub') ///
						 beta_low(`beta_low') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k')
	graph export `outstub'/benchmark_all2_w`win'_ziptrendsq.png, replace

	benchmark_plot_wmean, depvar(ln_med_rent_psqft) w(`win') absorb(year_month zipcode) cluster(statefips) outstub(`outstub') ///
						 beta_low(`beta_low') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k')
	graph export `outstub'/benchmark_wmean2_w`win'_ziptrend.png, replace
	benchmark_plot_wmean, depvar(ln_med_rent_psqft) w(`win') absorb(year_month zipcode i.zipcode#c.trend_sq) cluster(statefips) outstub(`outstub') ///
						 beta_low(`beta_low') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k')
	graph export `outstub'/benchmark_wmean2_w`win'_ziptrendsq.png, replace

	}


	

end 


program benchmark_plot_all2
    syntax, depvar(str) w(int) absorb(str) cluster(str) outstub(str) beta_low(str) gamma_low(str) gamma_hi(str) k(str)
	
    local lincom_coeffs "L0.D.ln_mw"
    forval x = 1 / `w' {
    	local lincom_coeffs `"`lincom_coeffs' + L`x'.D.ln_mw"'
    }


    *Model 1 - lags and leads
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model1: lincomest `lincom_coeffs'

	*model 2: lags only 
	reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model2: lincomest `lincom_coeffs'

	*model 3: leads and lags AB (lagged depvar)
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw L.D.`depvar', 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model3: lincomest `lincom_coeffs'

	*model 4: lags only AB (lagged depvar)
	reghdfe D.`depvar' L(0/`w').D.ln_mw L.D.`depvar', 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model4: lincomest `lincom_coeffs'

	*benchmarks
	sum medrentprice_sfcc if e(sample)
	local rent_month = r(mean)
	local week_hours = 40
	local mw_workers = 2
	sum actual_mw if e(sample)
	local mw_month = r(mean) * `week_hours' * 4.35 * `mw_workers'
	local alpha = `mw_month' / `rent_month'
	
	sum sh_mww_all2 if e(sample)
	local share_mww_tot = r(mean)
	sum mww_shrenter_all2 if e(sample)
	local mww_share_rent = r(mean)
	sum sh_mww_renter_all2 if e(sample)
	local share_mww_rent_tot = r(mean)

	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`share_mww_tot') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(total)
	local mod_tot  = r(benchmark_total)
	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`share_mww_rent_tot') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(total_rent)
	local mod_totrent = r(benchmark_total_rent)
	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`mww_share_rent') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(rent)
	local mod_rent = r(benchmark_rent)

	coefplot (model1, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Leads and lags")) ///
			 (model2, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Lags only")) ///
	         (model3, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "AB leads and lags")) ///
	         (model4, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "AB lags only")), ///
 	yline(0, lc(gs11)) ylabel(-.05(0.05).2) legend(off) asequation vertical recast(bar) ///
 	citop barwidth(0.3) fcolor(*.5) nooffsets ///
	yline(`mod_tot', lcolor(cranberry) lp(shortdash)) yline(`mod_totrent', lcolor(orange) lp(shortdash)) ///
	yline(`mod_rent', lcolor(mint) lp(shortdash))
end

program benchmark_plot_wmean
    syntax, depvar(str) w(int) absorb(str) cluster(str) outstub(str) beta_low(str) gamma_low(str) gamma_hi(str) k(str)
	
    local lincom_coeffs "L0.D.ln_mw"
    forval x = 1 / `w' {
    	local lincom_coeffs `"`lincom_coeffs' + L`x'.D.ln_mw"'
    }


    *Model 1 - lags and leads
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model1: lincomest `lincom_coeffs'

	*model 2: lags only 
	reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model2: lincomest `lincom_coeffs'

	*model 3: leads and lags AB (lagged depvar)
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw L.D.`depvar', 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model3: lincomest `lincom_coeffs'

	*model 4: lags only AB (lagged depvar)
	reghdfe D.`depvar' L(0/`w').D.ln_mw L.D.`depvar', 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons
	eststo model4: lincomest `lincom_coeffs'

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
	
	sum sh_mww_wmean2 if e(sample)
	local share_mww_tot = r(mean)
	sum mww_shrenter_wmean2 if e(sample)
	local mww_share_rent = r(mean)
	sum sh_mww_renter_wmean2 if e(sample)
	local share_mww_rent_tot = r(mean)

	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`share_mww_tot') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(total)
	local mod_tot  = r(benchmark_total)
	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`share_mww_rent_tot') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(total_rent)
	local mod_totrent = r(benchmark_total_rent)
	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`mww_share_rent') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(rent)
	local mod_rent = r(benchmark_rent)

	coefplot (model1, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Leads and lags")) ///
			 (model2, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "Lags only")) ///
	         (model3, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "AB leads and lags")) ///
	         (model4, color(ebblue) ciopts(lcolor(ebblue) lp(dash) lw(vthin)) rename((1) = "AB lags only")), ///
 	yline(0, lc(gs11)) ylabel(-.05(0.05).2) legend(off) asequation vertical recast(bar) ///
 	citop barwidth(0.3) fcolor(*.5) nooffsets ///
	yline(`mod_tot', lcolor(cranberry) lp(shortdash)) yline(`mod_totrent', lcolor(orange) lp(shortdash)) ///
	yline(`mod_rent', lcolor(mint) lp(shortdash))
end

program compute_benchmark, rclass
	syntax, beta_low(str) alpha(str) s_low(str) gamma_low(str) gamma_hi(str) k(str) name(str)

	local s_hi = 1 - `s_low'	

	local benchmark = (`beta_low' * `s_low') / (-(`gamma_low' * `s_low') - (`gamma_hi' * `s_hi') + `k')

	return scalar benchmark_`name' = `benchmark'
end 

main 