set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado
set scheme s1color

program main 
	local instub "../../../drive/derived_large/output"
	local outstub "../output"

	use zipcode year_month place_code placetype countyfips  ///
		statefips medrentprice* fed_mw state_mw county_mw   ///
		local_mw actual_mw dactual_mw which_mw mw_event msa /// 
		using `instub'/unbal_rent_panel.dta, clear 

		prepare_vars, log_vars(actual_mw)

		plot_mw_time, out(`outstub') target(d_ln_mw) sample(sfcc 2br mfr5plus)
		

		plot_mw_changes, out(`outstub') target(d_ln_mw) sample(sfcc 2br mfr5plus)
		

end 


program plot_mw_changes
	syntax, out(str) target(str) sample(str)

	foreach var in `sample' {
		
		local depvar "medrentpricepsqft_`var'"
		g `target'plot = `target'*100

		*currently there are only 3 events with a negative MW change (1 must be corrected, 1 is ok, 1 could not find out)
		twoway (hist `target'plot if  `target'>0 & !missing(`depvar'), color(ebblue) lc(white)), ///
		xtitle("{&Delta} Min. wage (p.p.)") ylabel(, grid)
		graph export `out'/hist_mw_change_pct_`var'.png, replace 
		
		drop `target'plot
	}
end



program plot_mw_time
	syntax, out(str) target(str) sample(str)

	foreach var in `sample' {

		local depvar "medrentpricepsqft_`var'"
		preserve

		keep if `target' >0 & !missing(`depvar')

		collapse (count) `target', by(year_month)

		twoway (bar `target' year_month, bargap(.5) color(ebblue) barwidth(1.5) lc(white)), ///
		xlabel(#18, angle(45) labsize(small)) ylabel(, grid) ytitle("") xtitle("")
		graph export `out'/hist_mw_time_`var'.png, replace 
		restore
	}



end 

program prepare_vars
	syntax, log_vars(str)
	foreach var in `log_vars' {
			gen ln_`var' = ln(`var')
		}

	rename ln_actual_mw ln_mw 
	g d_ln_mw = D.ln_mw
end 




main 