set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local raw     "../../../drive/raw_data/min_wage"
    local xwalk   "../../../raw/crosswalk"
    local outstub "../output"
    local temp    "../temp"

    import_statenames, instub(`xwalk') outstub(`temp')
    local fips = r(fips)

    fed_min_wage_change,   instub(`raw') outstub(`temp') 
    add_state_to_fedmw,    fips(`fips')  outstub(`temp')
    state_min_wage_change, instub(`raw') outstub(`temp') temp(`temp')

    prepare_finaldata, begindate(01may1974) finaldate(31dec2019)           ///
                       outstub(`temp') temp(`temp')

    local mw_list "fed_mw mw"
    export_state_daily,     instub(`temp') outstub(`outstub') target_mw(`mw_list')
    export_state_monthly,   instub(`temp') outstub(`outstub') target_mw(`mw_list')
    export_state_quarterly, instub(`temp') outstub(`outstub') target_mw(`mw_list')
    export_state_annually,  instub(`temp') outstub(`outstub') target_mw(`mw_list')
end

program import_statenames, rclass
    syntax, instub(str) outstub(str)

    import excel using `instub'/state_name_fips_usps.xlsx, clear ///
        firstrow

    rename (Name       FIPSStateNumericCode  OfficialUSPSCode)           ///
           (statename  statefips             stateabb)
    drop sname

    label var stateabb "State"

    save_data `outstub'/crosswalk.dta, replace key(statefips) log(none)

    levelsof statefips, local(fips)
    return local fips "`fips'"
end

program fed_min_wage_change
    syntax, instub(str) outstub(str)

    import excel using `instub'/VZ_FederalMinimumWage_Changes.xlsx, clear firstrow
    rename Fed_mw fed_mw
    keep year month day fed_mw source

    gen date = mdy(month, day, year)
    format date %td

    replace fed_mw = round(fed_mw, .01)
    label var fed_mw "Federal Minimum Wage"

    order year month day date fed_mw source

    export delim using `outstub'/VZ_federal_changes.csv, replace
end

program add_state_to_fedmw
    syntax, fips(str) outstub(str)
    
    tsset date
    tsfill

    carryforward year month day fed_mw, replace

    keep date fed_mw

    tempfile temp
    save `temp'
    
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

    save_data `outstub'/fedmw.dta, replace key(date statefips) log(none)
end

program state_min_wage_change
    syntax, instub(str) outstub(str) temp(str)

    import excel using `instub'/VZ_StateMinimumWage_Changes.xlsx, clear firstrow

    gen date = mdy(month,day,year)
    format date %td

    gen double mw = round(VZ_mw, .01)
    gen double mw_healthinsurance = round(VZ_mw_healthinsurance, .01)
    gen double mw_smallbusiness   = round(VZ_mw_smallbusiness, .01)
    drop VZ_mw*

    merge m:1 statefips using `temp'/crosswalk.dta, nogen assert(3)

    order statefips statename stateabb year month day date mw* source source_2 source_notes
    label var statefips "State FIPS Code"
    label var statename "State"

    sort stateabb date
    
    export delim using `outstub'/VZ_state_changes.csv, replace 

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
    syntax, begindate(str) finaldate(str) outstub(str) temp(str)

    merge 1:1 statefips date using `temp'/fedmw.dta, nogen
    merge m:1 statefips using `temp'/crosswalk.dta, nogen assert(3)

    gen mw_adj = mw
    replace mw_adj = fed_mw if fed_mw >= mw & fed_mw ~= .
    replace mw_adj = fed_mw if mw == . & fed_mw ~= .
    drop mw
    rename mw_adj mw

    keep if date >= td(`begindate') & date <= td(`finaldate')

    order statefips statename stateabb date fed_mw mw
    label var mw "State Minimum Wage"
    notes mw: The mw variable represents the higher rate between the state and federal minimum wage

    save_data `outstub'/data_state.dta, replace key(statefips date) log(none)
end

program export_state_daily
    syntax, instub(str) outstub(str) target_mw(str)

    use `instub'/data_state.dta, clear

    keep statefips statename stateabb date `target_mw'

    save_data `outstub'/state_daily.csv, key(statefips date) ///
        outsheet replace
end

program export_state_monthly
    syntax, instub(str) outstub(str) target_mw(str)

    use `instub'/data_state.dta, clear

    keep statefips statename stateabb date `target_mw'

    gen monthly_date = mofd(date)
    format monthly_date %tm

    collapse (max) `target_mw', by(statefips statename stateabb monthly_date)

    label var monthly_date "Monthly Date"
    label_mw_vars, time_level("Monthly")

    save_data using `outstub'/state_monthly.csv, key(statefips monthly_date) ///
        outsheet replace
end

program export_state_quarterly
    syntax, instub(str) outstub(str) target_mw(str)

    use `instub'/data_state.dta, clear

    keep statefips statename stateabb date `target_mw'

    gen quarterly_date = qofd(date)
    format quarterly_date %tq

    collapse (max) `target_mw', by(statefips statename stateabb quarterly_date)

    label var quarterly_date "Quarterly Date"
    label_mw_vars, time_level("Quarterly")

    save_data `outstub'/state_quarterly.csv, key(statefips quarterly_date) ///
        outsheet replace
end

program export_state_annually
    syntax, instub(str) outstub(str) target_mw(str)

    use `instub'/datdata_statea.dta, clear

    keep statefips statename stateabb date `target_mw'

    gen year = yofd(date)
    format year %ty

    collapse (max) `target_mw', by(statefips statename stateabb year)

    label var year "Year"
    label_mw_vars, time_level("Annual")

    save_data `outstub'/state_annual.csv, key(statefips year) ///
        outsheet replace
end

program label_mw_vars
    syntax, time_level(str)

	cap label var fed_mw  "`time_level' Federal MW"
	cap label var mw      "`time_level' State MW"	
	cap label var mw_healthinsurance "`time_level' State MW Health and Insurance"
	cap label var mw_smallbusiness   "`time_level' State MW Small Business"
end

*EXECUTE
main 
