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

	import delim ../../../drive/raw_data/ahs/AHS_sfcc_est_by_br.csv, clear
	prepare_ahs_weights
	save ../temp/ahs_wgt.dta, replace 

	use `instub_safmr'/safrm.dta, clear 
	prepare_weighted_safmr
	save ../temp/wgt_safmr.dta, replace 

	compare_zillow_safmr_zipcode, tseries(sfcc) inzillow(`instub_zillow') insafmr(`instub_safmr') mlist(1 6 12)


end 

program prepare_ahs_weights
	
	collapse (sum) estimate, by(year br)

	bys year: egen tot_house = sum(estimate)
	g br_share = estimate / tot_house

	keep year br br_share

	tsset br year 
	tsfill
	bys br: carryforward br_share, replace 
end 

program prepare_weighted_safmr
	unab safmrvars: safmr*
	collapse (mean) `safmrvars', by(year)
	reshape long safmr@br, i(year) j(br)
	rename safmrbr safmr
	merge 1:1 year br using ../temp/ahs_wgt.dta, nogen assert(1 2 3) keep(1 3)
	collapse (mean) safmr [w = br_share], by(year)
end 


program compare_zillow_safmr_zipcode
	syntax, tseries(str) inzillow(str) insafmr(str) mlist(str)
	
	local target vars "" 
	foreach s in `tseries' {
		local target_vars `"`target_vars' medrentprice_`s'"'
	}
	
	use zipcode place_code msa countyfips statefips ///
		year_month `target_vars' ///
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

	preserve
	collapse (mean) `target_vars', by(year)
	merge 1:1 year using ../temp/wgt_safmr.dta, nogen assert(1 2 3) keep(1 3)

	merge 1:1 year using ../temp/cpi2012.dta, nogen keep(1 3)
	foreach v in `target_vars' safmr {
		replace `v' = `v'/cpi2012
	}

	twoway (line medrentprice_sfcc year, lc(eltblue)) ///
		   (line safmr year, lp(dash) lc(gs10)), ///
		   legend(order(1 "zillow single family/condo" 2 "SAFMR")) ///
		   ylabel(500(500)2000, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
		   xlabel(, labsize(small))  xtitle(, size(medsmall))
	graph export ../output/trend_zillow_safmrwgt_zipcode_avg.png, replace
	restore 
	* Option 1: take year average 
	preserve
	collapse (mean) `target_vars', by(zipcode year)
	merge 1:1 zipcode year using `insafmr'/safrm.dta	

	unab safmrvars: safmr*
	local target_final `"`target_vars' `safmrvars'"'
	collapse (mean) `target_final', by(year)

	merge 1:1 year using ../temp/cpi2012.dta, nogen keep(1 3)
	foreach v in `target_final' {
		replace `v' = `v'/cpi2012
	}

	twoway (line medrentprice_sfcc year, lc(eltblue)) ///
		   (line safmr2br year, lp(dash) lc(gs11)) ///
		   (line safmr3br year, lp(dash) lc(lavender)) ///
		   (line safmr4br year, lp(dash) lc(black)), ///
		   legend(order(1 "zillow single family/condo" 2 "SAFMR 2br" 3 "SAFMR 3br" 4 "SAFMR 4br") cols(3)) ///
		   ylabel(, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
		   xlabel(, labsize(small)) xtitle(, size(medsmall))
	graph export ../output/trend_zillow_safmr_zipcode_avg.png, replace

	twoway (line medrentprice_sfcc year, lc(eltblue)) ///
		   (line safmr3br year, lp(dash) lc(black)), ///
		   legend(order(1 "zillow single family/condo" 2 "SAFMR 3br") cols(3)) ///
		   ylabel(, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
		   xlabel(, labsize(small)) xtitle(, size(medsmall))
	graph export ../output/trend_zillow_safmr3br_zipcode_avg.png, replace

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
			replace `v' = `v'/cpi2012
		}

		twoway (line medrentprice_sfcc year, lc(eltblue)) ///
			   (line safmr2br year, lp(dash) lc(gs11)) (line safmr3br year, lp(dash) lc(lavender)) (line safmr4br year, lp(dash) lc(black)), ///
			   legend(order(1 "zillow single family/condo" 2 "SAFMR 2br" 3 "SAFMR 3br" 4 "SAFMR 4br") cols(3)) ///
			   ylabel(, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
			   xlabel(, labsize(small)) xtitle(, size(medsmall))
		graph export ../output/trend_zillow_safmr_zipcode_m`m'.png, replace

		twoway (line medrentprice_sfcc year, lc(eltblue)) ///
			   (line safmr3br year, lp(dash) lc(black)), ///
			   legend(order(1 "zillow single family/condo" 2 "SAFMR 3br") cols(3)) ///
			   ylabel(, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
			   xlabel(, labsize(small)) xtitle(, size(medsmall))
		graph export ../output/trend_zillow_safmr3br_zipcode_m`m'.png, replace
		restore	
	}

	*binscatter correlation 	
	collapse (mean) `target_vars', by(zipcode year)
	merge 1:1 zipcode year using `insafmr'/safrm.dta	

	reshape long safmr@br, i(zipcode year `target_vars') j(safmr_type)

	* zipcode average time series correlations
	preserve 
	collapse (mean) medrentprice_sfcc safmrbr, by(year safmr_type)
	bys safmr_type: corr medrentprice_sfcc safmrbr
	restore


	binscatter medrentprice_sfcc safmrbr if safmr_type>0, ///
	by(safmr_type) absorb(zipcode) ylabel(0(1000)6000, grid labsize(small)) xlabel(0(1000)4000, labsize(small)) ///
	ytitle("Median Rent Price (2012 USD)", size(medsmall)) xtitle("Small Area Fair Market Rent", size(medsmall)) ///
	legend(order(1 "1br" 2 "2br" 3 "3br" 4 "4br") rows(1))
	graph export ../output/bins_sfcc_safmr_bytype.png, replace

	winsor2 medrentprice_sfcc, replace by(safmr_type year) cuts(5 95)

	foreach var in medrentprice_sfcc safmrbr {
		qui reghdfe `var' if safmr_type==`nbr', absorb(zipcode) res(`var'R)
	}
	local nbr = 3
	qui corr medrentprice_sfccR safmrbrR if safmr_type==`nbr'
	local rho = round(r(rho), .001)
	di `rho'

	qui reghdfe medrentprice_sfcc safmrbr if safmr_type==`nbr', absorb(zipcode)
	local estbeta = round(_b[safmrbr], .001)
	local estse = round(_se[safmrbr], .001)
	binscatter medrentprice_sfcc safmrbr if safmr_type==`nbr', ///
	absorb(zipcode)  ///
	ytitle("Median Rent Price (2012 USD)", size(medsmall)) xtitle("Small Area Fair Market Rent - `nbr'br", size(medsmall)) ///
	mc(eltblue) lc(gs10) text(1600 2200 "{&beta} = `estbeta' (`estse')") text(1580 2150 "{&rho} = `rho'")

	graph export ../output/bins_sfcc_safmr`nbr'br.png, replace

end


main 
