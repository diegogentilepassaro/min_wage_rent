set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado


program main 
	local instub  = "../../../drive/" 
	local outstub = "../output/"

	us_stats, instub(`instub')
	// baseline_rent_stats, instub(`instub')
	// baseline_listing_stats, instub(`instub')
	// baseline_yearmonth_stats, instub(`instub')

	*build_table
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
	syntax, instub(str)

	use `instub'/derived_large/output/baseline_rent_panel.dta, clear
	keep zipcode 
	duplicates drop
	g zip2 = string(zipcode, "%05.0f")
	drop zipcode 
	rename zip2 zipcode 
	tempfile baseline_rent_zip 
	save "`baseline_rent_zip'", replace 

	use ../temp/us_stats_zipcode.dta, clear 

	merge 1:1 zipcode using `baseline_rent_zip', nogen assert(1 2 3) keep(3)

	destring zipcode, replace

	collapse (sum) pop housing_units (mean) med_hhinc housing_rent_sh (count) zipcode

	merge 1:1 _n using ../temp/us_totals, nogen assert(1 2 3)

	g pop_sh = pop/USpop
	g housing_units_sh = housing_units/UShousing_units
	g zipcode_sh = zipcode/USzipcode

	drop USpop UShousing_units USzipcode

	order zipcode zipcode_sh pop pop_sh housing_units housing_units_sh med_hhinc housing_rent_sh

	save ../temp/rent_panel_stats_zipcode.dta, replace 
end 


program baseline_listing_stats
	syntax, instub(str)

	use `instub'/derived_large/output/baseline_listing_panel.dta, clear
	keep zipcode 
	duplicates drop
	g zip2 = string(zipcode, "%05.0f")
	drop zipcode 
	rename zip2 zipcode 
	tempfile baseline_listing_zip 
	save "`baseline_listing_zip'", replace 

	use ../temp/us_stats_zipcode.dta, clear 

	merge 1:1 zipcode using `baseline_listing_zip', nogen assert(1 2 3) keep(3)

	destring zipcode, replace

	collapse (sum) pop housing_units (mean) med_hhinc housing_rent_sh (count) zipcode

	merge 1:1 _n using ../temp/us_totals, nogen assert(1 2 3)

	g pop_sh = pop/USpop
	g housing_units_sh = housing_units/UShousing_units
	g zipcode_sh = zipcode/USzipcode

	drop USpop UShousing_units USzipcode

	order zipcode zipcode_sh pop pop_sh housing_units housing_units_sh med_hhinc housing_rent_sh

	save ../temp/listing_panel_stats_zipcode.dta, replace 
end 


program baseline_yearmonth_stats
	syntax, instub(str)

	use "../../../drive/derived_large/output/zipcode_yearmonth_panel_all.dta", clear
	
	keep if year_month == `=tm(2019m1)'
	g zip2 = string(zipcode, "%05.0f")
	drop zipcode 
	rename zip2 zipcode 
	tempfile baseline_yearmonth_zip 
	save "`baseline_yearmonth_zip'", replace 

	use ../temp/us_stats_zipcode.dta, clear 

	merge 1:1 zipcode using `baseline_yearmonth_zip', nogen assert(1 2 3) keep(1 3)

	destring zipcode, replace

	collapse (sum) pop housing_units (mean) med_hhinc housing_rent_sh (count) zipcode

	merge 1:1 _n using ../temp/us_totals, nogen assert(1 2 3)

	g pop_sh = pop/USpop
	g housing_units_sh = housing_units/UShousing_units
	g zipcode_sh = zipcode/USzipcode

	drop USpop UShousing_units USzipcode

	order zipcode zipcode_sh pop pop_sh housing_units housing_units_sh med_hhinc housing_rent_sh

	save ../temp/yearmonth_panel_stats_zipcode.dta, replace 
end 


program build_table 
	mat t = J(8, 4, .)
	use ../temp/rent_panel_stats_zipcode.dta, clear
	append using ../temp/listing_panel_stats_zipcode.dta
	append using ../temp/yearmonth_panel_stats_zipcode.dta
	append using ../temp/us_panel_stats_zipcode.dta

	format pop housing_units med_hhinc %20.0fc


	forval x = 1/4 {
		mat t[1, `x'] = zipcode[`x']
		mat t[2, `x'] = round(zipcode_sh[`x'], .001) 
		mat t[3, `x'] = pop[`x']
		mat t[4, `x'] = round(pop_sh[`x'], .001)
		mat t[5, `x'] = housing_units[`x']
		mat t[6, `x'] = round(housing_units_sh[`x'], .001)
		mat t[7, `x'] = med_hhinc[`x']'
		mat t[8, `x'] = round(housing_rent_sh[`x'], .001)
	}

	local rownames `" "zipcode" "(\%)" "population" "(\%)"  "housing units" "(\%)"  "median income"  "rent/income ratio" "'
	mat rowname t = `rownames'

	local dsets_names = `" "Rent Panel" "Listing Panel" "Full Panel" "U.S." "'
	mat colname t = `dsets_names'


	outtable using ../output/desc_stats.tex, mat(t) center replace 




end



main 
