set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main 
	local raw     "../../../drive/raw_data/min_wage"
    local xwalk   "../../../raw/crosswalk"
	local outstub "../output"
	local temp    "../temp"

	import_crosswalk, instub(`xwalk') outstub(`temp')

	substate_min_wage_change, instub(`raw') outstub(`temp') temp(`temp')
	prepare_local, temp(`temp')
	prepare_state, outstub(`outstub') temp(`temp') finaldate(31Dec2019)
	
	local mw_list = "mw mw_smallbusiness"
	prepare_finaldata, temp(`temp') finaldate(31Dec2019) target_mw(`mw_list')

	export_substate_daily,     outstub(`outstub') temp(`temp') 
	export_substate_monthly,   outstub(`outstub') temp(`temp') target_mw(`mw_list')
	export_substate_quarterly, outstub(`outstub') temp(`temp') target_mw(`mw_list')
	export_substate_yearly,    outstub(`outstub') temp(`temp') target_mw(`mw_list')
end

program import_crosswalk
	syntax, instub(str) outstub(str)
	import excel using `instub'/state_name_fips_usps.xlsx, clear firstrow 
	
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
	label var stateabb "State Abbreviation"
	label var locality "City/County"
	label var mw "Minimum Wage"
	order statefips statename stateabb locality year month day date mw ///
		mw_* source source_2 source_notes

	export delim using `outstub'/VZ_substate_changes.csv, replace 
end

program prepare_local
	syntax, temp(str)
	preserve
		egen tag = tag(statefips locality)
		keep if tag == 1
		keep statefips locality

		save `temp'/localities.dta, replace
	restore
end

program prepare_state
	syntax, outstub(str) temp(str) finaldate(str)

	sum year
	local minyear = r(min)

	preserve	
		import delim `outstub'/state_daily.csv, clear 

		gen date2 = date(date, "DMY")
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
	syntax, temp(str) finaldate(str) target_mw(str)
	
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
	replace mw = round(mw,0.01)
	gen abovestate_mw = mw > state_mw
	label var abovestate_mw "Local `var' > State min wage"

	local mw "mw"
	local new_target_mw: list target_mw - mw 
	
	foreach var in `new_target_mw' {
		replace `var' = mw if `var' == .
		replace `var' = round(`var', 0.01)
		gen abovestate_`var' = `var' > state_mw
		label var abovestate_`var' "Local `var' > State min wage"		
	}

	keep statefips statename stateabb date locality mw mw_* abovestate_*  source_notes
	order statefips statename stateabb date locality mw mw_* abovestate_*   source_notes
	notes mw: The mw variable represents the most applicable minimum wage across the locality.

	save_data `temp'/data_substate.dta, key(statefips locality date) replace log(none)
end

program export_substate_daily
	syntax, outstub(str) temp(str) 
		
	use `temp'/data_substate.dta, clear
	save_data `outstub'/substate_daily.csv, key(locality date) ///
        outsheet replace
end

program export_substate_monthly
	syntax, outstub(str) temp(str) target_mw(str)
	use `temp'/data_substate.dta, clear

	gen monthly_date = mofd(date)
	format monthly_date %tm

	collapse (max) `target_mw' abovestate_*, by(statefips statename stateabb locality monthly_date)

	label var monthly_date "Monthly Date"
	label_mw_vars, time_level("Monthly")

	save_data `outstub'/substate_monthly.csv, key(locality monthly_date) ///
        outsheet replace
end 

program export_substate_quarterly
	syntax, outstub(str) temp(str) target_mw(str)
	use `temp'/data_substate.dta, clear

	gen quarterly_date = qofd(date)
	format quarterly_date %tq

	collapse (max) `target_mw' abovestate_*, by(statefips statename stateabb locality quarterly_date)

	label var quarterly_date "Quarterly Date"
	label_mw_vars, time_level("Quarterly")

	save_data `outstub'/substate_quarterly.csv, key(locality quarterly_date) ///
        outsheet replace
end 

program export_substate_yearly
	syntax, outstub(str) temp(str) target_mw(str)
	use `temp'/data_substate.dta, clear

	gen year = yofd(date)
	format year %ty

	collapse (max) `target_mw' abovestate_*, by(statefips statename stateabb locality year)

	label var year "Year"
	label_mw_vars, time_level("Annual")

	save_data `outstub'/substate_annual.csv, key(locality year) ///
        outsheet replace
end

program label_mw_vars
	syntax, time_level(str)

	cap label var mw     "`time_level' MW"	
	cap label var abovestate_mw "Local > State min wage"	
	cap label var mw_healthinsurance "`time_level' State MW Health and Insurance"
	cap label var mw_smallbusiness   "`time_level' State MW Small Business"
end

* EXECUTE
main 
