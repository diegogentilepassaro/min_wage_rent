set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main 
    use "../../../base/qcew/output/industry_county_qtr_emp_wage.dta", clear
	
	keep if ownership == "Total Covered"
	drop ownership naics industry
	
	preserve
	keep if year_quarter == `=tq(2010q1)'
	gen avg_employment_quarter = (employment_month1 + employment_month2 + employment_month3)/3
	egen us_total_employment_quarter = sum(avg_employment_quarter) 
	egen us_avg_week_wage_num = sum(avg_employment_quarter*avg_week_wage)
	gen us_avg_week_wage = us_avg_week_wage_num/us_total_employment_quarter
	
	gen above_avg_us_weekly_wage = (avg_week_wage > us_avg_week_wage)

	egen decile_avg_week_wage = xtile(avg_week_wage), n(10)
	
	save_data "../temp/wage_rankings_2010q1.dta", key(countyfips) replace log(none)
    restore
	
	merge m:1 countyfips using "../temp/wage_rankings_2010q1.dta", ///
	    nogen assert(1 3) keep(3) ///
		keepusing(decile_avg_week_wage above_avg_us_weekly_wage)
    
	save_data "../temp/county_quarter_emp_wage.dta", key(year_quarter countyfips) ///
	    replace log(none)
end

main
