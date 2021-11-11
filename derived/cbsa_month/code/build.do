set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_der_large "../../../drive/derived_large"
    local outstub      "../../../drive/derived_large/cbsa_month"
    local logfile      "../output/data_file_manifest.log"

    use zipcode zipcode_num year_month year statefips cbsa10 rural ///
	    medrentpricepsqft_SFCC ln_rents ///
		actual_mw ln_mw exp_ln_mw_1* ///
		ln_emp_* ln_estcount_* ln_avgwwage_* using ///
	    "`in_der_large'/estimation_samples/all_zipcode_months.dta", clear
    xtset zipcode_num year_month
    gen d_ln_mw = D.ln_mw
    gen d_exp_ln_mw_17 = D.exp_ln_mw_17
	
    drop if missing(medrentpricepsqft_SFCC)
    drop if cbsa10 == "99999"
	gen change_mw = (actual_mw > L.actual_mw)
	collapse (count) nbr_zipcodes = zipcode_num ///
	    (sum) nbr_zipcodes_with_change = change_mw ///
	    (max) change_within_cbsa = change_mw ///
		max_actual_mw = actual_mw ///
		max_d_ln_mw = d_ln_mw ///
		max_d_exp_ln_mw_17 = exp_ln_mw_17 ///
		(mean) avg_actual_mw = actual_mw ///
		avg_d_ln_mw = d_ln_mw ///
		avg_d_exp_ln_mw_17 = exp_ln_mw_17, by(cbsa10 year year_month)
	save_data "`outstub'/cbsa_month.dta", ///
		key(cbsa10 year_month) log(`logfile') replace		

	keep if change_within_cbsa == 1
	gen event_year_month = year_month
	format event_year_month %tm
	gen event_year = year
	bysort cbsa10 (year_month): gen nbr_cum_changes = sum(change_within_cbsa)
	bysort cbsa10 (event_year_month): ///
		gen time_since_treated = event_year_month[_n] - event_year_month[_n - 1]
	egen event_id = group(nbr_cum_changes cbsa10)
	keep cbsa10 event_id event_year event_year_month ///
		change_within_cbsa time_since_treated
	save_data "`outstub'/events.dta", ///
		key(cbsa10 event_year_month) log(`logfile') replace
end

main
