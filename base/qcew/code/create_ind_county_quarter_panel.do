set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
	local instub "../../../drive/raw_data/qcew/county"
	local outstub "../output"

	foreach year in 09 10 11 12 13 14 15 16 17 18 {
		process_hl_county_year_file, instub(`instub') year(`year')
	}
	process_hl_county_year_file, instub(`instub') year(19) quarters(3)
	
	use "../temp/09.dta", clear
	foreach year in 10 11 12 13 14 15 16 17 18 19 {
		append using "../temp/`year'.dta"
	}
    save_data "`outstub'/industry_county_qtr_emp_wage.dta", ///
		key(year_quarter countyfips naics ownership) replace
end

program process_hl_county_year_file
	syntax, instub(str) year(str) [quarters(int 4)]
	
	forval qtr = 1(1)`quarters' {
		import excel "`instub'/20`year'_all_county_high_level/allhlcn`year'`qtr'.xlsx", ///
			sheet("US_St_Cn_MSA") firstrow clear

		keep if (AreaType == "County")
		drop Cnty Own StName AreaType StatusCode TotalQuarterlyWages EmploymentLocation TotalWageLocation
		
		destring Year, replace
		destring Qtr, replace
		gen end_month = Qtr*3
		
		gen year_quarter = qofd(mdy(end_month, 1, Year))
		format year_quarter %tq
		drop Year Qtr end_month
		
		rename (AreaCode Area St NAICS Ownership Industry Establishment AverageWeekly) ///
			(countyfips county statefips naics ownership industry estab_count avg_week_wage)
		
		if "`qtr'" == "1" {
			rename (January February March) ///
				(employment_month1 employment_month2 employment_month3)
		}
		if "`qtr'" == "2" {
			rename (April May June) ///
				(employment_month1 employment_month2 employment_month3)
		}
		if "`qtr'" == "3" {
			rename (July August September) ///
				(employment_month1 employment_month2 employment_month3)
		}
		if "`qtr'" == "4" {
			rename (October November December) ///
				(employment_month1 employment_month2 employment_month3)
		}
		
		save "../temp/`year'`qtr'.dta", replace
	}
	
	use "../temp/`year'1.dta", clear
	forval qtr = 2(1)`quarters' {
		append using "../temp/`year'`qtr'.dta"
	}
	
	order year_quarter countyfips county statefips ///
		naics ownership industry estab_count
	save_data "../temp/`year'.dta", key(year_quarter countyfips naics ownership) ///
		replace log(none)
end

* EXECUTE
main
