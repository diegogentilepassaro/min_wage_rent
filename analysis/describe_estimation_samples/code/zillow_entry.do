set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
	local instub  "../../../drive/derived_large/estimation_samples"
	local outstub "../output"
	
	local rent_var  "medrentpricepsqft_SFCC"
	local target_ym "2015m1"
 	
	foreach geo in zipcode county {
		use "`instub'/all_`geo'_months.dta", clear
		keep if !missing(`rent_var')
		gcollapse (min) min_year_month = year_month, by(`geo')
		
		unique `geo'
		local total_geo = r(N)
		
		bysort min_year_month: egen nbr_entrant = count(`geo')
		drop `geo'
		by min_year_month: keep if _n == 1
		gen share_entrant = nbr_entrant/`total_geo'
		gen cum_share_entrant = sum(share_entrant)
	    
		sum cum_share_entrant if min_year_month >= `=tm(`target_ym')'
		local cum_share_at_target = r(min)
		local cum_share_at_target : di %6.3f `cum_share_at_target'
		
		label var nbr_entrant        "Number of entrants"
		label var cum_share_entrant  "Cumulative share of entrants"
		label var min_year_month     "Year-month"
		
		twoway (line nbr_entrant min_year_month, yaxis(1)) ///
			(line cum_share_entrant min_year_month, yaxis(2)), ///
			text(0.8 `=tm(`target_ym')' "`cum_share_at_target'", yaxis(2)) ///
			xline(`=tm(`target_ym')') legend(row(2)) ///
			graphregion(color(white)) bgcolor(white)
		graph export "../output/`geo'_entrants.png", replace
	}
end

main
