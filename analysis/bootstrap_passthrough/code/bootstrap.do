clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    use "../temp/baseline_rent_panel_24.dta", clear

    xtset, clear
	eststo clear
    eststo: bootstrap passthrough = r(passthrough) ///
	    avg_effect = r(avg_effect) ///
		incr_sf_monthly_income = r(incr_sf_monthly_income), rep(100) seed(8) ///
	    cluster(zipcode): thing_to_bootstrap
	esttab * using "../output/bootstrap.tex", mtitle("Bootstrap") ci replace
end

program thing_to_bootstrap, rclass

    reghdfe medrentpricepsqft_sfcc ib24.last_sal_mw_event_rel_months24, nocons ///
		absorb(zipcode calendar_month year_month)
	local sum_coeffs = 0
	forval i = 25(1)49 {
        local sum_coeffs = `sum_coeffs' + _b[`i'.last_sal_mw_event_rel_months24]
		local avg_effect = `sum_coeffs'/25
	}
	
	reghdfe dactual_mw ib24.last_sal_mw_event_rel_months24, nocons ///
		absorb(zipcode calendar_month year_month)
	local used_mw_change = _b[25.last_sal_mw_event_rel_months24]
	local incr_sf_monthly_income = (2*40*4.35)*`used_mw_change'
	
	local avg_sf_home_size = 1500
	
	return scalar avg_effect = `avg_effect'
	return scalar incr_sf_monthly_income = `incr_sf_monthly_income'
    return scalar passthrough = (`avg_sf_home_size'*`avg_effect')/`incr_sf_monthly_income'
end

main
