clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local FE "zipcode year_month"
	local cluster_se "zipcode"

	foreach w in 6 12 {
		foreach i in 1 2 { 
			use "`instub'/baseline_panel_rent`i'_w`w'.dta", clear
			
			create_event_plot, depvar(rent`i') 				  				///
				event_var(last_sal_mw_event_rel_months`w') 					///
			    controls(" ") window(`w')									///
			    absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`i'_w`w'.png", replace	
		}
	}
end

main
