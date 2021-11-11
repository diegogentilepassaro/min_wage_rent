set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_der_large "../../../drive/derived_large"
    local outstub      "../../../drive/derived_large/stacked_sample_experimental"
    local logfile      "../output/data_file_manifest.log"

    use zipcode zipcode_num year_month year statefips cbsa10 rural ///
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
	    keep cbsa10 statefips
		duplicates drop cbsa10 statefips, force
		rename cbsa10 cbsa10_treated
		save "../temp/cbsa_state_combinations.dta", replace
	restore
	
	preserve
	    collapse (max) change_within_cbsa = change_mw, by(cbsa10 year year_month)
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
		save_data "../temp/event_ids", ///
		    key(cbsa10 event_year_month) log(none) replace
	restore

	build_stacked_data, window_size(3)
	save_data "`outstub'/stacked_sample_window3.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace

	build_stacked_data, window_size(6)
	save_data "`outstub'/stacked_sample_window6.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace		
	
	build_stacked_data, window_size(9)
	save_data "`outstub'/stacked_sample_window9.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace
end

program build_stacked_data
    syntax, window_size(int)
	
    use "../temp/event_ids", clear
	drop if inrange(time_since_treated, 1, `window_size')
	qui levelsof event_id, local(events)
    foreach event of local events {
	    preserve
	        keep if event_id == `event'
			rename cbsa10 cbsa10_treated
			save "../temp/event.dta", replace
			merge 1:m cbsa10_treated using "../temp/cbsa_state_combinations.dta", ///
			    nogen keep(3)
			keep statefips
			merge 1:m statefips using "../temp/all_zipcodes.dta", ///
			    nogen keep(3)
			gen event_id = `event'
			merge m:1 event_id using "../temp/event.dta", ///
			    nogen keep(3)
				
			gen event_yy = event_year - 2000
			qui sum event_yy
			local event_yy = r(mean)
			
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
	        
			foreach var of varlist ln_rents ln_mw exp_ln_mw_17 exp_ln_mw ///
	            ln_emp_* ln_estcount_* ln_avgwwage_* {
		        
				bysort zipcode event_id (year_month): ///
				    gen d_`var' = `var'[_n]  - `var'[_n -1]
	        }
			
			xtset zipcode_event_id year_month
			foreach var of varlist d_ln_mw d_exp_ln_mw_17 d_exp_ln_mw {
			    forval i = 1(1)`window_size' {
			        gen L`i'_`var' = L`i'.`var'
			        gen F`i'_`var' = F`i'.`var'
				}
			}
			
			keep if inrange(rel_time, -`window_size', `window_size')
			bysort zipcode: egen nbr_months_around_event = count(year_month)
			keep if nbr_months_around_event == 2*`window_size' + 1
			keep zipcode zipcode_num year_month ///
			    event_id zipcode_event_id cbsa10_treated ///
			    cbsa10 statefips rural  actual_mw ///
			    exp_ln_mw exp_ln_mw_17 ln_* d_* L* F*
			save_data "../temp/sample_event_`event'.dta", ///
			    key(zipcode year_month event_id) log(none) replace
	    restore
	}
	
	clear all
	foreach event of local events{
	    append using "../temp/sample_event_`event'.dta"
	}
	drop if missing(zipcode)
end

main
