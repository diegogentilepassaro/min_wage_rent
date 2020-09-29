clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main 
	local instub_zillow "../../../drive/derived_large/output"
	local instub_safmr "../../../base/alt_rents/output"
	local logfile "../output/data_file_manifest.log"

	import delim ../../../drive/raw_data/census/cpi2012_usa.csv, clear  
	replace cpi2012 = cpi2012 /100
	save ../temp/cpi2012.dta, replace

	compare_zillow_safmr_zipcode, tseries(2br mfr5plus sfcc) inzillow(`instub_zillow') insafmr(`instub_safmr') mlist(1 6 12)


end 

program correlation_zillow_safmr
	syntax, tseries(str) inzillow(str) insafmr(str) mlist(str)
	binscatter medrentprice_sfcc safmr2br, absorb(year)

	STOP 

end

program compare_zillow_safmr_zipcode
	syntax, tseries(str) inzillow(str) insafmr(str) mlist(str)
	
	local target vars "" 
	foreach s in `tseries' {
		local target_vars `"`target_vars' medrentprice_`s'"'
	}
	
	use zipcode place_code msa countyfips statefips ///
		year_month `target_vars'           ///
		using `inzillow'/zipcode_yearmonth_panel_all.dta

		foreach s in `tseries' {
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
	g year = yofd(dofm(year_month))
	keep if inrange(year, 2010, 2019)

	* Option 1: take year average 
	preserve
	collapse (mean) `target_vars', by(zipcode year)
	merge 1:1 zipcode year using `insafmr'/safrm.dta	


	unab safmrvars: safmr*
	local target_final `"`target_vars' `safmrvars'"'
	collapse (mean) `target_final', by(year)


	merge 1:1 year using ../temp/cpi2012.dta, nogen keep(1 3)
	foreach v in `target_final' {
		replace `v' = `v'*cpi2012
	}

	twoway (line medrentprice_2br year, lc(mint)) (line medrentprice_mfr5plus year, lc(khaki)) (line medrentprice_sfcc year, lc(red)) ///
		   (line safmr2br year, lp(dash) lc(eltblue)) (line safmr3br year, lp(dash) lc(lavender)) (line safmr4br year, lp(dash) lc(black)), ///
	legend(order(1 "zillow 2br" 2 "zillow multi-family" 3 "zillow single family/condo" 4 "safmr 2br" 5 "safmr 3br" 6 "safmr 4br") cols(3)) ///
	ylabel(, grid) ytitle("Rent (2012 USD)", size(medsmall)) xtitle(, size(medsmall))
	graph export ../output/trend_zillow_safmr_zipcode_avg.png, replace
	restore

	* Option 2: take given month 
	foreach m in `mlist' {
		preserve
		g month = month(dofm(year_month))

		keep if month == `m'
		merge 1:1 zipcode year using `insafmr'/safrm.dta	


		unab safmrvars: safmr*
		local target_final `"`target_vars' `safmrvars'"'
		collapse (mean) `target_final', by(year)
		//use `instub_safmr'/safrm.dta, clear


		merge 1:1 year using ../temp/cpi2012.dta, nogen keep(1 3)
		foreach v in `target_final' {
			replace `v' = `v'*cpi2012
		}

		twoway (line medrentprice_2br year, lc(mint)) (line medrentprice_mfr5plus year, lc(khaki)) (line medrentprice_sfcc year, lc(red)) ///
			   (line safmr2br year, lp(dash) lc(eltblue)) (line safmr3br year, lp(dash) lc(lavender)) (line safmr4br year, lp(dash) lc(black)), ///
		legend(order(1 "zillow 2br" 2 "zillow multi-family" 3 "zillow single family/condo" 4 "safmr 2br" 5 "safmr 3br" 6 "safmr 4br") cols(3)) ///
		ylabel(, grid) ytitle("Rent (2012 USD)", size(medsmall)) xtitle(, size(medsmall))
		graph export ../output/trend_zillow_safmr_zipcode_m`m'.png, replace
		restore	
	}

	*binscatter correlation 
	
	collapse (mean) `target_vars', by(zipcode year)
	merge 1:1 zipcode year using `insafmr'/safrm.dta	

	reshape long safmr@br, i(zipcode year `target_vars') j(safmr_type)

	binscatter medrentprice_sfcc safmrbr if safmr_type>0, ///
	by(safmr_type) absorb(year) ylabel(0(1000)6000, grid labsize(small)) xlabel(0(1000)4000, labsize(small)) ///
	ytitle("Median Rent Price (2012 USD)", size(medsmall)) xtitle("Small Area Fair Market Rent", size(medsmall)) ///
	legend(order(1 "1br" 2 "2br" 3 "3br" 4 "4br") rows(1))
	graph export ../output/bins_sfcc_safmr_bytype.png, replace

end


main 