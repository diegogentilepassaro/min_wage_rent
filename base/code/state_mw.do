set more off
clear all

*SETTING GLOBAL DIRECTORIES
cap mkdir "../output/min_wage/"
global raw "../../raw_data/min_wage/"
global exports "../output/min_wage/"
global temp "../temp/"



program main 	
	import_crosswalk
	local fips = r(fips)
	fed_min_wage_change "VZ_FederalMinimumWage_Changes"
	add_state_to_fedmw "`fips'"
	state_min_wage_change "VZ_StateMinimumWage_Changes"
	
	prepare_finaldata 01may1974 01jul2016
	
	export_state_daily
	export_state_monthly	
	export_state_quarterly
	export_state_annually
end

program import_crosswalk, rclass
	import excel using ${raw}FIPS_crosswalk.xlsx, clear firstrow
	rename Name statename
	rename FIPSStateNumericCode statefips
	rename OfficialUSPSCode stateabb
	replace stateabb = upper(stateabb)
	keep statename statefips stateabb
	label var stateabb "State Abbreviation"

	save ${temp}crosswalk.dta, replace

	levelsof statefips, local(fips)
	return local fips "`fips'"
end

program fed_min_wage_change
	args fedfile
	import excel using ${raw}`fedfile'.xlsx, clear firstrow
	rename Fed_mw fed_mw
	keep year month day fed_mw source

	gen date = mdy(month,day,year)
	format date %td

	rename fed_mw old_fed_mw
	gen double fed_mw = round(old_fed_mw, .01)
	drop old_fed_mw
	label var fed_mw "Federal Minimum Wage"
	order year month day date fed_mw source

	sort date
	export delim using ${exports}VZ_federal_changes.csv, replace
end

program add_state_to_fedmw
	args fips 
	
	tsset date
	tsfill

	carryforward year month day fed_mw, replace

	keep date fed_mw

	tempfile temp
	save `temp'
	di "`fips'"
	
	foreach i in `fips' {
		use `temp', clear
		gen statefips = `i'
		tempfile state`i'
		save `state`i''
	}
	foreach i in `fips' {
		if `i' == 1 use `state`i'', clear
		else quietly append using `state`i''
	}

	compress
	save ${temp}fedmw.dta, replace

end

program state_min_wage_change 
	args states
	import excel using ${raw}`states'.xlsx, clear firstrow

	gen date = mdy(month,day,year)
	format date %td

	gen double mw = round(VZ_mw, .01)
	gen double mw_healthinsurance = round(VZ_mw_healthinsurance, .01)
	gen double mw_smallbusiness = round(VZ_mw_smallbusiness, .01)
	drop VZ_mw*

	merge m:1 statefips using ${temp}crosswalk.dta, nogen assert(3)

	order statefips statename stateabb year month day date mw* source source_2 source_notes
	label var statefips "State FIPS Code"
	label var statename "State"

	sort stateabb date
	
	export delim using ${exports}VZ_state_changes.csv, replace 

	tsset statefips date
	tsfill

	keep statefips date mw* source_notes

	foreach x of varlist source_notes {
	  bysort statefips (date): replace `x' = `x'[_n-1] if `x' == ""
	}
	foreach x of varlist mw* {
	  bysort statefips (date): replace `x' = `x'[_n-1] if `x' == .
	}

end 

program prepare_finaldata	
	args begindate finaldate

	merge 1:1 statefips date using ${temp}fedmw.dta, nogenerate
	merge m:1 statefips using ${temp}crosswalk.dta, nogen assert(3)

	gen mw_adj = mw
	replace mw_adj = fed_mw if fed_mw >= mw & fed_mw ~= .
	replace mw_adj = fed_mw if mw == . & fed_mw ~= .
	drop mw
	rename mw_adj mw

	keep if date >= td(`begindate') & date <= td(`finaldate')

	order statefips statename stateabb date fed_mw mw
	label var mw "State Minimum Wage"
	notes mw: The mw variable represents the higher rate between the state and federal minimum wage

	save ${temp}data.dta, replace
end


program export_state_daily
	use ${temp}data.dta, clear

	sort stateabb date

	export delim using ${exports}VZ_state_daily.csv, replace 

end

program export_state_monthly
	use ${temp}data.dta, clear

	gen monthly_date = mofd(date)
	format monthly_date %tm

	collapse (min) min_fed_mw = fed_mw min_mw = mw (mean) mean_fed_mw = fed_mw mean_mw = mw (max) max_fed_mw = fed_mw max_mw = mw, by(statefips statename stateabb monthly_date)

	label var monthly_date "Monthly Date"
	label var min_fed_mw "Monthly Federal Minimum"
	label var min_mw "Monthly State Minimum"

	label var mean_fed_mw "Monthly Federal Average"
	label var mean_mw "Monthly State Average"

	label var max_fed_mw "Monthly Federal Maximum"
	label var max_mw "Monthly State Maximum"

	sort stateabb monthly_date

	export delim using ${exports}VZ_state_monthly.csv, replace
end

program export_state_quarterly
	use ${temp}data.dta, clear

	gen quarterly_date = qofd(date)
	format quarterly_date %tq


	collapse (min) min_fed_mw = fed_mw min_mw = mw (mean) mean_fed_mw = fed_mw mean_mw = mw (max) max_fed_mw = fed_mw max_mw = mw, by(statefips statename stateabb quarterly_date)

	label var quarterly_date "Quarterly Date"
	label var min_fed_mw "Quarterly Federal Minimum"
	label var min_mw "Quarterly State Minimum"

	label var mean_fed_mw "Quarterly Federal Average"
	label var mean_mw "Quarterly State Average"

	label var max_fed_mw "Quarterly Federal Maximum"
	label var max_mw "Quarterly State Maximum"

	sort stateabb quarterly_date

	export delim using ${exports}VZ_state_quarterly.csv, replace 
end

program export_state_annually
	use ${temp}data.dta, clear

	gen year = yofd(date)
	format year %ty

	collapse (min) min_fed_mw = fed_mw min_mw = mw (mean) mean_fed_mw = fed_mw mean_mw = mw (max) max_fed_mw = fed_mw max_mw = mw, by(statefips statename stateabb year)

	label var year "Year"
	label var min_fed_mw "Annual Federal Minimum"
	label var min_mw "Annual State Minimum"

	label var mean_fed_mw "Annual Federal Average"
	label var mean_mw "Annual State Average"

	label var max_fed_mw "Annual Federal Maximum"
	label var max_mw "Annual State Maximum"

	sort stateabb year

	export delim using ${exports}VZ_state_annual.csv, replace 
end







main 
