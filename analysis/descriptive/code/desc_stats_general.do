set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado


program main 
	local instub  = "../../../drive/" 
	local outstub = "../output/"

	// us_stats, instub(`instub')
	us_stats_new, instub(`instub')

	baseline_rent_stats, instub(`instub') target_zillow("medrentpricepsqft_2br medrentpricepsqft_mfr5plus medrentpricepsqft_sfcc")
	baseline_listing_stats, instub(`instub') target_zillow("medlistingpricepsqft_sfcc medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier")
	baseline_yearmonth_stats, instub(`instub') target_zillow("medrentpricepsqft_2br medrentpricepsqft_mfr5plus medrentpricepsqft_sfcc medlistingpricepsqft_sfcc medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier")

	build_table, target_zillow("medrentpricepsqft_2br medrentpricepsqft_mfr5plus medrentpricepsqft_sfcc medlistingpricepsqft_sfcc medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier") 
end 


program us_stats_new 
	syntax, instub(str)

	import delim `instub'/base_large/output/zip_demo.csv, clear


	collapse (sum) pop2010 housing_units2010 (mean) urb_share2010 college_share2010 poor_share20105 black_share2010 hisp_share2010 child_share2010 elder_share2010 unemp_share20105 med_hhinc20105 renthouse_share2010 work_county_share20105 (count) zipcode



	g pop_sh = 1
	g housing_units_sh = 1
	g zipcode_sh = 1

	order zipcode zipcode_sh pop2010 pop_sh housing_units2010 housing_units_sh med_hhinc20105 renthouse_share2010 urb_share2010 college_share2010 black_share2010 hisp_share2010 poor_share20105 child_share2010 elder_share2010 unemp_share20105 work_county_share20105
	save ../temp/us_panel_stats_zipcode.dta, replace

	keep pop2010 housing_units2010 zipcode
	rename (pop housing_units zipcode) (USpop UShousing_units USzipcode)
	save ../temp/us_totals.dta, replace 





end


program us_stats
	syntax, instub(str)

	import delim `instub'/raw_data/census/tract/nhgis0041_csv/nhgis0041_ds239_20185_2018_tract.csv, clear

	g statefips = string(statea, "%02.0f")
	g countyfips = string(countya, "%03.0f")
	g tractfips = string(tracta, "%06.0f")

	g tract_fips = statefips + countyfips + tractfips

	rename (ajwme001 aj1se001 ajzae001) (pop housing_units med_hhinc)

	g housing_rent_sh = aj1ue003 / aj1ue001

	
	order aj1ue003 aj1ue001, last
	replace housing_rent_sh = 0 if aj1ue003 == 0 & aj1um001==0 

	keep tract_fips pop housing_units housing_rent_sh med_hhinc

	save ../temp/us_stats_tract.dta, replace

	import excel `instub'/raw_data/hud_Xwalks/TRACT_ZIP_122018.xlsx, firstrow clear
	rename (tract zip) (tract_fips zipcode)
	keep tract_fips zipcode tot_ratio


	merge m:1 tract_fips using ../temp/us_stats_tract.dta, nogen assert(1 2 3) keep(1 3)
	sort zipcode

	collapse (sum) pop housing_units (mean) med_hhinc housing_rent_sh [iw = tot_ratio], by (zipcode)

	save ../temp/us_stats_zipcode.dta, replace

	destring zipcode, replace
	collapse (sum) pop housing_units (mean) med_hhinc housing_rent_sh (count) zipcode

	g pop_sh = 1
	g housing_units_sh = 1
	g zipcode_sh = 1

	order zipcode zipcode_sh pop pop_sh housing_units housing_units_sh med_hhinc housing_rent_sh
	save ../temp/us_panel_stats_zipcode.dta, replace

	keep pop housing_units zipcode
	rename (pop housing_units zipcode) (USpop UShousing_units USzipcode)
	save ../temp/us_totals.dta, replace 


end

program baseline_rent_stats
	syntax, instub(str) target_zillow(str)
	use `instub'/derived_large/output/baseline_rent_panel.dta, clear

	create_stats_final_dsets, target_zillow(`target_zillow')
	save ../temp/rent_panel_stats_zipcode.dta, replace 
end 


program baseline_listing_stats
	syntax, instub(str) target_zillow(str)

	use `instub'/derived_large/output/baseline_listing_panel.dta, clear

	create_stats_final_dsets, target_zillow(`target_zillow')

	
	save ../temp/listing_panel_stats_zipcode.dta, replace 
end 


program baseline_yearmonth_stats
	syntax, instub(str) target_zillow(str)

	use "../../../drive/derived_large/output/zipcode_yearmonth_panel_all.dta", clear
	
	replace sal_mw_event =. if missing(mw_event)	

	local target_zillow_count = ""
	foreach var of local target_zillow {
		local newvar "N`var' = `var'"
		local target_zillow_count = `" `target_zillow_count' `newvar' "'
	}
		
	collapse (sum)  mw_event sal_mw_event fed_event state_event county_event local_event ///
			 (mean)  `target_zillow' ///
			 (count) `target_zillow_count' ///
			 (first) pop2010 housing_units2010 urb_share2010 college_share2010 poor_share20105 black_share2010 hisp_share2010 child_share2010 elder_share2010 unemp_share20105 med_hhinc20105 renthouse_share2010 work_county_share20105 ///
 			, by(zipcode)

	foreach var `target_zillow_count' {
		replace `var' = . if `var'==0
	} 

	local target_zillow_N = ""
	foreach var of local target_zillow {
		local newvar "N`var'"
		local target_zillow_N = `" `target_zillow_N' `newvar' "'
	}

	collapse (sum)  pop2010 housing_units2010 ///
			 (mean)  urb_share2010 college_share2010 poor_share20105 black_share2010 hisp_share2010 ///
			 	     child_share2010 elder_share2010 unemp_share20105 med_hhinc20105 renthouse_share2010 work_county_share20105 ///
				     mw_event sal_mw_event fed_event state_event county_event local_event ///
				     `target_zillow'  ///
			 (count) zipcode `target_zillow_N'


	merge 1:1 _n using ../temp/us_totals, nogen assert(1 2 3)

	g pop_sh = pop2010/USpop
	g housing_units_sh = housing_units2010/UShousing_units
	g zipcode_sh = zipcode/USzipcode

	drop USpop UShousing_units USzipcode

	order zipcode zipcode_sh pop2010 pop_sh housing_units2010 housing_units_sh med_hhinc20105 renthouse_share2010 urb_share2010 college_share2010 black_share2010 hisp_share2010 poor_share20105 child_share2010 elder_share2010 unemp_share20105 work_county_share20105 mw_event sal_mw_event fed_event state_event county_event local_event

	// keep if year_month == `=tm(2019m1)'
	// g zip2 = string(zipcode, "%05.0f")
	// drop zipcode 
	// rename zip2 zipcode 
	// tempfile baseline_yearmonth_zip 
	// save "`baseline_yearmonth_zip'", replace 

	// use ../temp/us_stats_zipcode.dta, clear 

	// merge 1:1 zipcode using `baseline_yearmonth_zip', nogen assert(1 2 3) keep(1 3)

	// destring zipcode, replace

	// collapse (sum) pop housing_units (mean) med_hhinc housing_rent_sh (count) zipcode

	// merge 1:1 _n using ../temp/us_totals, nogen assert(1 2 3)

	// g pop_sh = pop/USpop
	// g housing_units_sh = housing_units/UShousing_units
	// g zipcode_sh = zipcode/USzipcode

	// drop USpop UShousing_units USzipcode

	// order zipcode zipcode_sh pop pop_sh housing_units housing_units_sh med_hhinc housing_rent_sh

	save ../temp/yearmonth_panel_stats_zipcode.dta, replace 
end 


program build_table 
	syntax, target_zillow(str)

	local table_len = 23 
	foreach var of local target_zillow {

		local table_len = `table_len' + 2
	}


	mat t = J(`table_len', 4, .)
	
	use          ../temp/us_panel_stats_zipcode.dta, clear
	append using ../temp/yearmonth_panel_stats_zipcode.dta
	append using ../temp/listing_panel_stats_zipcode.dta
	append using ../temp/rent_panel_stats_zipcode.dta
	
	format pop2010 housing_units2010 med_hhinc %20.0fc

	foreach var in pop2010 housing_units2010 {
		replace `var' = `var'/1000000
	}


	forval x = 1/4 {
		mat t[1, `x'] = zipcode[`x']
		mat t[2, `x'] = round(zipcode_sh[`x'], .001) 
		mat t[3, `x'] = round(pop2010[`x'], .001)
		mat t[4, `x'] = round(pop_sh[`x'], .001)
		mat t[5, `x'] = round(housing_units2010[`x'], .001)
		mat t[6, `x'] = round(housing_units_sh[`x'], .001)
		mat t[7, `x'] = round(med_hhinc20105[`x']', 1)
		mat t[8, `x'] = round(renthouse_share2010[`x'], .001)
		mat t[9, `x'] = round(urb_share2010[`x'], .001)
		mat t[10, `x'] = round(college_share2010[`x'], .001)
		mat t[11, `x'] = round(black_share2010[`x'], .001)
		mat t[12, `x'] = round(hisp_share2010[`x'], .001)
		mat t[13, `x'] = round(poor_share20105[`x'], .001)
		mat t[14, `x'] = round(child_share2010[`x'], .001)
		mat t[15, `x'] = round(elder_share2010[`x'], .001)
		mat t[16, `x'] = round(unemp_share20105[`x'], .001)
		mat t[17, `x'] = round(work_county_share20105[`x'], .001)
		mat t[18, `x'] = round(mw_event[`x'], .001)
		mat t[19, `x'] = round(sal_mw_event[`x'], .001)
		mat t[20, `x'] = round(fed_event[`x'], .001)
		mat t[21, `x'] = round(state_event[`x'], .001)
		mat t[22, `x'] = round(county_event[`x'], .001)
		mat t[23, `x'] = round(local_event[`x'], .001)
	}

	local tabrow = 24

	local target_zillow_both = ""
	foreach var of local target_zillow {
		local target_zillow_both = `"`target_zillow_both' `var' N`var'"'
	}

	di "`target_zillow_both'"
	foreach var in `target_zillow_both' {
		forval x = 1/4 {
			mat t[`tabrow', `x'] = round(`var'[`x'], .001)
		}
		local tabrow = `tabrow' + 1
	}

	local label_zillow = ""
	foreach var of local target_zillow_both {
		if "`var'" == "medrentpricepsqft_sfcc" {
			local label_zillow = `"`label_zillow' "Median Rent psqft SFCC""'
		}
		if "`var'" == "Nmedrentpricepsqft_sfcc" | "`var'" == "Nmedrentpricepsqft_2br" | "`var'" == "Nmedrentpricepsqft_mfr5plus" | "`var'" == "Nmedlistingpricepsqft_sfcc" | "`var'" == "Nmedlistingpricepsqft_low_tier" | "`var'" == "Nmedlistingpricepsqft_top_tier" {
			local label_zillow = `"`label_zillow' "(N)""'
		}
		if "`var'" == "medrentpricepsqft_2br" {
			local label_zillow = `"`label_zillow' "Median Rent psqft 2BR""'
		}
		if "`var'" == "medrentpricepsqft_mfr5plus" {
			local label_zillow = `"`label_zillow' "Median Rent psqft MFR5PLUS""'
		}
		if "`var'" == "medlistingpricepsqft_sfcc" {
			local label_zillow = `"`label_zillow' "Median Listing psqft SFCC""'
		}
		if "`var'" == "medlistingpricepsqft_low_tier" {
			local label_zillow = `"`label_zillow' "Median Listing psqft 5-35th pct""'
		}
		if "`var'" == "medlistingpricepsqft_top_tier" {
			local label_zillow = `"`label_zillow' "Median Listing psqft 65-95th pct""'
		}
	}
	di `label_zillow'
		
	local rownames =  `" "zipcode" "(\%)" "population (Million)" "(\%)"  "housing units (Million)" "(\%)"  "median income"  "Houses for rent (\%)" "Urban population (\%)" "College Educated (\%)" "Black population (\%)" "Hispanic population (\%)" "Pop. in poverty (\%)" "Children 0-5 (\%)" "Elders 65+ (\%)" "Unemployed (\%)" "Work in same County (\%)" "MW events" "Salient MW events" "Fed MW event" "State MW event" "County MW Event" "Local MW Event" "'

	foreach var of local label_zillow {
		local rownames =  `" `rownames' "`var'" "' 
	}

	mat rowname t = `rownames'

	mat colname t = "U.S." "Full Panel" "Listing Panel" "Rent Panel" 

	mat list t 
	esttab matrix(t) using ../output/desc_stats.tex, replace 
end




program create_stats_final_dsets
	syntax, target_zillow(str)
	replace sal_mw_event =. if missing(mw_event)	

	local target_zillow_count = ""
	foreach var of local target_zillow {
		local newvar "N`var' = `var'"
		local target_zillow_count = `" `target_zillow_count' `newvar' "'
	}

	collapse (sum)  mw_event sal_mw_event fed_event state_event county_event local_event ///
			 (mean)  `target_zillow' ///
			 (count) `target_zillow_count' ///
			 (first) pop2010 housing_units2010 urb_share2010 college_share2010 poor_share20105 black_share2010 hisp_share2010 child_share2010 elder_share2010 unemp_share20105 med_hhinc20105 renthouse_share2010 work_county_share20105 ///
			 , by(zipcode) 	

	local target_zillow_N = ""
	foreach var of local target_zillow {
		local newvar "N`var'"
		local target_zillow_N = `" `target_zillow_N' `newvar' "'
	}

	collapse (sum)  pop2010 housing_units2010 ///
			 (mean)  urb_share2010 college_share2010 poor_share20105 black_share2010 hisp_share2010 ///
			 	     child_share2010 elder_share2010 unemp_share20105 med_hhinc20105 renthouse_share2010 work_county_share20105 ///
				     mw_event sal_mw_event fed_event state_event county_event local_event ///
				     `target_zillow'  ///
			 (count) zipcode `target_zillow_N'


	merge 1:1 _n using ../temp/us_totals, nogen assert(1 2 3)

	g pop_sh = pop2010/USpop
	g housing_units_sh = housing_units2010/UShousing_units
	g zipcode_sh = zipcode/USzipcode

	drop USpop UShousing_units USzipcode

	order zipcode zipcode_sh pop2010 pop_sh housing_units2010 housing_units_sh med_hhinc20105 renthouse_share2010 urb_share2010 college_share2010 black_share2010 hisp_share2010 poor_share20105 child_share2010 elder_share2010 unemp_share20105 work_county_share20105 mw_event sal_mw_event fed_event state_event county_event local_event

end



main 
