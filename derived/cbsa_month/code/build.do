set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub  "../../../drive/derived_large/estimation_samples"
    local outstub "../../../drive/derived_large/cbsa_month"
    local logfile "../output/data_file_manifest.log"

    load_data, instub(`instub')

    collapse (count) n_zipcodes             = zipcode_num     ///
             (sum)   n_zipcodes_with_change = mw_change       ///
             (max)   change_within_cbsa     = mw_change       ///
                     max_statutory_mw       = statutory_mw    ///
                     max_d_mw_res           = d_mw_res        ///
                     max_d_mw_wkp_tot_17    = mw_wkp_tot_17   ///
             (mean)  avg_statutory_mw       = statutory_mw    ///
                     avg_d_mw_res           = d_mw_res        ///
                     avg_d_mw_wkp_tot_17    = mw_wkp_tot_17,  ///
            by(cbsa year year_month)

    gen all_zip_changed = (n_zipcodes == n_zipcodes_with_change)
    
    save_data "`outstub'/cbsa_month.dta", ///
        key(cbsa year_month) log(`logfile') replace		

    make_cbsa_event_data

    save_data "`outstub'/events.dta", ///
        key(cbsa event_year_month) log(`logfile') replace
end

program load_data
    syntax, instub(str)

    clear
    use zipcode zipcode_num year_month year statefips cbsa                   ///
          medrentpricepsqft_SFCC ln_rents mw_res mw_wkp_tot_17 statutory_mw  ///
        if cbsa != "99999"                                                   ///
        using  "`instub'/zipcode_months.dta"

    xtset zipcode_num year_month

    gen d_mw_res        = D.mw_res
    gen d_mw_wkp_tot_17 = D.mw_wkp_tot_17

    gen mw_change = (statutory_mw > L.statutory_mw)
    
    drop if missing(medrentpricepsqft_SFCC)
end

program make_cbsa_event_data

    keep if change_within_cbsa == 1

    rename year_month event_year_month
    rename year       event_year

    format event_year_month %tm

    bys cbsa (event_year_month): gen mw_change_id = sum(change_within_cbsa)
    egen event_id = group(mw_change_id cbsa)

    bys cbsa (event_year_month): ///
        gen time_since_treated = event_year_month[_n] - event_year_month[_n - 1]

    keep cbsa event_id event_year event_year_month all_zip_changed time_since_treated
end


main
