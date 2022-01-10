set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub  "../../../drive/derived_large"
    local outstub "../../../drive/derived_large/cbsa_month"
    local logfile "../output/data_file_manifest.log"

    load_data, instub(`instub')

    collapse (count) nbr_zipcodes             = zipcode_num   ///
             (sum)   nbr_zipcodes_with_change = mw_change     ///
             (max)   change_within_cbsa       = mw_change     ///
                     max_actual_mw            = actual_mw     ///
                     max_d_ln_mw              = d_ln_mw       ///
                     max_d_exp_ln_mw_17       = exp_ln_mw_17  ///
             (mean)  avg_actual_mw            = actual_mw     ///
                     avg_d_ln_mw              = d_ln_mw       ///
                     avg_d_exp_ln_mw_17       = exp_ln_mw_17, ///
            by(cbsa10 year year_month)

    gen all_zip_changed = (nbr_zipcodes == nbr_zipcodes_with_change)
    
    save_data "`outstub'/cbsa_month.dta", ///
        key(cbsa10 year_month) log(`logfile') replace		

    make_cbsa_event_data

    save_data "`outstub'/events.dta", ///
        key(cbsa10 event_year_month) log(`logfile') replace
end

program load_data
    syntax, instub(str)

    clear
    use zipcode zipcode_num year_month year statefips cbsa10 rural       ///
          medrentpricepsqft_SFCC ln_rents actual_mw ln_mw exp_ln_mw_1*   ///
          ln_emp_* ln_estcount_* ln_avgwwage_*                           ///
        if cbsa10 != "99999"                                             ///
        using  "`instub'/estimation_samples/all_zipcode_months.dta"

    xtset zipcode_num year_month

    gen d_ln_mw        = D.ln_mw
    gen d_exp_ln_mw_17 = D.exp_ln_mw_17

    gen mw_change = (actual_mw > L.actual_mw)
    
    drop if missing(medrentpricepsqft_SFCC)
end

program make_cbsa_event_data

    keep if change_within_cbsa == 1

    rename year_month event_year_month
    rename year       event_year

    format event_year_month %tm

    bys cbsa10 (event_year_month): gen mw_change_id = sum(change_within_cbsa)
    egen event_id = group(mw_change_id cbsa10)

    bys cbsa10 (event_year_month): ///
        gen time_since_treated = event_year_month[_n] - event_year_month[_n - 1]

    keep cbsa10 event_id event_year event_year_month all_zip_changed time_since_treated
end


main
