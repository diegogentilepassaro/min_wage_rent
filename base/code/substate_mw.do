set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado

program main 
	local raw "../../drive/raw_data/min_wage"
	local exports "../output"
	local temp "../temp"

	import_crosswalk, instub(`raw') outstub(`temp')
	substate_min_wage_change, instub(`raw') outstub(`exports') temp(`temp')
	prepare_local, temp(`temp')
	prepare_state, outstub(`exports') temp(`temp') finaldate(31dec2019)
	prepare_finaldata, temp(`temp') finaldate(31dec2019)

	export_substate_daily,     outstub(`exports') temp(`temp')
	export_substate_monthly,   outstub(`exports') temp(`temp')
	export_substate_quarterly, outstub(`exports') temp(`temp')
	export_substate_annually,  outstub(`exports') temp(`temp')
end 

program import_crosswalk, rclass
	syntax, instub(str) outstub(str)
	import excel using `instub'/FIPS_crosswalk.xlsx, clear firstrow 
	
	rename Name statename
	rename FIPSStateNumericCode statefips
	rename OfficialUSPSCode stateabb
	replace stateabb = upper(stateabb)
	label var stateabb "State Abbreviation"
	
	keep statename statefips stateabb

	save `outstub'/crosswalk.dta, replace
end

program substate_min_wage_change
	syntax, instub(str) outstub(str) temp(str)

	import excel using `instub'/VZ_SubstateMinimumWage_Changes.xlsx, clear firstrow

	gen date = mdy(month,day,year)
	format date %td

	gen double mw                 = round(VZ_mw, .01)
	gen double mw_healthinsurance = round(VZ_mw_healthinsurance, .01)
	gen double mw_macrobusiness   = round(VZ_mw_macrobusiness, .01)
	gen double mw_mediumbusiness  = round(VZ_mw_mediumbusiness, .01)
	gen double mw_smallbusiness   = round(VZ_mw_smallbusiness, .01)
	gen double mw_smallbusiness_mincomp = round(VZ_mw_smallbusiness_mincompensat, .01)
	gen double mw_hotel           = round(VZ_mw_hotel, .01)
	gen double mw_nonprofit       = round(VZ_mw_nonprofit, .01)
	gen double mw_tipped          = round(VZ_mw_tipped, .01)
	drop VZ_mw*

	egen min_mw  = rowmin(mw-mw_tipped)
	egen mean_mw = rowmean(mw-mw_tipped)
	egen max_mw  = rowmax(mw-mw_tipped)

	merge m:1 statefips using `temp'/crosswalk.dta, nogen keep(3)
	label var statefips "State FIPS Code"
	label var statename "State"
	label var stateabb  "State Abbreviation"
	label var locality  "City/County"
	label var mw        "Minimum Wage"
	order statefips statename stateabb locality year month day date mw mw_* source source_2 source_notes

	sort locality date
	export delim using `outstub'/VZ_substate_changes.csv, replace 
end

program prepare_local
	syntax, temp(str)
	preserve
	egen tag = tag(statefips locality)
	keep if tag == 1
	keep statefips locality

	save `temp'\localities.dta, replace
	restore
end

program prepare_state
	syntax, outstub(str) temp(str) finaldate(str)
	sum year
	local minyear = r(min)
	preserve
	
	import delim `outstub'/VZ_state_daily.csv, clear 
	g date2 = date(date, "DMY")
	format date2 %td
	order date2, after(date)
	drop date 
	rename date2 date
	keep if year(date) >= `minyear' & date <= td(`finaldate')
	joinby statefips using `temp'/localities.dta
	keep statefips statename stateabb locality date mw
	rename mw state_mw
	save `temp'/statemw.dta, replace
	restore
end

program prepare_finaldata
	syntax, temp(str) finaldate(str)
	
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

	merge 1:m statefips locality date using `temp'/statemw.dta, assert(2 3) nogenerate
	replace mw = state_mw if mw == .
	replace mw = round(mw, 0.01)
	gen abovestate = mw > state_mw
	label var abovestate "Local > State min wage"

	keep statefips statename stateabb date locality mw* *_mw abovestate source_notes
	order statefips statename stateabb date locality mw* *_mw abovestate source_notes
	notes mw: The mw variable represents the most applicable minimum wage across the locality.

	save_data `temp'/data.dta, key(statefips locality date) replace log(none)
end

program export_substate_daily
	syntax, outstub(str) temp(str)	
		
	use `temp'/data.dta, clear
	sort locality date
	export delim using `outstub'\VZ_substate_daily.csv, replace
end

program export_substate_monthly
	syntax, outstub(str) temp(str)
	use `temp'/data.dta, clear

	gen monthly_date = mofd(date)
	format monthly_date %tm

	collapse (min) min_mw = min_mw (mean) mean_mw = mean_mw (max) max_mw = max_mw abovestate, ///
		by(statefips statename stateabb locality monthly_date)

	label var monthly_date "Monthly Date"
	label_mw_vars, time_level("Monthly")

	sort locality monthly_date

	export delim using `outstub'/VZ_substate_monthly.csv, replace 
end 

program export_substate_quarterly
	syntax, outstub(str) temp(str)
	use `temp'/data.dta, clear

	gen quarterly_date = qofd(date)
	format quarterly_date %tq

	collapse (min) min_mw = mw (mean) mean_mw = mw (max) max_mw = mw abovestate, /// 
		by(statefips statename stateabb locality quarterly_date)

	label var quarterly_date "Quarterly Date"
	label_mw_vars, time_level("Quarterly")

	sort locality quarterly_date

	export delim using `outstub'/VZ_substate_quarterly.csv, replace
end 

program export_substate_annually
	syntax, outstub(str) temp(str)
	use `temp'/data.dta, clear

	gen year = yofd(date)
	format year %ty

	collapse (min) min_mw = min_mw (mean) mean_mw = mean_mw (max) max_mw = max_mw abovestate, ///
		by(statefips statename stateabb locality year)

	label var year "Year"
	label_mw_vars, time_level("Annual")

	sort locality year

	export delim using `outstub'/VZ_substate_annual.csv, replace 
end

program label_mw_vars
	syntax, time_level(str)

	label var min_mw     "`time_level' Minimum"
	label var mean_mw    "`time_level' Average"
	label var max_mw     "`time_level' Maximum"
	label var abovestate "Local MW > State MW"	
end

* EXECUTE
main 
