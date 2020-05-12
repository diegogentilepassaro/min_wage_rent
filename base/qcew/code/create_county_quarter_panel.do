set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    forval year = 10(1)19 {
        process_hl_county_year_file, year(`year')
	}
	
	use "../temp/10.dta", clear
	forval year = 11(1)19 {
	    append using "../temp/`year'.dta"
	}
	save_data "../output/industry_county_qtr_emp_wage.dta", ///
	    key(year_qtr area_fips_code naics_code ownership_code) replace
end

program process_hl_county_year_file
    syntax, year(int) 
	
	forval qtr = 1(1)4 {
		import excel "../../../drive/raw_data/qcew/raw/county/20`year'_all_county_high_level/allhlcn`year'`qtr'.xlsx", ///
			sheet("US_St_Cn_MSA") firstrow clear

		keep if (AreaType != "Nation" & AreaType != "State")
		drop Cnty Own Area StatusCode TotalQuarterlyWages EmploymentLocation TotalWageLocation
		
		destring Year, replace
		destring Qtr, replace
		gen end_month = Qtr*3
		
		gen year_qtr = qofd(mdy(end_month, 1, Year))
		format year_qtr %tq
		drop Year Qtr end_month
		
		rename (AreaCode AreaType St StName NAICS Ownership Industry Establishment AverageWeekly) ///
			(area_code area_type state state_name naics ownership industry estab_count avg_week_wage)
		
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
	append using "../temp/`year'2.dta"
	append using "../temp/`year'3.dta"
	append using "../temp/`year'4.dta"
    
	encode area_code, gen(area_fips_code)
	encode naics, gen(naics_code)
	encode ownership, gen(ownership_code)
	
	order year_qtr area_code area_fips_code area_type state state_name ///
	    naics naics_code ownership ownership_code industry estab_count
	save_data "../temp/`year'.dta", key(year_qtr area_fips_code naics_code ownership_code) ///
	    replace log(none)
end

* EXECUTE
main
