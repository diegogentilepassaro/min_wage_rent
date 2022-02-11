clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main 
	local instub_zillow "../../../drive/derived_large/estimation_samples"
	local instub_safmr "../../../base/safmr/output"
	local logfile "../output/data_file_manifest.log"
	
	import delim "../../../drive/raw_data/census/cpi2012_usa.csv", clear  
	replace cpi2012 = cpi2012 /100
	save ../temp/cpi2012.dta, replace

	import delim "../../../drive/raw_data/ahs/AHS_sfcc_est_by_br.csv", clear
	prepare_ahs_weights
	save ../temp/ahs_wgt.dta, replace 
	
	use "`instub_safmr'/safrm_2017_2019_by_zipcode_cbsa10.dta", clear
	collapse (sum) safmr1br safmr2br safmr3br safmr4br, ///
	    by(zipcode year)
	save "../temp/safmr_2017_2019.dta", replace
	
	use "`instub_safmr'/safrm_2012_2016_by_zipcode_county_cbsa10.dta", clear
	collapse (sum) safmr1br safmr2br safmr3br safmr4br, ///
	    by(zipcode year)
	append using "../temp/safmr_2017_2019.dta"
	save "../temp/safmr.dta", replace
	prepare_weighted_safmr
	save ../temp/wgt_safmr.dta, replace 

	compare_zillow_safmr_zipcode, inzillow(`instub_zillow') ///
	    mlist(1 6 12)
	drop _merge
	reshape wide medrentprice_SFCC safmrbr, i(zipcode safmr_type) j(year)
	gen chg_safmrbr = safmrbr2019 - safmrbr2018
	gen chg_medrent_price = medrentprice_SFCC2019 - medrentprice_SFCC2018
	
	binscatter chg_medrent_price chg_safmrbr if safmr_type == 2
	graph export "../output/binscatter_zillow_vs_safmr2br.png", replace
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
	merge 1:1 year br using "../temp/ahs_wgt.dta", nogen assert(1 2 3) keep(1 3)
	collapse (mean) safmr [w = br_share], by(year)
end 


program compare_zillow_safmr_zipcode
	syntax, inzillow(str) mlist(str)
	
	use zipcode place_code cbsa10 countyfips statefips ///
		year_month medrentprice_SFCC ///
		using "`inzillow'/all_zipcode_months.dta"

	g rmtag = (medrentprice_SFCC == .)
	bys zipcode (year_month): g ziplen = _N
	bys zipcode (year_month): gegen rmcount = sum(rmtag)
	g sample_SFCC = (ziplen != rmcount)
	drop ziplen rmtag rmcount

	unab samplist: sample_*
	gegen allmis = rowtotal(`samplist')
	drop if allmis==0 
	drop allmis 
	g year = yofd(dofm(year_month))
	keep if inrange(year, 2010, 2019)

	preserve
	collapse (mean) medrentprice_SFCC, by(year)
	merge 1:1 year using ../temp/wgt_safmr.dta, nogen assert(1 2 3) keep(1 3)

	merge 1:1 year using ../temp/cpi2012.dta, nogen keep(1 3)
	foreach v in medrentprice_SFCC safmr {
		replace `v' = `v'/cpi2012
	}
	
	corr safmr medrentprice_SFCC

	twoway (line medrentprice_SFCC year, lc(eltblue)) ///
		   (line safmr year, lp(dash) lc(gs10)), ///
		   legend(order(1 "zillow single family/condo" 2 "SAFMR")) ///
		   ylabel(500(500)2000, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
		   xlabel(, labsize(small))  xtitle(, size(medsmall)) ///
		   graphregion(color(white)) bgcolor(white)
	graph export "../output/trend_zillow_safmrwgt_zipcode_avg.png", replace
	restore 
	* Option 1: take year average 
	preserve
	collapse (mean) medrentprice_SFCC, by(zipcode year)
	merge 1:1 zipcode year using "../temp/safmr.dta"

	unab safmrvars: safmr*
	collapse (mean) medrentprice_SFCC `safmrvars', by(year)

	merge 1:1 year using "../temp/cpi2012.dta", nogen keep(1 3)
	foreach v in  medrentprice_SFCC `safmrvars' {
		replace `v' = `v'/cpi2012
	}

	twoway (line medrentprice_SFCC year, lc(eltblue)) ///
		   (line safmr2br year, lp(dash) lc(gs11)) ///
		   (line safmr3br year, lp(dash) lc(lavender)) ///
		   (line safmr4br year, lp(dash) lc(black)), ///
		   legend(order(1 "zillow single family/condo" 2 "SAFMR 2br" 3 "SAFMR 3br" 4 "SAFMR 4br") cols(3)) ///
		   ylabel(, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
		   xlabel(, labsize(small)) xtitle(, size(medsmall)) ///
		   graphregion(color(white)) bgcolor(white)
	graph export "../output/trend_zillow_safmr_zipcode_avg.png", replace

	twoway (line medrentprice_SFCC year, lc(eltblue)) ///
		   (line safmr3br year, lp(dash) lc(black)), ///
		   legend(order(1 "zillow single family/condo" 2 "SAFMR 3br") cols(3)) ///
		   ylabel(, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
		   xlabel(, labsize(small)) xtitle(, size(medsmall)) ///
		   graphregion(color(white)) bgcolor(white)
	graph export "../output/trend_zillow_safmr3br_zipcode_avg.png", replace

	restore

	* Option 2: take given month 
	foreach m in `mlist' {
		preserve
		g month = month(dofm(year_month))

		keep if month == `m'
		merge 1:1 zipcode year using "../temp/safmr.dta"	


		unab safmrvars: safmr*
		collapse (mean)  medrentprice_SFCC `safmrvars', by(year)

		merge 1:1 year using "../temp/cpi2012.dta", nogen keep(1 3)
		foreach v in medrentprice_SFCC {
			replace `v' = `v'/cpi2012
		}

		twoway (line medrentprice_SFCC year, lc(eltblue)) ///
			   (line safmr2br year, lp(dash) lc(gs11)) (line safmr3br year, lp(dash) lc(lavender)) (line safmr4br year, lp(dash) lc(black)), ///
			   legend(order(1 "zillow single family/condo" 2 "SAFMR 2br" 3 "SAFMR 3br" 4 "SAFMR 4br") cols(3)) ///
			   ylabel(, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
			   xlabel(, labsize(small)) xtitle(, size(medsmall)) ///
			   graphregion(color(white)) bgcolor(white)
		graph export ../output/trend_zillow_safmr_zipcode_m`m'.png, replace

		twoway (line medrentprice_SFCC year, lc(eltblue)) ///
			   (line safmr3br year, lp(dash) lc(black)), ///
			   legend(order(1 "zillow single family/condo" 2 "SAFMR 3br") cols(3)) ///
			   ylabel(, grid labsize(small)) ytitle("Rent (2012 USD)", size(medsmall)) ///
			   xlabel(, labsize(small)) xtitle(, size(medsmall)) ///
			   graphregion(color(white)) bgcolor(white)
		graph export "../output/trend_zillow_safmr3br_zipcode_m`m'.png", replace
		restore	
	}

	*binscatter correlation 	
	collapse (mean) medrentprice_SFCC, by(zipcode year)
	merge 1:1 zipcode year using "../temp/safmr.dta"	

	reshape long safmr@br, i(zipcode year medrentprice_SFCC) j(safmr_type)

	* zipcode average time series correlations
	preserve 
		collapse (mean) medrentprice_SFCC safmrbr, by(year safmr_type)
		bys safmr_type: corr medrentprice_SFCC safmrbr
	restore

	winsor2 medrentprice_SFCC, replace by(safmr_type year) cuts(5 95)

	preserve
	local nbr = 3
	foreach var in medrentprice_SFCC safmrbr {
		qui reghdfe `var' if safmr_type==`nbr', absorb(zipcode) res(`var'R)
	}
	qui corr medrentprice_SFCCR safmrbrR if safmr_type==`nbr'
	local rho = round(r(rho), .001)
	di `rho'

	qui reghdfe medrentprice_SFCC safmrbr if safmr_type==`nbr', absorb(zipcode)
	local estbeta = round(_b[safmrbr], .001)
	local estse = round(_se[safmrbr], .001)
	binscatter medrentprice_SFCC safmrbr if safmr_type==`nbr', ///
	absorb(zipcode) ///
	ytitle("Median Rent Price (2012 USD)", size(medsmall)) xtitle("Small Area Fair Market Rent - `nbr'br", size(medsmall)) ///
	mc(navy) lc(gs10) text(1600 2200 "{&beta} = `estbeta' (`estse')") text(1580 2150 "{&rho} = `rho'")

	graph export "../output/bins_sfcc_safmr`nbr'br.png", replace
	restore
end


main 