set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main 
	local instub_mw    "../../../drive/base_large/output"
	local instub_wages "../../../base/qcew/output"
	local outstub "../output"

	use `instub_mw'/zip_mw.dta, clear

	clean_zip_mw

	merge m:1 countyfips year_month using `instub_wages'/tot_emp_wage_countymonth.dta, ///
	nogen assert(1 2 3) keep(1 3)


	prepare_mw_wage_panel

	save_data `outstub'/mw_wage_panel.dta, key(zipcode year_month) replace 

	

end 


program clean_zip_mw 
	destring countyfips, replace 
	destring statefips, replace
	drop county_above local_above
	g temp = mofd(year_month)
	order temp, after(year_month)
	drop year_month
	rename temp year_month
	format year_month %tm
end 


program prepare_mw_wage_panel

	xtset zipcode year_month

	rename avgwwage_tot avgwwage_qt 
	g avgmwage_qt = avgwwage_qt * 4.35

	g ln_mw    = log(actual_mw)
	g ln_wwage = log(avgwwage_qt)
	g ln_mwage = log(avgmwage_qt)
	g ln_emp   = log(emp_tot)
	g ln_est   = log(estcount_tot)

	foreach var in ln_mw ln_wwage ln_mwage ln_emp ln_est {
		bys zipcode (year_month): g d_`var' = D.`var'
	}

	keep zipcode year_month                       ///
	ln_mw d_ln_mw actual_mw dactual_mw treated_mw ///
		 ln_wwage d_ln_wwage avgwwage_qt          ///
		 ln_mwage d_ln_mwage avgmwage_qt          ///
		 ln_emp d_ln_emp emp_tot                  ///
		 ln_est d_ln_est  estcount_tot
end 




main 