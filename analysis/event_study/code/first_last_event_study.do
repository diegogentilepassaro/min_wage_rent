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
	local target_output "medlistingpricepsqft_sfcc medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier medrentpricepsqft_sfcc medrentpricepsqft_mfr5plus zri_sfccmf"

	foreach window in 11 {
		foreach depvar in `target_output' {
			create_event_plot, outstub(`outstub') depvar(`depvar')     			  	///
				event_var(last_`event_dummy'_rel_months`window') controls(" ") window(`window')	///
				absorb(zipcode msa calendar_month##state year_month) cluster(zipcode)			
		}
	}
end

main
