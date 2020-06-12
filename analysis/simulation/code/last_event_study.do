clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local FE_1 "zipcode year_month"
	local FE_2 "zipcode year_month statefips##year_month"
	local cluster_se "zipcode"

	foreach w in 6 12 {
		use "`instub'/baseline_panel_rent_w`w'.dta", clear

		foreach i in 1 2 3 {
			
			* rent_var simulated as zipcode + time effects
			create_event_plot, depvar(rent`i') 				  				///
				event_var(last_sal_mw_event_rel_months`w') 					///
				controls(" ") window(`w')									///
				absorb(`FE_1') cluster(`cluster_se')
			graph export "`outstub'/last_rent`i'_w`w'_base.png", replace

			* Control for state##year_month
			create_event_plot, depvar(rent`i') 				  				///
				event_var(last_sal_mw_event_rel_months`w') 					///
				controls(" ") window(`w')									///
				absorb(`FE_2') cluster(`cluster_se')
			graph export "`outstub'/last_rent`i'_w`w'_state_x_time.png", replace
			
			* Control for state-specific trend
			create_event_plot, depvar(rent`i') 				  				///
				event_var(last_sal_mw_event_rel_months`w') 					///
				controls("c.trend#i.statefips") window(`w')					///
				absorb(`FE_1') cluster(`cluster_se')
			graph export "`outstub'/last_rent`i'_w`w'_state-trend.png", replace


			* rent_var simulated as zipcode + time effects + state_specific time effect
			local j = `i' + 3

			create_event_plot, depvar(rent`j') 				  				///
				event_var(last_sal_mw_event_rel_months`w') 					///
				controls(" ") window(`w')									///
				absorb(`FE_1') cluster(`cluster_se')
			graph export "`outstub'/last_rent`j'_w`w'_base.png", replace

			* Control for state##year_month
			create_event_plot, depvar(rent`j') 				  				///
				event_var(last_sal_mw_event_rel_months`w') 					///
				controls(" ") window(`w')									///
				absorb(`FE_2') cluster(`cluster_se')
			graph export "`outstub'/last_rent`j'_w`w'_state_x_time.png", replace

			* Control for state-specific trend
			create_event_plot, depvar(rent`j') 				  				///
				event_var(last_sal_mw_event_rel_months`w') 					///
				controls("c.trend#i.statefips") window(`w')					///
				absorb(`FE_1') cluster(`cluster_se')
			graph export "`outstub'/last_rent`j'_w`w'_state-trend.png", replace
		}
	}
end

main
