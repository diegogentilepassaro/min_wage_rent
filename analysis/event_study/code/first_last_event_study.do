clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub  "../temp/"
	local outstub "../output/"

	use `instub'/zipcode_year_month_panel.dta, clear
	

	foreach window in 12 24 {
		create_event_plot, outstub(`outstub') depvar(medrentprice_2br)     			  	///
			event_var(last_min_event_rel_months`window') controls(" ") window(`window')	///
			absorb(zipcode msa calendar_month##state year_month) cluster(zipcode)

		create_event_plot, outstub(`outstub') depvar(medrentpricepsqft_2br)     		///
			event_var(last_min_event_rel_months`window') controls(" ") window(`window')	///
			absorb(zipcode msa calendar_month##state year_month) cluster(zipcode)

		create_event_plot, outstub(`outstub') depvar(zhvi_2br)   						///
			event_var(last_min_event_rel_months`window') controls(" ") window(`window')	///
			absorb(zipcode msa calendar_month##state year_month) cluster(zipcode)
	}
end

main
