set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_est        "../../../drive/derived_large/estimation_samples"
    local in_cbsa_month "../../../drive/derived_large/cbsa_month"
    local outstub       "../../../drive/derived_large/estimation_samples"
    local logfile       "../output/data_file_manifest.log"

    load_zipcode_data, instub(`in_est')

    save_data "../temp/all_zipcodes.dta", ///
        key(zipcode year_month) log(none) replace

    foreach w in 3 6 9 {
        build_stacked_data, instub(`in_cbsa_month') w(`w')
        save_data "`outstub'/stacked_sample_window`w'.dta", ///
            key(zipcode event_id year_month) log(`logfile') replace
    }
end

program load_zipcode_data
    syntax, instub(str)

    use zipcode zipcode_num year_month year statefips cbsa         ///
        medrentpricepsqft_SFCC ln_rents statutory_mw               ///
        mw_res mw_wkp_tot_* ln_emp_* ln_estcount_* ln_avgwwage_*   ///
        using "`instub'/zipcode_months.dta", clear

    drop if missing(medrentpricepsqft_SFCC)
    drop if cbsa == "99999"

    xtset zipcode_num year_month
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

                merge 1:m cbsa using "../temp/all_zipcodes.dta", ///
                    nogen keep(3)

                if `event_yy' < 17 {
                    rename mw_wkp_tot_`event_yy' mw_wkp_tot_baseyear 
                }
                if `event_yy' == 17 {
                    gen mw_wkp_tot_baseyear = mw_wkp_tot_17 
                }
                if `event_yy' >= 18 {
                    rename mw_wkp_tot_18 mw_wkp_tot_baseyear 
                }

                drop event_year event_yy
                gen rel_time = year_month - event_year_month
                egen zipcode_event_id = group(zipcode event_id)
                
                xtset zipcode_event_id year_month

                foreach var of varlist ln_rents mw_res mw_wkp_tot_17 mw_wkp_tot_baseyear ///
                                       ln_emp_* ln_estcount_* ln_avgwwage_*  {
                    
                    gen d_`var' = D.`var'
                }
                
                foreach var of varlist d_mw_res d_mw_wkp_tot_17 d_mw_wkp_tot_baseyear {
                    forval i = 1(1)`w' {
                        gen L`i'_`var' = L`i'.`var'
                        gen F`i'_`var' = F`i'.`var'
                    }
                }
                
                keep if inrange(rel_time, -`w', `w')

                bysort zipcode: egen nbr_months_around_event = count(year_month)
                keep if nbr_months_around_event == 2*`w' + 1

                keep zipcode zipcode_num zipcode_event_id year_month  ///
                     cbsa statefips event_id statutory_mw             ///
                     mw_res mw_wkp_tot_baseyear mw_wkp_tot_17 ln_* d_* L* F*
                
                save_data "../temp/sample_event_`event'.dta", ///
                    key(zipcode event_id year_month) log(none) replace
            restore
        }
    }

    clear
    foreach event of local events{
        append using "../temp/sample_event_`event'.dta"
    }
end


main
