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
	
	merge m:1 countyfips year_month using `instub_wages'/ind_emp_wage_countymonth.dta, ///
	nogen assert(1 2 3) keep(3)
	merge m:1 countyfips year_month using `instub_wages'/tot_emp_wage_countymonth.dta, ///
	nogen assert(1 2 3) keep(3)	
	
	prepare_panel, sectors(bizserv fin info const eduhe leis manu natres transp tot)
	


	*when checking 7790 notmatched from master zippanel, 95 percents are PO boxes and the remaning 5 looks like universities, very small rural areas. This means we probably can use zcta/zip interchangeably
	*used this to check zipcode type 
	*merge m:1 zipcode using ../temp/zip_zcta_xwalk.dta, nogen assert(1 2 3)


	save_data `outstub'/qcew_controls_countyquarter_panel.dta, key(countyfips quarter) replace 

	

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


program prepare_panel
	syntax, sectors(str)

	local contlist ""
	foreach s in `sectors' {
		unab this_s : *_`s'
	
		g avgmwage_`s' = avgwwage_`s' * 4.35
		g ln_wwage_`s' = log(avgwwage_`s')
		g ln_mwage_`s' = log(avgmwage_`s')
		g ln_emp_`s'   = log(emp_`s')
		g ln_est_`s'   = log(estcount_`s')

		local contlist `"`contlist' avgwwage_`s' avgmwage_`s' ln_wwage_`s' ln_mwage_`s' emp_`s' ln_emp_`s' estcount_`s' ln_est_`s'"'
	}


	keep year_month countyfips            ///
		 ln_mw actual_mw dactual_mw treated_mw ///
		 exp_mw ln_expmw             ///
		`contlist'

	g quarter = qofd(dofm(year_month)), 
	order quarter, after(year_month)
	format quarter %tq
	
	unab quartervar : estcount_* avgwwage_* avgmwage_* ln_wwage_* ln_mwage_* ln_est_*
	unab monthvar : emp_* ln_emp_*	

	preserve 
	xtset countyfips year_month
	foreach var in ln_mw ln_expmw `monthvar' {
		bys countyfips (year_month): g d_`var' = D.`var'
	}
	g statefips = string(countyfips, "%05.0f")
	replace statefips = substr(statefips, 1, 2)
	destring statefips, replace
	order statefips, after(countyfips)	
	
	save ../output/qcew_controls_countymonth.dta, replace 
	restore

	gcollapse (first) `quartervar' ///
	          (last) actual_mw dactual_mw treated_mw ln_mw exp_mw ln_expmw `monthvar', by(countyfips quarter) 

  	xtset countyfips quarter

	foreach var in ln_mw ln_expmw `monthvar' {
		bys countyfips (quarter): g d_`var' = (1/3)*D.`var'
	}
	foreach var in `quartervar' {
		bys countyfips (quarter): g avg_d_`var' = (1/3)*D.`var'
	}

	g statefips = string(countyfips, "%05.0f")
	replace statefips = substr(statefips, 1, 2)
	destring statefips, replace
	order statefips, after(countyfips)	
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