set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_der_large "../../../drive/derived_large"
    local outstub      "../../../drive/derived_large/stacked_sample"
    local logfile      "../output/data_file_manifest.log"
	
	local window_size_pre = 7
	local window_size_post = 6

    use zipcode zipcode_num year_month statefips cbsa10 rural ///
	    medrentpricepsqft_SFCC ln_rents ///
		actual_mw ln_mw exp_ln_mw_1* using ///
	    "`in_der_large'/estimation_samples/all_zipcode_months.dta", clear
    xtset zipcode_num year_month

    drop if missing(medrentpricepsqft_SFCC)
    drop if cbsa10 == "99999"
	gen change_mw = (actual_mw > L.actual_mw)
	save_data "../temp/all_zipcodes.dta", ///
	    key(zipcode year_month) log(none) replace
	
	preserve
	    collapse (max) change_within_cbsa = change_mw, by(cbsa10 year_month)
		keep if change_within_cbsa == 1
		gen event_month = year_month
	    bysort cbsa10 (year_month): gen nbr_cum_changes = sum(change_within_cbsa)
		egen event_id = group(nbr_cum_changes cbsa10)
		keep cbsa10 event_id event_month
		save_data "../temp/event_ids", ///
		    key(cbsa10 event_month) log(none) replace
	restore

    use "../temp/event_ids", clear
	qui levelsof event_id, local(events)
	
	foreach event of local events{
	    preserve
	        keep if event_id == `event'
			merge 1:m cbsa10 using "../temp/all_zipcodes.dta", ///
			    nogen keep(3)
			gen rel_time = year_month - event_month
			keep if inrange(rel_time, -`window_size_pre', `window_size_post')
			bysort zipcode: egen nbr_months_around_event = count(year_month)
			keep if nbr_months_around_event == `window_size_pre' + `window_size_post' + 1
			save_data "../temp/sample_event_`event'.dta", ///
			    key(zipcode year_month event_id) log(none) replace
	    restore
	}
	
	foreach event of local events{
	    append using "../temp/sample_event_`event'.dta"
	}
	foreach var in ln_rents ln_mw exp_ln_mw_17 {
		bysort zipcode event_id (year_month): gen d_`var' = `var'[_n]  - `var'[_n -1]
	} 
	drop if missing(zipcode)
	drop if rel_time == -`window_size_pre'
	save_data "`outstub'/stacked_sample.dta", ///
			    key(zipcode year_month event_id) log(`logfile') replace
end


main
