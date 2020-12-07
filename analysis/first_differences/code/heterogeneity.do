clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	local tablevars      "med_hhinc20105 college_share20105 black_share2010 walall_29y_lowinc_ssh halall_29y_lowinc_ssh"
	local demovars       "med_hhinc20105 unemp_share20105 college_share20105 black_share2010 teen_share2010"
	local demovars_extra "teen_share2010 work_county_share20105 renthouse_share2010"
	local workvars       "walall_29y_lowinc_ssh halall_29y_lowinc_ssh walall_29y_lowinc_zsh halall_29y_lowinc_zsh"
	
	* Heterogeneity plot - demographics and workers' type
	/* foreach var in `demovars' `workvars' `demovars_extra'{

		build_ytitle, var(`var')

		plot_dd_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) ///
			het_var(`var'_st_qtl) cluster(statefips) ytitle(`r(title)')
		graph export "`outstub'/fd_static_heter_`var'.eps", replace
	} */

	*Table - demographics 
	make_table_titles, hetlist(`tablevars')
	local het_titles "`r(title_list)'"

	make_dd_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) ///
		absorb(year_month zipcode) cluster(statefips) hetlist(`tablevars')

	esttab * using "`outstub'/fd_table_het.tex", compress se replace 	///
		keep(*.qtl*) mtitles(`het_titles') substitute(\_ _)  ///
		coeflabels(1.qtl#c.d_ln_mw "First quartile" ///
				   2.qtl#c.d_ln_mw "Second quartile" ///
				   3.qtl#c.d_ln_mw "Third quartile" ///
				   4.qtl#c.d_ln_mw "Fourth quartile") /// 
		stats(N, fmt(%9.0gc) labels("Observations")) star(* 0.10 ** 0.05 *** 0.01) nonote

	*table - workers' type 
	make_table_titles, hetlist(`workvars')
	local het_titles "`r(title_list)'"
	make_dd_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) cluster(statefips) hetlist(`workvars')
	esttab * using "`outstub'/fd_table_workers.tex", compress se replace 	///
		keep(*.qtl*) mtitles(`het_titles') substitute(\_ _)  ///
		coeflabels(1.qtl#c.d_ln_mw "First quartile" ///
				   2.qtl#c.d_ln_mw "Second quartile" ///
				   3.qtl#c.d_ln_mw "Third quartile" ///
				   4.qtl#c.d_ln_mw "Fourth quartile") /// 
		stats(N, fmt(%9.0gc) labels("Observations")) star(* 0.10 ** 0.05 *** 0.01)  nonote
end

program plot_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) het_var(str) ytitle(str) [qtles(int 4)]

	eststo clear
	define_controls
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"
	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	reghdfe D.`depvar' c.d_ln_mw#i.`het_var' D.(`controls'), ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	coefplot, base graphregion(color(white)) bgcolor(white) keep(*.`het_var') ///
		ylabel(1 "First quartile" 2 "Second quartile" 3 "Third quartile" 4 "Fourth quartile") ///
		ytitle(`ytitle') xtitle("Elasticity of rents to the MW")	///
		xline(0, lcol(black)) mcolor(edkblue) ciopts(recast(rcap) lc(edkblue) lw(vthin))
end

program build_ytitle, rclass
	syntax, var(str)

	if "`var'" == "med_hhinc20105" {
		return local title "Quartiles of 2010 median household income"
	}
	if "`var'" == "renthouse_share2010" {
		return local title "Quartiles of 2010 share of houses rent"
	}
	if "`var'" == "college_share20105" {
		return local title "Quartiles of 2010 college share"
	}
	if "`var'" == "black_share2010" {
		return local title "Quartiles of 2010 share of black individuals"
	}
	if "`var'" == "nonwhite_share2010" {
		return local title "Quartiles of 2010 share of non-white individuals"
	}
	if "`var'" == "work_county_share20105" {
		return local title "Quartiles of 2010 share who work in county"
	}
	if "`var'" == "unemp_share20105" {
		return local title "Quartiles of 2010 unemployment rate"
	}
	if "`var'" == "teen_share2010" {
		return local title "Quartiles of 2010 share of 15-24 years old residents"
	}
	if "`var'" == "urb_share2010" {
		return local title "Quartiles of 2010 share of urban population"
	}
	if "`var'" == "youngadult_share2010" {
		return local title "Quartiles of 2010 share of 25-34 years old residents"
	}
	if "`var'" == "worktravel_10_share20105" {
		return local title "Quartiles of 2010 share of workers commuting in 10 minutes"
	}
	if "`var'" == "worker_foodservice20105" {
		return local title "Quartiles of 2010 share of food and service industry workers"
	}
	if "`var'" == "sh_mww_wmean2" {
		return local title "Quartiles of 2010 share of MW workers (ACS)"
	}
	if "`var'" == "sh_mww_renter_wmean2" {
		return local title "Quartiles of 2010 share of MW workers and renters (ACS)"
	}
	if "`var'" == "mww_shrenter_wmean2" {
		return local title "Quartiles of 2010 share of renters that are MW workers (ACS)"
	}

	if "`var'" == "walall_njob_29young_ssh" {
		return local title "Workers 29 yrs or younger - workplace state-level share"
	}
	if "`var'" == "halall_njob_29young_ssh" {
		return local title "Workers 29 yrs or younger - residence state-level share"
	}
	if "`var'" == "walall_29y_lowinc_ssh" {
		return local title "Low income workers 29 yrs or younger - workplace state-level share"
	}
	if "`var'" == "halall_29y_lowinc_ssh" {
		return local title "Low income workers 29 yrs or younger - residence state-level share"
	}
	if "`var'" == "walall_29y_lowinc_zsh" {
		return local title "Low income workers 29 yrs or younger - workplace zipcode-level share"
	}
	if "`var'" == "halall_29y_lowinc_zsh" {
		return local title "Low income workers 29 yrs or younger - residence zipcode-level share"
	}
end

program plot_dd_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) het_var(str) ytitle(str) [qtles(int 4)]

	eststo clear
	define_controls
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"
	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	reghdfe D.`depvar' c.d_ln_mw#i.`het_var' D.(`controls'), ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	coefplot, base graphregion(color(white)) bgcolor(white) keep(*.`het_var'*) ///
		ylabel(1 "1" 2 "2" 3 "3" 4 "4") levels(90) ///
		ytitle(`ytitle', size(small)) ///
		xtitle("Estimated effect of ln MW on ln rents", size(small)) xlabel(-.05(.02).1)	///
		xline(0, lcol(black)) mc(edkblue) ciopts(recast(rcap) lc(edkblue) lp(dash) lw(vthin))
end

program make_dd_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) hetlist(str) [qtles(int 4)]

	define_controls
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"
	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	local hetlist_qtl ""
	foreach var in `hetlist' {
		local hetlist_qtl `"`hetlist_qtl' `var'_st_qtl"'
	}

	eststo clear
	foreach var in `hetlist_qtl' {
		rename `var' qtl
		eststo: reghdfe D.`depvar' c.d_ln_mw#i.qtl D.(`controls'), ///
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
			local title_list `"`title_list' "\shortstack{Median \\ income}""'
		}
		if "`var'" == "renthouse_share2010" {
			local title_list `"`title_list' "\shortstack{Rent \\ house (\%)}""'
		}
		if "`var'" == "college_share20105" {
			local title_list `"`title_list' "\shortstack{College \\ grad. (\%)}""'
		}
		if "`var'" == "black_share2010" {
			local title_list `"`title_list' "\shortstack{African- \\ am. (\%)}""'
		}
		if "`var'" == "nonwhite_share2010" {
			local title_list `"`title_list' "\shortstack{Non-white \\ pop. (\%)}""'
		}
		if "`var'" == "work_county_share20105" {
			local title_list `"`title_list' "\shortstack{Work in \\ county (\%)}""'
		}
		if "`var'" == "unemp_share20105" {
			local title_list `"`title_list' "\shortstack{Unemp. \\ rate (\%)}""'
		}
		if "`var'" == "teen_share2010" {
			local title_list `"`title_list' "\shortstack{15-24 years \\ old (\%)}""'
		}
		if "`var'" == "walall_njob_29young_ssh" {
			local title_list `"`title_list' "\shortstack{Young worker, \\ workplace}""'		
		}
		if "`var'" == "halall_njob_29young_ssh" {
			local title_list `"`title_list' "\shortstack{Young worker, \\ residence}""'		
		}
		if "`var'" == "walall_29y_lowinc_ssh" {
			local title_list `"`title_list' "\shortstack{Young low-income \\ worker, workplace}""'		
		}
		if "`var'" == "halall_29y_lowinc_ssh" {
			local title_list `"`title_list' "\shortstack{Young low-income \\ worker, residence}""'		
		}
	}

	return local title_list "`title_list'" 
end 


*Execute 
main 
