clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main 
	local instub_zillow "../../../drive/derived_large/output"
	local instub_safmr "../../../base/alt_rents/output"
	local logfile "../output/data_file_manifest.log"


	local target_series "2br mfr5plus sfcc"
	
	local target vars "" 
	foreach s in `target_series' {
		local target_vars `"`target_vars' medrentprice_`s'"'
	}
	
	use zipcode place_code msa countyfips statefips ///
		year_month `target_vars'           ///
		using `instub_zillow'/zipcode_yearmonth_panel_all.dta

		foreach s in `target_series' {
			g rmtag = (medrentprice_`s'==.)
			bys zipcode (year_month): g ziplen = _N
			bys zipcode (year_month): gegen rmcount = sum(rmtag)
			g sample_`s' = (ziplen!=rmcount)
			drop ziplen rmtag rmcount
		}

	unab samplist: sample_*
	gegen allmis = rowtotal(`samplist')
	drop if allmis==0 
	drop allmis 

	* Option 1: take year average 
	preserve
	g year = yofd(dofm(year_month))
	collapse (mean) `target_vars', by(zipcode year)
	merge 1:1 zipcode year using `instub_safmr'/safrm.dta	

	unab safmrvars: safmr*
	local target_final `"`target_vars' `safmrvars'"'
	collapse (mean) `target_final', by(year)
	//use `instub_safmr'/safrm.dta, clear

	keep if inrange(year, 2010, 2019)

	twoway (line medrentprice_2br year, lc(mint)) (line medrentprice_mfr5plus year, lc(khaki)) (line medrentprice_sfcc year, lc(red)) ///
		   (line safmr2br year, lp(dash) lc(eltblue)) (line safmr3br year, lp(dash) lc(lavender)) (line safmr4br year, lp(dash) lc(black)), ///
	legend(order(1 "zillow 2br" 2 "zillow multi-family" 3 "zillow single family/condo" 4 "safmr 2br" 5 "safmr 3br" 6 "safmr 4br") cols(3)) ///
	ylabel(, grid)
	graph export ../output/trend_zillow_safmr_zipcode_avg.png, replace
	restore

	* Option 2: take given month 
	preserve
	local m = 12
	g year = yofd(dofm(year_month))
	g month = month(dofm(year_month))

	keep if month == `m'
	merge 1:1 zipcode year using `instub_safmr'/safrm.dta	

	unab safmrvars: safmr*
	local target_final `"`target_vars' `safmrvars'"'
	collapse (mean) `target_final', by(year)
	//use `instub_safmr'/safrm.dta, clear

	keep if inrange(year, 2010, 2019)

	twoway (line medrentprice_2br year, lc(mint)) (line medrentprice_mfr5plus year, lc(khaki)) (line medrentprice_sfcc year, lc(red)) ///
		   (line safmr2br year, lp(dash) lc(eltblue)) (line safmr3br year, lp(dash) lc(lavender)) (line safmr4br year, lp(dash) lc(black)), ///
	legend(order(1 "zillow 2br" 2 "zillow multi-family" 3 "zillow single family/condo" 4 "safmr 2br" 5 "safmr 3br" 6 "safmr 4br") cols(3)) ///
	ylabel(, grid)
	graph export ../output/trend_zillow_safmr_zipcode_m`m'.png, replace
	restore
end 




main 