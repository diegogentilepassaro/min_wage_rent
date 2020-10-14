clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	local hetvars "med_hhinc20105 renthouse_share2010 college_share20105 black_share2010"
	* Heterogeneity
	foreach var in `hetvars' {

		build_ytitle, var(`var')

		plot_dd_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) ///
			het_var(`var'_st_qtl) cluster(statefips) ytitle(`r(title)')
		graph export "`outstub'/fd_static_heter_`var'.png", replace

	}
	

	make_table_titles, hetlist(`hetvars')
	local het_titles "`r(title_list)'"

	di `het_titles'

	make_dd_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) cluster(statefips) hetlist(`hetvars')
	esttab * using "`outstub'/fd_table_het.tex", compress se replace 	///
		mtitles(`het_titles') substitute(\_ _)  ///
		coeflabels(1.qtl#c.d_ln_mw "$\Delta \ln(MW) \times 1^{st} qtl$" ///
				   2.qtl#c.d_ln_mw "$\Delta \ln(MW) \times 2^{nd} qtl$" ///
				   3.qtl#c.d_ln_mw "$\Delta \ln(MW) \times 3^{rd} qtl$" ///
				   4.qtl#c.d_ln_mw "$\Delta \ln(MW) \times 4^{th} qtl$") /// 
		stats(r2 N, fmt(%9.3f %9.0gc) labels("R-squared" "Observations")) ///
		star(* 0.10 ** 0.05 *** 0.01)  nonote

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

program plot_dd_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) het_var(str) ytitle(str) [qtles(int 4)]

	eststo clear
	reghdfe D.`depvar' c.d_ln_mw#i.`het_var', ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	coefplot, base graphregion(color(white)) bgcolor(white) ///
	ylabel(1 "1" 2 "2" 3 "3" 4 "4") ///
	ytitle(`ytitle') ///
	xtitle("Estimated effect of ln MW on ln rents")	///
	xline(0, lcol(black)) mc(edkblue) ciopts(recast(rcap) lc(edkblue) lp(dash) lw(vthin))
end

program make_dd_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) hetlist(str) [qtles(int 4)]

	local hetlist_qtl ""
	foreach var in `hetlist' {
		local hetlist_qtl `"`hetlist_qtl' `var'_st_qtl"'
	}

	eststo clear
	foreach var in `hetlist_qtl' {
		rename `var' qtl
		eststo: reghdfe D.`depvar' c.d_ln_mw#i.qtl, ///
			absorb(`absorb') ///
			vce(cluster `cluster') nocons	
		rename qtl `var'
	} 
end 

program make_table_titles, rclass 
	syntax, hetlist(str) 

	local title_list "" 
	foreach var in `hetlist' {
		if "`var'" == "med_hhinc20105" {
			local title_list `"`title_list' "Median Income""'
		}
		if "`var'" == "renthouse_share2010" {
			local title_list `"`title_list' "Rental House (\%)""'
		}
		if "`var'" == "college_share20105" {
			local title_list `"`title_list' "College Grad. (\%)""'
		}
		if "`var'" == "black_share2010" {
			local title_list `"`title_list' "African Am. (\%)""'
		}
		if "`var'" == "nonwhite_share2010" {
			local title_list `"`title_list' "Non-white pop. (\%)""'
		}
		if "`var'" == "work_county_share20105" {
			local title_list `"`title_list' "Work in county (\%)""'
		}
	}

	return local title_list "`title_list'" 

end 



*Execute 
main 
