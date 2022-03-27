set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_cty_mth    "../../../drive/derived_large/county_month"
    local in_qcew       "../../../base/qcew/output"
    local outstub       "../../../drive/derived_large/county_year"
    local logfile       "../output/data_file_manifest.log"

    use countyfips cbsa  statefips year month    ///
        statutory_mw mw_res mw_wkp* medrent* ///
        using  "`in_cty_mth'/county_month_panel.dta"

    make_yearly_data

    clean_qcew, instub(`in_qcew')

    use "../temp/mw_rents_data.dta", clear
    merge m:1 countyfips year using "../temp/qcew_data.dta", ///
	    nogen keep(1 3)

    destring_geographies

    save_data "`outstub'/county_year.dta", key(countyfips year) ///
        log(`logfile') replace
end

program make_yearly_data

    gen ln_rents = log(medrentpricepsqft_SFCC)

    rename *timevary* *timvar* 
    qui describe mw_wkp*, varlist
    local mw_wkp_vars = r(varlist)

    local vars statutory_mw mw_res ln_rents `mw_wkp_vars'

    keep year countyfips cbsa statefips month `vars'
    
    foreach var of local vars {
        bys countyfips year: egen `var'_avg = mean(`var')
    }

    bysort countyfips year (month): keep if _n == 7
    drop month
    
    save "../temp/mw_rents_data.dta", replace
end

program clean_qcew
    syntax, instub(str)
    
    use countyfips year month estcount* avgwwage* emp*            ///
       using `instub'/ind_emp_wage_countymonth.dta, clear

    foreach var of varlist estcount* avgwwage* emp* {
        gen ln_`var' = log(`var')
        drop `var'
        bys countyfips year: egen ln_`var'_avg = mean(ln_`var')
    }

	bysort countyfips year (month): keep if _n == 7
    drop month

    save "../temp/qcew_data.dta", replace
end

program destring_geographies

    destring statefips,  gen(statefips_num)
    destring cbsa,       gen(cbsa_num)
    destring countyfips, gen(county_num)
end


main
