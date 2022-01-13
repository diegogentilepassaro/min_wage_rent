set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_est        "../../../drive/derived_large/estimation_samples"
    local in_cbsa_month "../../../drive/derived_large/cbsa_month"
    local outstub       "../../../drive/derived_large/estimation_samples"
    local logfile       "../output/data_file_manifest.log"

    use zipcode zipcode_num year_month year statefips cbsa10 rural        ///
        medrentpricepsqft_SFCC ln_rents                                   ///
        actual_mw ln_mw exp_ln_mw_1* ln_emp_* ln_estcount_* ln_avgwwage_* ///
        using "`in_est'/all_zipcode_months.dta", clear

    xtset zipcode_num year_month
    drop if missing(medrentpricepsqft_SFCC)
    drop if cbsa10 == "99999"

    save_data "../temp/all_zipcodes.dta", ///
        key(zipcode year_month) log(none) replace

    foreach w in 3 6 9 {
        build_stacked_data, instub(`in_cbsa_month') w(`w')
        save_data "`outstub'/stacked_sample_window`w'.dta", ///
            key(zipcode year_month event_id) log(`logfile') replace
    }
end

program build_stacked_data
    syntax, instub(str) w(int)

    use "`instub'/events.dta", clear

    *drop if inrange(time_since_treated, 1, `w')
    qui levelsof event_id, local(events)

    foreach event of local events {
        quietly {
            preserve
                keep if event_id == `event'

                gen event_yy = event_year - 2000
                qui sum event_yy
                local event_yy = r(mean)

                merge 1:m cbsa10 using "../temp/all_zipcodes.dta", ///
                    nogen keep(3)
                    
                if `event_yy' < 17 {
                    rename exp_ln_mw_`event_yy' exp_ln_mw 
                }
                if `event_yy' == 17 {
                    gen exp_ln_mw = exp_ln_mw_17 
                }
                if `event_yy' >= 18 {
                    rename exp_ln_mw_18 exp_ln_mw 
                }
                
                drop event_year event_yy
                gen rel_time = year_month - event_year_month
                egen zipcode_event_id = group(zipcode event_id)
                
                xtset zipcode_event_id year_month

                foreach var of varlist ln_rents ln_mw exp_ln_mw_17 exp_ln_mw ///
                                    ln_emp_* ln_estcount_* ln_avgwwage_*  {
                    
                    gen d_`var' = D.`var'
                }
                
                foreach var of varlist d_ln_mw d_exp_ln_mw_17 d_exp_ln_mw {
                    forval i = 1(1)`w' {
                        gen L`i'_`var' = L`i'.`var'
                        gen F`i'_`var' = F`i'.`var'
                    }
                }
                
                keep if inrange(rel_time, -`w', `w')

                bysort zipcode: egen nbr_months_around_event = count(year_month)
                keep if nbr_months_around_event == 2*`w' + 1

                keep zipcode zipcode_num cbsa10 statefips event_id year_month ///
                     rural actual_mw exp_ln_mw exp_ln_mw_17 ln_* d_* L* F*
                
                save_data "../temp/sample_event_`event'.dta", ///
                    key(zipcode event_id year_month) log(none) replace
            restore
        }
    }

    clear all
    foreach event of local events{
        append using "../temp/sample_event_`event'.dta"
    }
end


main
