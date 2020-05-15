set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main 
    use "../../../drive/derived_large/output/zipcode_yearmonth_panel_all.dta", clear
	
	local rent_vars "medrentprice_sfcc medrentpricepsqft_sfcc"
	local listing_vars "medlistingprice_sfcc medlistingpricepsqft_sfcc"
	
	collapse_to_county_quarter, rent_vars(`rent_vars') listing_vars(`listing_vars')
	
	tostring countyfips, replace
	replace countyfips  = string(real(countyfips),"%05.0f")
	
	tostring statefips, replace
	replace statefips  = string(real(statefips),"%02.0f")
	
	merge 1:1 year_quarter countyfips using "../temp/county_quarter_emp_wage.dta", nogen ///
	    keep(1 3) 
	
	save_data "../../../drive/derived_large/output/county_quarter_panel_all.dta", ///
	    key(countyfips year_quarter) replace
		
	foreach var in `rent_vars' {
	
	    create_baseline_panel, var(`var') balance_date(01jan2013) ///
		    start_date(01jan2010) end_date(12dec2019)
	}
	
	use "../temp/baseline_medrentprice_sfcc.dta", clear
	foreach var in medrentpricepsqft_sfcc {
	
		merge 1:1 countyfips year_quarter using "../temp/baseline_`var'.dta", ///
		    nogen keep(1 3)
		}
	save_data "../../../drive/derived_large/output/baseline_rent_county_quarter.dta", ///
	    key(countyfips year_quarter) replace
		
   foreach var in `listing_vars' {
   
	    create_baseline_panel, var(`var') balance_date(01jan2013) ///
		    start_date(01jan2010) end_date(12dec2019)
	}
	
	use "../temp/baseline_medlistingpricepsqft_sfcc.dta", clear
	foreach var in medlistingprice_sfcc {
	
		merge 1:1 countyfips year_quarter using "../temp/baseline_`var'.dta", ///
		    nogen keep(1 3)
		}
	save_data "../../../drive/derived_large/output/baseline_listing_county_quarter.dta", ///
	    key(countyfips year_quarter) replace
end  

program collapse_to_county_quarter
    syntax, rent_vars(str) listing_vars(str)
	
    gen year_quarter = qofd(dofm(year_month))
    format %tq year_quarter
	
	collapse (mean) `rent_vars' `listing_vars' ///
	    (max) mw_event dactual_mw sal_mw_event mw_event025 mw_event075 ///
		calendar_quarter = calendar_month houses10_zip_county, ///
	    by(zipcode year_quarter placename placetype city msa countyfips county statefips stateabb)
		
	xtset zipcode year_quarter /* to assert is keyed on zipcode year_quarter */
	
	collapse (mean) `rent_vars' `listing_vars' ///
	    (max) mw_event dactual_mw sal_mw_event mw_event025 mw_event075 [aweight = houses10_zip_county], ///
	    by(countyfips year_quarter ///
		calendar_quarter county statefips stateabb)
end

program create_baseline_panel
    syntax, var(str) balance_date(str) start_date(str) end_date(str)
	
	use "../../../drive/derived_large/output/county_quarter_panel_all.dta", clear
	keep if (year_quarter >= `=qofd(td(`start_date'))' & year_quarter <= `=qofd(td(`end_date'))')

	preserve
	keep if year_quarter == `=qofd(td(`balance_date'))'
	keep if !missing(`var')
	keep countyfips
	save_data "../temp/`var'_nonmiss_countyfips.dta", replace ///
	    key(countyfips) log(none)
	restore
	
	merge m:1 countyfips using "../temp/`var'_nonmiss_countyfips.dta", ///
	    keep(3) nogen
	
	rename countyfips countyfips_str
	encode countyfips_str, gen(countyfips)
	
	xtset countyfips year_quarter
	assert r(balanced) == "strongly balanced"
	
	save_data "../temp/baseline_`var'.dta", key(countyfips year_quarter) ///
	    replace log(none)
end

main
