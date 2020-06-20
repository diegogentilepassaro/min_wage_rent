set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado
set scheme s1color


program main 
	local instub  = "../../../drive/derived_large/output/" 
	local outstub = "../output/"

	nMW_rent_corr, output(`outstub') instub(`instub') target_yr(2019) ///
					target_qt(3) start_yr(2012) ///
					target_vars("medrentpricepsqft_sfcc medlistingpricepsqft_sfcc")


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
		   legend(order(1 "less than 5 MW changes" 2 "more than 5 MW changes"))
	      
end 





main
