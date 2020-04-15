clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../../drive/derived_large/output"
	local outstub "../temp/"

	use `instub'/zipcode_yearmonth_panel.dta, clear

	
	prepare_data, time_var(year_month) geo_unit(zipcode) outstub(`outstub')

	foreach window in 11 {
		create_latest_event_vars, event_dummy(mw_event) window(`window')                ///
			time_var(year_month) geo_unit(zipcode)
			
        create_event_vars_preclean, event_dummy(mw_event) window(`window')                       ///
			time_var(year_month) geo_unit(zipcode)  
	}
	

	save_data `outstub'zipcode_year_month_panel.dta, key(zipcode year_month)            ///
	    replace log(none)
end

program prepare_data 
    syntax, time_var(str) geo_unit(str) outstub(str) 

    gen date = dofm(year_month)
	gen calendar_month = month(date)
	drop date

	local var_bal = "medrentprice_sfcc medrentprice_cc medrentprice_1br medrentprice_2br medrentprice_3br medrentprice_4br medrentprice_5br medrentprice_mfdxtx medrentprice_mfr5plus medrentprice_sf medrentprice_studio medrentpricepsqft_sfcc medrentpricepsqft_cc medrentpricepsqft_1br medrentpricepsqft_2br medrentpricepsqft_3br medrentpricepsqft_4br medrentpricepsqft_5br medrentpricepsqft_mfdxtx medrentpricepsqft_mfr5plus medrentpricepsqft_sf medrentpricepsqft_studio"

	
	local bal_start_date = "2013m1"
	local bal_end_date   = "2018m12"


	balance_panel_fullfromstart, start_date(`bal_start_date') end_date(`bal_end_date') ///
		geo_unit("zipcode") var_balance(`var_bal') outstub(`outstub')

	
	local len_s = 20
	balance_panel_lenseries, start_date(`bal_start_date') end_date(`bal_end_date') ///
		geo_unit("zipcode") len_series(`len_s') ///
		var_balance(`var_bal') outstub(`outstub')

	keep if year_month >= tm(`bal_start_date') & year_month<tm(`bal_end_date')


	replace mw_event = 0 if dactual_mw < 0.5


	drop if missing(msa)
	
	keep zipcode year_month state msa calendar_month ///
	    medrentprice* zri* zhvi* medlistingprice* ///
		mw_event mw_event_smallbusiness fb* len`len_s'* 
end



program balance_panel_lenseries
	syntax, start_date(str) end_date(str) geo_unit(str) len_series(int) var_balance(str) outstub(str)


	foreach var in `var_balance' {
		preserve
		// g byte fb_`var' = (year_month >= tm(`start_date') & year_month<tm(2020m1)) 
		qui keep if year_month >= tm(`start_date') & year_month<tm(`end_date')
		
		bys `geo_unit' (year_month): g delta_time = D.year_month if !missing(`var')
		bys `geo_unit' (year_month): replace delta_time = 1 if !missing(`var') & _n==1
		bys `geo_unit' (year_month): egen len_series = sum(delta_time) if !missing(`var')
		g len`len_series'_`var' = (len_series>`len_series' & !missing(`var')) 
		
		cap noisily keep if len`len_series'_`var'==1

		if _rc==0 {
			unique `geo_unit'
			unique year_month
			keep `geo_unit' year_month len`len_series'_`var'
			save "`outstub'len`len_series'_`var'.dta", replace
			restore
		}
		else {
			restore
		}
		cap merge 1:1 `geo_unit' year_month using `outstub'len`len_series'_`var'.dta, nogen keep(match master)	
		cap replace len`len_series'_`var' = 0 if missing(len`len_series'_`var')	
	}

	preserve 
	keep zipcode year_month `var_balance'
	save "`outstub'pctAll.dta", replace
	restore
end

program balance_panel_fullfromstart
	syntax, start_date(str) end_date(str) geo_unit(str) var_balance(str) outstub(str)

	foreach var in  `var_balance'  {
		preserve
		// g byte fb_`var' = (year_month >= tm(`start_date') & year_month<tm(2020m1)) 
		qui keep if year_month >= tm(`start_date') & year_month<tm(`end_date')
		
		qui keep if !missing(`var')

		
		qui g start_panel_date = tm(`start_date')
		bys `geo_unit' (year_month): egen first_month = min(year_month)
		qui keep if first_month==start_panel_date
		// qui replace fb_`var' = 0 if first_month!=start_panel_date
		

		bys `geo_unit' (year_month): g delta_time = D.year_month
		bys `geo_unit' (year_month): replace delta_time = 1 if _n==1
		bys `geo_unit' (year_month): g missing_periods = D.delta_time
		bys `geo_unit' (year_month): replace missing_periods = 0 if _n==1
		bys `geo_unit' (year_month): g balanced_panel = sum(missing_periods)


		cap noisily keep if balanced_panel==0

		count
		
		if _rc==0 {
			g fb_`var' = 1
			unique `geo_unit'
			unique year_month
			keep `geo_unit' year_month fb_`var'
			save "`outstub/'fb_`var'.dta", replace
			restore
		}
		else {
			restore
		}
			cap merge 1:1 `geo_unit' year_month using `outstub'fb_`var'.dta, nogen keep(match master)	
			cap replace fb_`var' = 0 if missing(fb_`var')	
	}
	// preserve 
	// keep zipcode year_month `var_balance'
	// save "`outstub'fbAll.dta", replace
	// restore

end

program create_latest_event_vars
	syntax, event_dummy(str) window(int) time_var(str) geo_unit(str) [min_option(str)]
	
	local window_span = `window'*2 + 1 

	qui sum year_month if !missing(mw_event)
	local max_period = r(max)
	local event_boundary = `max_period' - `window'
	di "`event_boundary'"

	gen `event_dummy'_`time_var' = `time_var' if `event_dummy' == 1 & `time_var' <= `event_boundary'
	format `event_dummy'_`time_var' %tm
	count if !missing(`event_dummy'_`time_var')

	bysort `geo_unit': egen last_`event_dummy'_`time_var' = max(`event_dummy'_`time_var')
	format last_`event_dummy'_`time_var' %tm
	gen last_`event_dummy'_rel_months`window' = `time_var' - last_`event_dummy'_`time_var'
	replace last_`event_dummy'_rel_months`window' = last_`event_dummy'_rel_months`window' + `window' + 1
	replace last_`event_dummy'_rel_months`window' = 0 ///
	    if last_`event_dummy'_rel_months`window' <= 0
	replace last_`event_dummy'_rel_months`window' = 1000 ///
	    if last_`event_dummy'_rel_months`window' > `window_span'
		
	drop `event_dummy'_`time_var' last_`event_dummy'_`time_var'
	    
end

program create_event_vars_preclean
	syntax, event_dummy(str) window(int) time_var(str) geo_unit(str)

	bysort `geo_unit' (`time_var'): gen event_start = 1 if `event_dummy'[_n + `window'] == 1
	gen event_start_non_overlap = event_start
	forvalues i = 0(1)`window' {  					
		bysort `geo_unit' (`time_var'): replace event_start_non_overlap = . ///
		    if `event_dummy'[_n - `i'] == 1 & event_start_non_overlap[_n - `window' - 1] ==1
	}
	local window_span = 2*`window' + 1
	gen rel_months_`event_dummy' = event_start_non_overlap
	forvalues i = 2(1)`window_span' {  					
		bysort `geo_unit' (`time_var'): replace rel_months_`event_dummy' = `i' ///
		    if event_start_non_overlap[_n - `i' + 1] == 1
	}
	replace rel_months_`event_dummy' = 1000 if rel_months_`event_dummy' == .


	drop event_start event_start_non_overlap
	rename rel_months_`event_dummy' rel_months_`event_dummy'`window'	
end



main
