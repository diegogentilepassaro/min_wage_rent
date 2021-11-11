set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_est        "../../../drive/derived_large/estimation_samples"
	local in_cbsa_month "../../../drive/derived_large/cbsa_month"
    local outstub       "../../../drive/derived_large/stacked_sample"
    local logfile       "../output/data_file_manifest.log"

    use zipcode zipcode_num year_month year statefips cbsa10 rural ///
	    medrentpricepsqft_SFCC ln_rents ///
		actual_mw ln_mw exp_ln_mw_1* ///
		ln_emp_* ln_estcount_* ln_avgwwage_* using ///
	    "`in_est'/all_zipcode_months.dta", clear
    xtset zipcode_num year_month
    drop if missing(medrentpricepsqft_SFCC)
    drop if cbsa10 == "99999"
	gen change_mw = (actual_mw > L.actual_mw)
	save_data "../temp/all_zipcodes.dta", ///
	    key(zipcode year_month) log(none) replace

	build_stacked_data, instub(`in_cbsa_month') window_size(3)
	save_data "`outstub'/stacked_sample_window3.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace

	build_stacked_data, instub(`in_cbsa_month') window_size(6)
	save_data "`outstub'/stacked_sample_window6.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace

	build_stacked_data, instub(`in_cbsa_month') window_size(9)
	save_data "`outstub'/stacked_sample_window9.dta", ///
	    key(zipcode year_month event_id) log(`logfile') replace				
end

program build_stacked_data
    syntax, instub(str) window_size(int)
	
    use "`instub'/events.dta", clear
	drop if inrange(time_since_treated, 1, `window_size')
	qui levelsof event_id, local(events)
    foreach event of local events{
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
			keep zipcode zipcode_num year_month event_id zipcode_event_id ///
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
