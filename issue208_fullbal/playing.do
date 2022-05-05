
use "..\drive\derived_large\estimation_samples\zipcode_months.dta"

xtset zipcode_num year_month

*** Drop state
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

*** Drop CBAs
local cbsa_list 35620 47900 47260 45300 42660 41860 41740 41700 40140 38060 37980 36740 33460 33100 31080 29820 27260 26420 19820 19740 19100 16980 16740 14460 12420 12580 12060

mat results = J(27, 2, .)
mat rownames results = `cbsa_list'
mat colnames results = b se

local i = 1
foreach cbsa of numlist `cbsa_list' {
	di " "
	di "Excluded CBSA: `cbsa'"
	reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
	   D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	   if fullbal_sample_SFCC == 1 & cbsa_num != `cbsa', absorb(year_month##cbsa_num) cluster(statefips) nocons
	
	mat b = e(b)
	mat V = e(V)
	
	mat results[`i', 1] = b[1, 4]
	mat results[`i', 2] = V[4, 4]^.5
	
	local i = `i' + 1
}

** Drop CBSAs with low number of ZIP codes
cap drop num_obs_cbsa
bys cbsa_num: gen num_obs_cbsa = _N if fullbal_sample_SFCC == 1
xtset zipcode_num year_month


foreach thresh of numlist 250 500 750 1000 1250 1500 2000 {
	di " "
	di "Threshold of observations in CBSA: `thresh'"
	reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
	   D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	   if fullbal_sample_SFCC == 1 & num_obs_cbsa >= `thresh' & !missing(num_obs_cbsa), ///
	   absorb(year_month##cbsa_num) cluster(statefips) nocons
	
}

** Drop ZIP codes with extreme values of rents

sum ln_rents, d
local p1  = r(p1)
local p99 = r(p99)

gen extreme_val =  !missing(ln_rents) & ((ln_rents <= `p1') | (ln_rents >= `p99'))

preserve
	collapse (max) extr_val = extreme_val, by(zipcode)
	
	tempfile extreme
	save    `extreme'
restore

merge m:1 zipcode using `extreme', nogen
xtset zipcode_num year_month

reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
   D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
   if fullbal_sample_SFCC == 1, ///
   absorb(year_month##cbsa_num) cluster(statefips) nocons
   
reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
   D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
   if fullbal_sample_SFCC == 1 & !extr_val, ///
   absorb(year_month##cbsa_num) cluster(statefips) nocons

** Estimate by year

foreach yyyy of numlist 2015 2016 2017 2018 2019 {

	reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
	   D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	   if fullbal_sample_SFCC == 1 & year >= `yyyy', ///
	   absorb(year_month##cbsa_num) cluster(statefips) nocons
}

** Balance in 2017m1

use "..\drive\derived_large\estimation_samples\zipcode_months.dta", clear

preserve
	collapse (min) min_ym = year_month if !missing(ln_rents), by(zipcode)
	
	keep if min_ym <= `=tm(2017m2)'
	
	tempfile balanced_zip
	save    `balanced_zip'
restore

merge m:1 zipcode using `balanced_zip'

keep if _merge == 3 & year >= 2017

xtset zipcode_num year_month

reghdfe D.ln_rents D.mw_res D.mw_wkp_tot_17 ///
	D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	, absorb(year_month) cluster(statefips)

reghdfe D.ln_rents D.mw_res D.mw_wkp_tot_17 ///
	D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	, absorb(year_month##cbsa_num) cluster(statefips)

reghdfe D.ln_rents D.mw_res L(-6/0).D.mw_wkp_tot_17 ///
	D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	, absorb(year_month) cluster(statefips)

reghdfe D.ln_rents D.mw_res L(-6/0).D.mw_wkp_tot_17 ///
	D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	, absorb(year_month##cbsa_num) cluster(statefips)

** Controls

use "..\drive\derived_large\estimation_samples\zipcode_months.dta", clear

merge m:1 zipcode using "..\drive\derived_large\zipcode\zipcode_cross.dta"
keep if _merge == 3
drop _merge


preserve

	keep if year_month == `=tm(2015m1)'
	keep if statutory_mw == 7.25
	rename statutory_mw stat_mw_baseline

	tempfile mw_base
	save    `mw_base'
restore

merge m:1 zipcode using `mw_base'

xtset zipcode_num year_month

* sh_residents_under1250_2013 sh_residents_underHS_2013

reghdfe D.ln_rents D.mw_res D.mw_wkp_tot_17 ///
	D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	if fullbal_sample_SFCC == 1, absorb(year_month i.month##c.sh_residents_under29_2013) cluster(statefips) nocons

reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
	D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	if fullbal_sample_SFCC == 1, absorb(year_month##cbsa_num) cluster(statefips) nocons

reghdfe D.ln_rents D.mw_res L(-6/6).D.mw_wkp_tot_17 ///
	D.( ln_emp_bizserv ln_emp_info ln_emp_fin ln_estcount_bizserv ln_estcount_info ln_estcount_fin ln_avgwwage_bizserv ln_avgwwage_info ln_avgwwage_fin ) ///
	if fullbal_sample_SFCC == 1, absorb(year_month##cbsa_num i.month##c.sh_residents_under1250_2013 i.month##c.sh_residents_under29_2013 i.month##c.sh_residents_underHS_2013) cluster(statefips) nocons

