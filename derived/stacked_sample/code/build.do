set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_der_large "../../../drive/derived_large"
    local outstub      "../../../drive/derived_large/stacked_sample"
    local logfile      "../output/data_file_manifest.log"

    use zipcode zipcode_num year_month statefips cbsa10 rural ///
	    medrentpricepsqft_SFCC ln_rents ///
		actual_mw ln_mw exp_ln_mw_1* ///
		ln_emp_* ln_estcount_* ln_avgwwage_* using ///
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

	build_stacked_data, window_size_pre(4) window_size_post(3)
	save_data "`outstub'/stacked_sample_window3.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace

	build_stacked_data, window_size_pre(7) window_size_post(6)
	save_data "`outstub'/stacked_sample_window6.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace

	build_stacked_data, window_size_pre(10) window_size_post(9)
	save_data "`outstub'/stacked_sample_window9.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace						
end

program build_stacked_data
    syntax, window_size_pre(int) window_size_post(int)
	
    use "../temp/event_ids", clear
	qui levelsof event_id, local(events)
    foreach event of local events{
	    preserve
	        keep if event_id == `event'
			merge 1:m cbsa10 using "../temp/all_zipcodes.dta", ///
			    nogen keep(3)
			gen rel_time = year_month - event_month
			egen zipcode_event_id = group(zipcode event_id)
			xtset zipcode_event_id year_month
			foreach var of varlist ln_mw exp_ln_mw_*{
			    gen L6_`var' = L6.`var'
			    gen L5_`var' = L5.`var'
			    gen L4_`var' = L4.`var'
			    gen L3_`var' = L3.`var'
			    gen L2_`var' = L2.`var'
			    gen L1_`var' = L1.`var'
			    gen F6_`var' = F6.`var'
			    gen F5_`var' = F5.`var'
			    gen F4_`var' = L4.`var'
			    gen F3_`var' = L3.`var'
			    gen F2_`var' = L2.`var'
			    gen F1_`var' = L1.`var'
			} 
			keep if inrange(rel_time, -`window_size_pre', `window_size_post')
			bysort zipcode: egen nbr_months_around_event = count(year_month)
			keep if nbr_months_around_event == `window_size_pre' + `window_size_post' + 1
			save_data "../temp/sample_event_`event'.dta", ///
			    key(zipcode year_month event_id) log(none) replace
	    restore
	}
	
	clear all
	foreach event of local events{
	    append using "../temp/sample_event_`event'.dta"
	}
	gen year_event = year(dofm(event_month))
	
	foreach var in exp_ln_mw L6_exp_ln_mw L5_exp_ln_mw L4_exp_ln_mw ///
	    L3_exp_ln_mw L2_exp_ln_mw L1_exp_ln_mw F6_exp_ln_mw ///
		F5_exp_ln_mw F4_exp_ln_mw F3_exp_ln_mw F2_exp_ln_mw F1_exp_ln_mw {
	    
		gen `var' = cond(year_event == 2010, `var'_10, ///
	        cond(year_event == 2011, `var'_11, ///
			cond(year_event == 2012, `var'_12, ///
			cond(year_event == 2013, `var'_13, ///
			cond(year_event == 2014, `var'_14, ///
			cond(year_event == 2015, `var'_15, ///
			cond(year_event == 2016, `var'_16, ///
			cond(year_event == 2017, `var'_17, ///
			cond(year_event == 2018, `var'_18, ///
			cond(year_event == 2019, `var'_18, .))))))))))		
		}
					
	foreach var of varlist ln_rents ln_mw exp_ln_mw_17 exp_ln_mw ///
	    ln_emp_* ln_estcount_* ln_avgwwage_* {
		bysort zipcode event_id (year_month): gen d_`var' = `var'[_n]  - `var'[_n -1]
	}
	
	drop if missing(zipcode)
	drop if rel_time == -`window_size_pre'
end

main
