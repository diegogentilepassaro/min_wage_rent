clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	local demovars       "med_hhinc20105 unemp_share20105 college_share20105 black_share2010"
	local demovars_extra "teen_share2010 urb_share2010 youngadult_share2010 worktravel_10_share20105 worker_foodservice20105"
	local workvars       "walall_29y_lowinc_ssh halall_29y_lowinc_ssh walall_29y_lowinc_zsh halall_29y_lowinc_zsh"
	
	* Heterogeneity plot - demographics and workers' type
	foreach var in `demovars' `workvars' `demovars_extra'{

		build_ytitle, var(`var')

		plot_dd_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) ///
			het_var(`var'_st_qtl) cluster(statefips) ytitle(`r(title)')
		graph export "`outstub'/fd_static_heter_`var'.png", replace

	}

	*table - demographics 
	make_table_titles, hetlist(`demovars')
	local het_titles "`r(title_list)'"
	make_dd_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) cluster(statefips) hetlist(`demovars')
	esttab * using "`outstub'/fd_table_het.tex", compress se replace 	///
		mtitles(`het_titles') substitute(\_ _)  ///
		coeflabels(1.qtl#c.d_ln_mw "$\Delta \ln(MW) \times 1^{st} qtl$" ///
				   2.qtl#c.d_ln_mw "$\Delta \ln(MW) \times 2^{nd} qtl$" ///
				   3.qtl#c.d_ln_mw "$\Delta \ln(MW) \times 3^{rd} qtl$" ///
				   4.qtl#c.d_ln_mw "$\Delta \ln(MW) \times 4^{th} qtl$") /// 
		stats(r2 N, fmt(%9.3f %9.0gc) labels("R-squared" "Observations")) ///
		star(* 0.10 ** 0.05 *** 0.01)  nonote

	*table - workers' type 
	make_table_titles, hetlist(`workvars')
	local het_titles "`r(title_list)'"
	make_dd_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) cluster(statefips) hetlist(`workvars')
	esttab * using "`outstub'/fd_table_workers.tex", compress se replace 	///
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
	reghdfe D.`depvar' c.d_ln_mw#i.`het_var', ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	coefplot, base graphregion(color(white)) bgcolor(white) ///
	ylabel(1 "1" 2 "2" 3 "3" 4 "4") levels(90) ///
	ytitle(`ytitle', size(small)) ///
	xtitle("Estimated effect of ln MW on ln rents", size(small)) xlabel(-.05(.02).1)	///
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
		if "`var'" == "unemp_share20105" {
			local title_list `"`title_list' "Unemp. rate (\%)""'
		}
		if "`var'" == "walall_njob_29young_ssh" {
			local title_list `"`title_list' "\shortstack{Young worker,  \\ workplace}""'		
		}
		if "`var'" == "halall_njob_29young_ssh" {
			local title_list `"`title_list' "\shortstack{Young worker,  \\ residence}""'		
		}
		if "`var'" == "walall_29y_lowinc_ssh" {
			local title_list `"`title_list' "\shortstack{Young low-income worker,  \\ workplace}""'		
		}
		if "`var'" == "halall_29y_lowinc_ssh" {
			local title_list `"`title_list' "\shortstack{Young low-income worker,  \\ residence}""'		
		}

	}

	return local title_list "`title_list'" 

end 



*Execute 
main 
