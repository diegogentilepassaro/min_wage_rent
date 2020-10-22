clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	* Heterogeneity
	foreach var in med_hhinc20105 renthouse_share2010 college_share20105 ///
				black_share2010 nonwhite_share2010 work_county_share20105 {

		build_ytitle, var(`var')

		plot_static_heterogeneity, depvar(ln_med_rent_psqft) absorb(year_month) ///
			het_var(`var'_st_qtl) cluster(statefips) ytitle(`r(title)')
		graph export "`outstub'/fd_static_heter_`var'.png", replace
	}

end

program build_ytitle, rclass
	syntax, var(str)

	if "`var'" == "med_hhinc20105" {
		return local title "Quintiles of within state 2010 median household income"
	}
	if "`var'" == "renthouse_share2010" {
		return local title "Quintiles of 2010 share of houses rent"
	}
	if "`var'" == "college_share20105" {
		return local title "Quintiles of 2010 college share"
	}
	if "`var'" == "black_share2010" {
		return local title "Quintiles of 2010 share of black individuals"
	}
	if "`var'" == "nonwhite_share2010" {
		return local title "Quintiles of 2010 share of non-white individuals"
	}
	if "`var'" == "work_county_share20105" {
		return local title "Quintiles of 2010 share who work in county"
	}
end

program plot_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) het_var(str) ytitle(str) [qtles(int 4)]

	eststo clear
	reghdfe D.`depvar' c.d_ln_mw#i.`het_var', ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	coefplot, base graphregion(color(white)) bgcolor(white) ///
	ylabel(1 "1" 2 "2" 3 "3" 4 "4") ///
	ytitle(`ytitle') ///
	xtitle("Estimated effect of ln MW on ln rents")	///
	xline(0, lcol(black)) mcolor(edkblue) ciopts(recast(rcap) lc(edkblue) lp(dash) lw(vthin))
end




*Execute 
main 
