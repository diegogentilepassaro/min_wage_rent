set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado
set scheme s1color


program main 
	local instub  = "../../../drive/derived_large/output/" 
	local outstub = "../output/"


	focus_trend, instub(`insutb') ///
		ziplist1("10029 10035") ziplist2("10021 10028 10044 10065 10075 10128")
	


	// nMW_rent_corr_zipcode, output(`outstub') instub(`instub') target_yr(2019) ///
	// 			    start_yr(2010) ///
	// 				target_vars(" medrentpricepsqft_sfcc medrentpricepsqft_2br medrentpricepsqft_mfr5plus") ///
	// 				demo_vars("pop2010 urb_share2010 med_hhinc20105 black_share2010 housing_units2010")

	// nMW_list_corr_zipcode, output(`outstub') instub(`instub') target_yr(2019) ///
	// 			    start_yr(2010) ///
	// 				target_vars("medlistingpricepsqft_sfcc medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier") ///
	// 				demo_vars("pop2010 urb_share2010 med_hhinc20105 black_share2010 housing_units2010")					

	// rent_demo_corr, instub(`instub') output(`outstub') ///
	// target_vars("medrentpricepsqft_sfcc") ///
	// demo_vars("urb_share2010 med_hhinc20105 black_share2010 college_share20105 poor_share20105 unemp_share20105 employee_share20105") ///
	// start_yr(2013)


end 


program focus_trend 
	syntax, instub(str) ziplist1(str) ziplist2(str)

	use `instub'baseline_rent_panel.dta, clear 

	g target_groups = 0 
	foreach zip of varlist ziplist1 {
		replace target_groups = 1 if zipcode==`zip'
	}
	foreach zip of varlist ziplist2 {
		replace target_groups = 2 if zipcode==`zip'
	}

end


program rent_demo_corr
	syntax, output(str) instub(str) target_vars(str) demo_vars(str) start_yr(int)

	use `instub'baseline_rent_panel.dta, clear 
	
	xtset zipcode year_month

	g year = year(dofm(year_month))

	keep if year >= `start_yr'

	local target_vars_start = ""
	foreach var of local target_vars {
		local newvar "`var'0 = `var'"
		local target_vars_start = `" `target_vars_start' `newvar' "'
	}

	local target_vars_end = ""
	foreach var of local target_vars {
		local newvar "`var'1 = `var'"
		local target_vars_end = `" `target_vars_end' `newvar' "'
	}

	
	collapse (first) `target_vars_start' `demo_vars' statefips (last) `target_vars_end', by(zipcode)

	foreach var of local target_vars {

		g D`var' = `var'1 - `var'0 / `var'0

		// reghdfe D`var', absorb(statefips) res(R`var') nocons

		drop if missing(D`var')

		local QTdemos = ""
		foreach demo of local demo_vars {
			xtile QT`demo' = `demo', n(4)
			local QTdemos = "`QTdemos' QT`demo'"
			graph bar D`var', over(QT`demo', label(labsize(small))) ///
			b1title("Quantiles of `demo'", size(small))   
			graph export `output'D`var'_`demo'.png, replace
		}

		drop `QTdemos'

	}
	



		

end


program nMW_rent_corr_zipcode 
	syntax, output(str) instub(str) target_yr(int) start_yr(int) target_vars(str) demo_vars(str)

	use `instub'baseline_rent_panel.dta, clear 

	xtset zipcode year_month

	g year = year(dofm(year_month))
	
	local yeardiff = `target_yr' - `start_yr'


	collapse (mean)`target_vars' `demo_vars' (sum) sal_mw_event dactual_mw (first) actual_mw if inrange(year,`start_yr', `target_yr'), by(zipcode year)
	bys zipcode (year): egen tot_events = sum(sal_mw_event)

	g mw_pctch = dactual_mw / actual_mw

	xtset zipcode year
	bys zipcode (year): g Lmw_pctch = L.mw_pctch	
	winsor2 Lmw_pctch, replace cuts(0 99)

	foreach var in `target_vars' {
		binscatter `var' mw_pctch , absorb(year) control(`demo_vars') ///
		xtitle("Percentage change MW in previous year", size(small)) ytitle(, size(small)) line(qfit) lc(gs12) ///
		ylabel(, labsize(small)) xlabel(, labsize(small)) savegraph(`output'binsc_`var'_pctMWch.png) replace
	}


end 

program nMW_list_corr_zipcode 
	syntax, output(str) instub(str) target_yr(int) start_yr(int) target_vars(str) demo_vars(str) 

	use `instub'baseline_listing_panel.dta, clear 
	
	xtset zipcode year_month

	g year = year(dofm(year_month))
	
	local yeardiff = `target_yr' - `start_yr'


	collapse (mean)`target_vars' `demo_vars' (sum) sal_mw_event dactual_mw (first) actual_mw if inrange(year,`start_yr', `target_yr'), by(zipcode year)
	bys zipcode (year): egen tot_events = sum(sal_mw_event)

	g mw_pctch = dactual_mw / actual_mw

	xtset zipcode year
	bys zipcode (year): g Lmw_pctch = L.mw_pctch	
	winsor2 Lmw_pctch, replace cuts(0 99)

	foreach var in `target_vars' {
		binscatter `var' mw_pctch , absorb(year) control(`demo_vars') ///
		xtitle("Percentage change MW in previous year", size(small)) ytitle(, size(small)) line(qfit) lc(gs12) ///
		ylabel(, labsize(small)) xlabel(, labsize(small)) savegraph(`output'binsc_`var'_pctMWch.png) replace
	}


end 


program nMW_rent_corr 
	syntax, output(str) instub(str) target_yr(int) target_qt(int) start_yr(int) target_vars(str)

	use `instub'county_quarter_panel_all.dta, clear 
	egen county_id = group(countyfips)
	xtset county_id year_quarter

	g year = year(dofq(year_quarter))
	


	preserve
	bys county_id (year_quarter): egen tot_sal_mw_events = sum(sal_mw_event)
	collapse (first) tot_sal_mw_events, by(county_id)
	sum tot_sal_mw_events, det 
	xtile ev_qtl = tot_sal_mw_events, n(2)
	keep county_id ev_qtl
	tempfile n_event_qt
	save "`n_event_qt'", replace 
	restore 

	merge m:1 county_id using `n_event_qt', assert(1 2 3) keep(1 3) nogen 

	collapse (mean) `target_vars' (first) ev_qtl, by(county_id year)

	winsor2 `target_vars', cuts(1 95) by(year)

	keep if year>=`start_yr'
	

	collapse `target_vars', by(year ev_qtl)

	drop if missing(medrentpricepsqft_sfcc)


	foreach var in `target_vars' {
		bys ev_qtl (year): gen start_`var' = `var'[1]
		replace `var' = `var' / start_`var'
	}

	twoway (connected medrentpricepsqft_sfcc year if ev_qtl==1) ///
		   (connected medrentpricepsqft_sfcc year if ev_qtl==2), ///
		   legend(order(1 "less than 5 MW changes" 2 "more than 5 MW changes")) ///
		   ytitle("Relative change in Rent per square foot", size(small))
   graph export `output'rentchange_nMW.png, replace
	      
end 





main
