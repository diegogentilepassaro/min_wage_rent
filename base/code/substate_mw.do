set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado

program main 
	import_crosswalk
	substate_min_wage_change "VZ_SubstateMinimumWage_Changes"
	prepare_local
	prepare_state 01Jul2016
	prepare_finaldata 01Jul2016

	export_substate_daily
	export_substate_monthly
	export_substate_quarterly
	export_substate_annually
end 

program import_crosswalk
	import excel using "../../raw_data/min_wage/FIPS_crosswalk.xlsx", clear firstrow 
	
	rename Name statename
	rename FIPSStateNumericCode statefips
	rename OfficialUSPSCode stateabb
	replace stateabb = upper(stateabb)
	keep statename statefips stateabb

	save ${temp}crosswalk.dta, replace
end

program substate_min_wage_change
	args substate
	import excel using "../../raw_data/min_wage/`substate'.xlsx", clear firstrow

	gen date = mdy(month,day,year)
	format date %td

	gen double mw = round(VZ_mw, .01)
	gen double mw_tipped = round(VZ_mw_tipped, .01)
	gen double mw_healthinsurance = round(VZ_mw_healthinsurance, .01)
	gen double mw_smallbusiness = round(VZ_mw_smallbusiness, .01)
	gen double mw_smallbusiness_mincomp = round(VZ_mw_smallbusiness_mincompensat, .01)
	gen double mw_hotel = round(VZ_mw_hotel, .01)
	drop VZ_mw*

	merge m:1 statefips using "../temp/crosswalk.dta", nogen keep(3)
	label var statefips "State FIPS Code"
	label var statename "State"
	label var stateabb "State Abbreviation"
	label var locality "City/County"
	label var mw "Minimum Wage"
	order statefips statename stateabb locality year month day date mw mw_* source source_2 source_notes

	sort locality date
	export delim using "../output/VZ_substate_changes.csv", replace 
end

program prepare_local
	preserve
	egen tag = tag(statefips locality)
	keep if tag == 1
	keep statefips locality

	save "../temp/localities.dta", replace
	restore
end

program prepare_state
	args finaldate
	sum year
	local minyear = r(min)
	preserve
	// use ${exports}VZ_state_daily.dta, clear
	import delim ${exports}VZ_state_daily.csv, clear 
	g date2 = date(date, "DMY")
	format date2 %td
	order date2, after(date)
	drop date 
	rename date2 date
	keep if year(date) >= `minyear' & date <= td(`finaldate')
	joinby statefips using ${temp}localities.dta
	keep statefips statename stateabb locality date mw
	rename mw state_mw
	save ${temp}statemw.dta, replace
	restore
end

program prepare_finaldata
	args finaldate
	
	encode locality, gen(locality_temp)

	tsset locality_temp date
	tsfill

	foreach x of varlist statename stateabb locality source_notes {
	  bysort locality_temp (date): replace `x' = `x'[_n-1] if `x' == ""
	}
	foreach x of varlist statefips mw* {
	  bysort locality_temp (date): replace `x' = `x'[_n-1] if `x' == .
	}

	keep if date <= td(`finaldate')

	merge 1:m statefips locality date using ${temp}statemw.dta, assert(2 3) nogenerate
	replace mw = state_mw if mw == .
	replace mw = round(mw,0.01)
	gen abovestate = mw > state_mw
	label var abovestate "Local > State min wage"

	keep statefips statename stateabb date locality mw mw_* abovestate source_notes
	order statefips statename stateabb date locality mw mw_* abovestate source_notes
	notes mw: The mw variable represents the most applicable minimum wage across the locality.

	save "../temp/data.dta", replace
	
end

program export_substate_daily	
		use "../temp/data.dta", clear
		sort locality date
		export delim using "../output/VZ_substate_daily.csv", replace
end

program export_substate_monthly
	use "../temp/data.dta", clear

	gen monthly_date = mofd(date)
	format monthly_date %tm

	collapse (min) min_mw = mw (mean) mean_mw = mw (max) max_mw = mw abovestate, by(statefips statename stateabb locality monthly_date)

	label var monthly_date "Monthly Date"
	label var min_mw "Monthly Minimum"
	label var mean_mw "Monthly Average"
	label var max_mw "Monthly Maximum"
	label var abovestate "Local > State min wage"

	sort locality monthly_date

	export delim using "../output/VZ_substate_monthly.csv", replace 
end 

program export_substate_quarterly
	use "../temp/data.dta", clear

	gen quarterly_date = qofd(date)
	format quarterly_date %tq

	collapse (min) min_mw = mw (mean) mean_mw = mw (max) max_mw = mw abovestate, by(statefips statename stateabb locality quarterly_date)

	label var quarterly_date "Quarterly Date"
	label var min_mw "Quarterly Minimum"
	label var mean_mw "Quarterly Average"
	label var max_mw "Quarterly Maximum"
	label var abovestate "Local > State min wage"

	sort locality quarterly_date

	export delim using "../output/VZ_substate_quarterly.csv", replace
end 

program export_substate_annually
	use "../temp/data.dta", clear

	gen year = yofd(date)
	format year %ty

	collapse (min) min_mw = mw (mean) mean_mw = mw (max) max_mw = mw abovestate, by(statefips statename stateabb locality year)

	label var year "Year"
	label var min_mw "Annual Minimum"
	label var mean_mw "Annual Average"
	label var max_mw "Annual Maximum"
	label var abovestate "Local > State min wage"

	sort locality year

	export delim using "../output/VZ_substate_annual.csv", replace 
end

* EXECUTE
main 
