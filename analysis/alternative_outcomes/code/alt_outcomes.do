clear all
set more off
set maxvar 32000 

program main

	local instub "../../../drive/derived_large/zipcode_year"

	use "`instub'/zipcode_year.dta"

	xtset zipcode_num year

	destring cbsa, generate(cbsa_num)
	
	local depvars sh_workers_under1250 sh_residents_underHS sh_workers_accomm_food
	
	foreach depvar of local depvars {
		reghdfe `depvar' L(-1/3).mw_wkp_tot_15_avg mw_res_avg if cbsa != "99999", ///
		absorb(zipcode_num cbsa_num##year) cluster(cbsa_num) nocons
	}

	forval bd = 0(1)4 {
		reghdfe ln_safmr`bd'br mw_wkp_tot_16_avg mw_res_avg if cbsa != "99999", ///
			absorb(zipcode_num cbsa_num##year) cluster(cbsa_num) nocons
	}

end

main
