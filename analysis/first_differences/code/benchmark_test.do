clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 


program main 
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	horse_race_models, depvar(ln_med_rent_psqft) w(5) absorb(year_month zipcode) cluster(statefips)


end 


program horse_race_models
    syntax, depvar(str) w(int) absorb(str) cluster(str) 
	
    local lincom_coeffs "L0.D.ln_mw"
    forval x = 1 / `w' {
    	local lincom_coeffs `"`lincom_coeffs' + L`x'.D.ln_mw"'
    }

	local beta_low = 0.1
	local gamma_low = 0.7
	local gamma_hi = 0.5
	local k = 0.1

    *Model 1 - lags and leads
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons

	sum medrentprice_sfcc if e(sample)
	local rent_month = r(mean)
	local week_hours = 40
	local mw_workers = 2
	sum actual_mw if e(sample)
	local mw_month = r(mean) * `week_hours' * 4.35 * `mw_workers'
	local alpha = `mw_month' / `rent_month'
	
	sum sh_mww_all2 if e(sample)
	local mww_share = r(mean)

	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`mww_share') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(test)
	local mod1 = r(benchmark_test)
	eststo model1: lincomest `lincom_coeffs'

	*model 2: lags only 
	reghdfe D.`depvar' L(0/`w').D.ln_mw, 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons

	sum medrentprice_sfcc if e(sample)
	local rent_month = r(mean)
	local week_hours = 40
	local mw_workers = 2
	sum actual_mw if e(sample)
	local mw_month = r(mean) * `week_hours' * 4.35 * `mw_workers'
	local alpha = `mw_month' / `rent_month'

	sum sh_mww_all2 if e(sample)
	local mww_share = r(mean)

	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`mww_share') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(test)
	local mod2 = r(benchmark_test)
	eststo model2: lincomest `lincom_coeffs'



	*model 3: leads and lags AB (lagged depvar)
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw L.D.`depvar', 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons

	sum medrentprice_sfcc if e(sample)
	local rent_month = r(mean)
	local week_hours = 40
	local mw_workers = 2
	sum actual_mw if e(sample)
	local mw_month = r(mean) * `week_hours' * 4.35 * `mw_workers'
	local alpha = `mw_month' / `rent_month'
	
	sum sh_mww_all2 if e(sample)
	local mww_share = r(mean)

	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`mww_share') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(test)
	local mod3 = r(benchmark_test)
	eststo model3: lincomest `lincom_coeffs'

	*model 4: lags only AB (lagged depvar)
	reghdfe D.`depvar' L(0/`w').D.ln_mw L.D.`depvar', 			///
		absorb(`absorb') 											///
		vce(cluster `cluster') nocons

	sum medrentprice_sfcc if e(sample)
	local rent_month = r(mean)
	local week_hours = 40
	local mw_workers = 2
	sum actual_mw if e(sample)
	local mw_month = r(mean) * `week_hours' * 4.35 * `mw_workers'
	local alpha = `mw_month' / `rent_month'
	
	sum sh_mww_all2 if e(sample)
	local mww_share = r(mean)

	compute_benchmark, beta_low(`beta_low') alpha(`alpha') s_low(`mww_share') gamma_low(`gamma_low') gamma_hi(`gamma_hi') k(`k') name(test)
	local mod4 = r(benchmark_test)
	eststo model4: lincomest `lincom_coeffs'

	coefplot (model1, color(mint) lcolor(mint)) (model2, color(orange) lcolor(orange)) ///
	(model3, color(ebblue) lcolor(ebblue)) (model4, color(lavender) lcolor(lavender)), xline(0, lp(dot) lc(gs11)) ///
	xline(`mod1') xline(`mod2', lcolor(black)) xline(`mod3', lcolor(ebblue)) xline(`mod4', lcolor(red%70)) ///
	xlabel(-.3(0.1).5) legend(order(2 "Leads and lags" 4 "Lags only" 6 "AB leads and lags" 8 "AB lags only")) ///
	ciopts(lp(dash) lw(vthin))
end

program compute_benchmark, rclass
	syntax, beta_low(str) alpha(str) s_low(str) gamma_low(str) gamma_hi(str) k(str) name(str)

	local s_hi = 1 - `s_low'	

	local benchmark = (`beta_low' * `alpha' * `s_low') / ((`gamma_low' * `s_low') + (`gamma_hi' * `s_hi') + `k')

	return scalar benchmark_`name' = `benchmark'
end 

main 