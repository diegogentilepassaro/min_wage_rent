set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main 
    local instub "../output"
    local outstub "../output"

    use `instub'/industry_county_qtr_emp_wage.dta, clear

    select_sectors, ownership(`" "Total Covered" "') industries("10")

    clean_vars

    create_monthly_panel

    save_data `outstub'/tot_emp_wage_countymonth.dta, ///
        key(countyfips year_month) replace

    use `instub'/industry_county_qtr_emp_wage.dta, clear

    select_sectors, ownership(`""Federal Government" "State Government" "Local Government" "Private""') ///
                    industries("1011 1012 1013 1021 1022 1023 1024 1025 1026 1019")

    clean_vars

    create_monthly_panel

    save_data `outstub'/ind_emp_wage_countymonth.dta, ///
        key(countyfips year_month) replace 

end 

program select_sectors
    syntax, ownership(str) industries(str)

    local n : word count `ownership'
    local first_owner: word 1 of `ownership'
    local owner_list `"ownership=="`first_owner'""'
    
    if `n'>1 {
        forval x = 2/`n' {
            local this_owner: word `x' of `ownership'
            local this_owner_list `" | ownership== "`this_owner'""'
            local owner_list `"`owner_list' `this_owner_list'"'    
        }        
    }
    keep if `owner_list'

    replace industry = trim(regexr(trim(industry), "^[0-9]+", ""))

    local n : word count `industries'
    local first_ind: word 1 of `industries'
    local ind_list `"naics == "`first_ind'""'
    
    if `n'>1 {
        forval x = 2/`n' {
            local this_ind: word `x' of `industries'
            local this_ind_list `" | naics == "`this_ind'""'
            local ind_list `"`ind_list' `this_ind_list'"'    
        }        
    }
    keep if (ownership != "Private") |  (ownership== "Private" & (`ind_list'))

    replace industry = ownership if ownership!= "Private"
end

program clean_vars 
    drop naics ownership county 

    rename (employment_month1 employment_month2 employment_month3 estab_count avg_week_wage) ///
           (emp_1             emp_2             emp_3             estcount_   avgwwage_)

    replace industry = "const"   if industry == "Construction"
    replace industry = "eduhe"   if industry == "Education and health services"
    replace industry = "fedgov"  if industry == "Federal Government"
    replace industry = "goodpr"  if industry == "Goods-producing"
    replace industry = "info"    if industry == "Information"
    replace industry = "leis"    if industry == "Leisure and hospitality"
    replace industry = "manu"    if industry == "Manufacturing"
    replace industry = "natres"  if industry == "Natural resources and mining"
    replace industry = "bizserv" if industry == "Professional and business services"
    replace industry = "servpr"  if industry == "Service-providing"
    replace industry = "stgov"   if industry == "State Government"
    replace industry = "transp"  if industry == "Trade, transportation, and utilities"
    replace industry = "locgov"  if industry == "Local Government"
    replace industry = "fin"     if industry == "Financial activities"
    replace industry = "tot"     if industry == "Total Covered"
end  


program  create_monthly_panel
    
    reshape long emp_, i(year_quarter countyfips statefips industry estcount avgwwage) j(qmon)

    replace qmon = qmon + 3 if quarter(dofq(year_quarter)) == 2
    replace qmon = qmon + 6 if quarter(dofq(year_quarter)) == 3
    replace qmon = qmon + 9 if quarter(dofq(year_quarter)) == 4

    g year_month = ym(year(dofq(year_quarter)), qmon)
    format year_month %tm
    drop year_quarter qmon
    order year_month, after(countyfips)

    reshape wide estcount avgwwage emp, i(countyfips statefips year_month) j(industry) string

end 


main 
