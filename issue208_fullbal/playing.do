
use "..\drive\derived_large\estimation_samples\zipcode_months.dta" 

xtset zipcode_num year_month

local state_list 01 02 04 05 06 08 09 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56

mat results = J(51, 2, .)
mat rownames results = `state_list'
mat colnames results = b se

local i = 1
foreach st in `state_list' {
	di " "
	di "Excluded statefips: `st'"
	reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
	   D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	   if fullbal_sample_SFCC == 1 & statefips != "`st'", absorb(year_month##cbsa_num) cluster(statefips) nocons
	
	mat b = e(b)
	mat V = e(V)
	
	mat results[`i', 1] = b[1, 4]
	mat results[`i', 2] = V[4, 4]^.5
	
	local i = `i' + 1
}

cap drop num_obs_cbsa
bys cbsa_num: gen num_obs_cbsa = _N if fullbal_sample_SFCC == 1
xtset zipcode_num year_month


foreach thresh of numlist 250 500 750 1000 1250 1500 2000 {
	di " "
	di "Threshold of observations in CBSA: `thresh'"
	reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
	   D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	   if fullbal_sample_SFCC == 1 & num_obs_cbsa >= `thresh' & !missing(num_obs_cbsa), ///
	   absorb(year_month##) cluster(statefips) nocons
	
}
