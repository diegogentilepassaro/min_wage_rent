set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main 
	local instub_mw    "../../../drive/base_large/output"
	local instub_wages "../../../base/qcew/output"
	local instub_xwalk "../../../raw/crosswalk"
	local outstub "../output"

	prepare_aux_data, instub_xwalk(`instub_xwalk') instub_mw(`instub_mw')

	use `instub_mw'/zip_mw.dta, clear
	clean_zip_mw
	merge 1:1 zipcode year_month using ../temp/exp_mw.dta, nogen assert(1 2 3)

	merge m:1 zipcode countyfips using ../temp/zip_cty_wgt.dta, nogen assert(1 2 3) keep(3)
	gsort countyfips year_month
	*collapse geography 
	gcollapse (mean) actual_mw dactual_mw treated_mw ln_mw exp_mw ln_expmw [aw = zhu], by(county year_month) 
	
	merge m:1 countyfips year_month using `instub_wages'/tot_emp_wage_countymonth.dta, ///
	nogen assert(1 2 3) keep(3)

	prepare_mw_wage_panel
	g quarter = qofd(dofm(year_month)), 
	order quarter, after(year_month)
	format quarter %tq

	gcollapse (first) estcount_tot avgwwage_qt avgmwage_qt ln_wwage ln_mwage ln_est ///
	          (last) actual_mw dactual_mw treated_mw ln_mw exp_mw ln_expmw emp_tot ln_emp, by(countyfips quarter) 

  	xtset countyfips quarter

	foreach var in ln_mw ln_emp ln_expmw {
		bys countyfips (quarter): g d_`var' = (1/3)*D.`var'
	}
	foreach var in ln_wwage ln_mwage ln_est {
		bys countyfips (quarter): g avg_d_`var' = (1/3)*D.`var'
	}

	g statefips = string(countyfips, "%05.0f")
	replace statefips = substr(statefips, 1, 2)
	destring statefips, replace
	order statefips, after(countyfips)

	*when checking 7790 notmatched from master zippanel, 95 percents are PO boxes and the remaning 5 looks like universities, very small rural areas. This means we probably can use zcta/zip interchangeably
	*used this to check zipcode type 
	*merge m:1 zipcode using ../temp/zip_zcta_xwalk.dta, nogen assert(1 2 3)


	save_data `outstub'/mw_wage_panel.dta, key(countyfips quarter) replace 

	

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

	xtset zipcode year_month
	g ln_mw    = log(actual_mw)
	

	keep zipcode countyfips year_month ///
		 ln_mw actual_mw dactual_mw treated_mw
end 


program prepare_mw_wage_panel

	rename avgwwage_tot avgwwage_qt 
	g avgmwage_qt = avgwwage_qt * 4.35

	g ln_wwage = log(avgwwage_qt)
	g ln_mwage = log(avgmwage_qt)
	g ln_emp   = log(emp_tot)
	g ln_est   = log(estcount_tot)


	keep year_month countyfips            ///
		 ln_mw actual_mw dactual_mw treated_mw ///
		 exp_mw ln_expmw             ///
		 ln_wwage avgwwage_qt          ///
		 ln_mwage avgmwage_qt          ///
		 ln_emp emp_tot                  ///
		 ln_est estcount_tot
end 

program prepare_aux_data	
	syntax, instub_xwalk(str) instub_mw(str)
	import delim `instub_xwalk'/zcta_county_rel_10.txt, delim(",") clear
	rename (zcta5 geoid) (zipcode countyfips)
	keep if zhupct >=50
	duplicates tag zipcode, g(dup)
	bys zipcode: egen morepop = max(zpoppct) if dup==1
	drop if dup==1 & zpoppct!=morepop
	drop morepop dup
	*keep housing units as weights
	keep zipcode countyfips hupt zhu 
	save ../temp/zip_cty_wgt.dta, replace 

	import excel `instub_xwalk'/zip_to_zcta_2019.xlsx, first clear
	rename (ZIP_CODE ZCTA) (zipcode zcta)
	drop if zcta=="No ZCTA"
	destring zipcode zcta, replace 
	keep zipcode zcta zip_join_type ZIP_TYPE
	save ../temp/zip_zcta_xwalk.dta, replace

	use `instub_mw'/exp_mw.dta, clear 
	g year_month = mofd(yearmonth)
	format year_month %tm
	drop yearmonth exp_mw_job_lowinc exp_mw_job_young
	rename exp_mw_totjob exp_mw
	g ln_expmw = log(exp_mw)
	save ../temp/exp_mw.dta, replace
end




main 