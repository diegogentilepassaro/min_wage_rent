clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
	local instub "../../first_differences/temp"
	local outstub "../output"

	plot_mw_dist, instub(`instub') outstub(`outstub')


end


program plot_mw_dist
	syntax, instub(str) outstub(str)

	use zipcode year_month actual_mw dactual_mw ln_mw d_ln_mw ///
	using `instub'/fd_rent_panel.dta, clear

	replace d_ln_mw = d_ln_mw * 100

	twoway (hist d_ln_mw if dactual_mw>0, color(navy%80) lcolor(white) lw(vthin)), ///
	xtitle("Minimum wage changes (%)", size(small)) xlabel(, labsize(small)) ylabel(, labsize(small)) ///
	graphregion(color(white)) bgcolor(white) 
	graph export `outstub'/d_ln_mw_dist.png, replace 
	graph export `outstub'/d_ln_mw_dist.eps, replace

	keep if dactual_mw>0
	twoway (hist year_month, color(navy%80) lcolor(white) lw(vthin)), ///
	xtitle("Minimum wage change period", size(small)) xlabel(#20, labsize(small) angle(45)) ///
	graphregion(color(white)) bgcolor(white) 
	graph export `outstub'/d_ln_mw_date_dist.png, replace 
	graph export `outstub'/d_ln_mw_date_dist.eps, replace 

end 




main  