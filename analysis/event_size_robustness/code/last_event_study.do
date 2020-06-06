clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local FE "zipcode calendar_month#countyfips year_month#statefips"
	local cluster_se "zipcode"

	foreach w in 6 12 {

		local depvar "psqft_sfcc"

		use "`instub'/baseline_rent_panel_`w'.dta", clear
			
	    create_event_plot, depvar(medrentprice`depvar') 					///
			event_var(last_mw_event025_rel_months`w') 						///
			controls("i.c_unused_mw_event025_`w'") window(`w')				///
			absorb(`FE') cluster(`cluster_se')
	    graph export "../output/last_rent`depvar'_event025_w`w'.png", replace
		
	    create_event_plot, depvar(medrentprice`depvar') 					///
			event_var(last_mw_event075_rel_months`w') 						///
			controls("i.c_unused_mw_event075_`w'") window(`w')				///
			absorb(`FE') cluster(`cluster_se')
	    graph export "`outstub'/last_rent`depvar'_event075_w`w'.png", replace
		

		use "`instub'/baseline_listing_panel_`w'.dta", clear
		
        create_event_plot, depvar(medlistingprice`depvar') 						///
			event_var(last_mw_event025_rel_months`w') 							///
			controls("i.c_unused_mw_event025_`w'") window(`w')					///
			absorb(`FE') cluster(`cluster_se')
	    graph export "../output/last_listing`depvar'_event025_w`w'.png", replace
		
	    create_event_plot, depvar(medlistingprice`depvar') 						///
			event_var(last_mw_event075_rel_months`w') 							///
			controls("i.c_unused_mw_event075_`w'") window(`w')					///
			absorb(`FE') cluster(`cluster_se')
	    graph export "`outstub'/last_listing`depvar'_event075_w`w'.png", replace
	}
end

main
