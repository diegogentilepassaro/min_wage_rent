set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
	foreach var in medrentprice_sfcc medrentprice_mfr5plus medrentprice_2br ///
	    medrentpricepsqft_sfcc medrentpricepsqft_mfr5plus medrentpricepsqft_2br {
		
	    create_baseline_panel, var(`var') balance_date(01jan2015) ///
		    start_date(01jan2010) end_date(12dec2019)
	}
	use "../temp/baseline_medrentprice_sfcc.dta", clear
	foreach var in medrentprice_mfr5plus medrentprice_2br ///
	    medrentpricepsqft_sfcc medrentpricepsqft_mfr5plus medrentpricepsqft_2br {
		
		merge 1:1 zipcode year_month using "../temp/baseline_`var'.dta", ///
		    nogen keep(1 3)
		}
	save_data "../../../drive/derived_large/output/baseline_rent_panel.dta", key(zipcode year_month) replace

	foreach var in medlistingprice_sfcc medlistingprice_low_tier ///
	    medlistingprice_top_tier medlistingpricepsqft_sfcc ///
		medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier {
		
	    create_baseline_panel, var(`var') balance_date(01jan2015) ///
		    start_date(01jan2010) end_date(12dec2019)
	}
	use "../temp/baseline_medlistingpricepsqft_sfcc.dta", clear
	foreach var in medlistingprice_sfcc medlistingprice_low_tier ///
	    medlistingprice_top_tier ///
		medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier {
		
		merge 1:1 zipcode year_month using "../temp/baseline_`var'.dta", ///
		    nogen keep(1 3)
		}
	save_data "../../../drive/derived_large/output/baseline_listing_panel.dta", key(zipcode year_month) replace

	use "../temp/zipcode_yearmonth_panel.dta", clear
	save_data "../../../drive/derived_large/output/zipcode_yearmonth_panel_all.dta", key(zipcode year_month) replace
end

program create_baseline_panel
    syntax, var(str) balance_date(str) start_date(str) end_date(str)
	
    use zipcode place_code placetype statefips msa countyfips county ///
	    year_month calendar_month `var' ///
	    actual_mw dactual_mw mw_event ///
		local_abovestate_mw county_abovestate_mw local_mw ///
		county_mw state_mw fed_mw ///
		sal_mw_event mw_event025 mw_event075 ///
		using "../temp/zipcode_yearmonth_panel.dta", clear
		
	keep if (year_month >= `=mofd(td(`start_date'))' & year_month <= `=mofd(td(`end_date'))')

	preserve
	keep if year_month == `=mofd(td(`balance_date'))'
	keep if !missing(`var')
	keep zipcode
	save_data "../temp/`var'_nonmiss_zipcodes.dta", replace ///
	    key(zipcode) log(none)
	restore
	
	merge m:1 zipcode using "../temp/`var'_nonmiss_zipcodes.dta", ///
	    keep(3) nogen
		
	xtset zipcode year_month
	assert r(balanced) == "strongly balanced"
	
	save_data "../temp/baseline_`var'.dta", key(zipcode year_month) ///
	    replace log(none)
end 

main
