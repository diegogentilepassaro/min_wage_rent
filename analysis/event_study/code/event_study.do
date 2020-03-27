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

	local event_dummy "mw_event"	
	local target_output "medrentprice_sfcc medrentpricepsqft_sfcc zri_sfccmf"

	foreach window in 12 24 {
		foreach depvar in `target_output' {
			create_event_plot, outstub(`outstub') depvar(`depvar')				///
				event_var(rel_months_`event_dummy'`window') controls(" ") window(`window')	///
				absorb(zipcode msa calendar_month##state year_month) cluster(zipcode)			
		}
	}
end

main
