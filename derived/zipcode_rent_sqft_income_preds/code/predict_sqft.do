clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000
set matsize 11000

program main
	local instub      "../../../base/geo_master/output"
	local in_acs_2019 "../../../base/acs_2019/output"
	local in_irs      "../../../drive/base_large/irs_soi"
	
	import delimited "`in_acs_2019'/acs_2019.csv", ///
	    stringcols(1) clear
	save "../temp/acs_2019.dta", replace
	
	use zipcode statefips year total_wage adj_gross_inc num_hhlds_irs using ///
	    "`in_irs'/irs_zip.dta", clear
	keep if year == 2018
	drop year
	drop if (zipcode == "00000" | zipcode == "99999")
    save "../temp/irs.dta", replace

	use "`instub'/zip_county_place_usps_master.dta", clear
	drop place_name county_name cbsa10_name state_abb 
	merge 1:1 zipcode using "../output/housing_sqft_per_zipcode.dta", ///
	    nogen assert(3)
	merge 1:1 zipcode using "../temp/irs.dta", nogen keep(1 3)
	merge m:1 zcta using "../temp/acs_2019.dta", nogen keep(1 3)
	keep if rural == 0
	
	foreach var in countyfips cbsa10 zipcode_type {
	    encode `var', gen(num_`var')
	}
	
	local covariates "area_sqmi pop2020_esri houses_zcta_place_county black hispanic total_households"
	local fes "i.num_countyfips i.num_cbsa10 i.num_zipcode_type"
	
	get_poisson_preds, depvar(sqft_from_rents) ///
	    covariates(`covariates') fes(`fes')
	get_poisson_preds, depvar(sqft_from_listings) ///
	    covariates(`covariates') fes(`fes')
	get_poisson_preds, depvar(rent_psqft) ///
	    covariates(`covariates') fes(`fes')
	get_poisson_preds, depvar(total_wage) ///
	    covariates(`covariates') fes(`fes')

	save_data "../output/predictions.dta", ///
	    key(zipcode) replace
	export delimited "../output/predictions.csv", replace
end

program get_poisson_preds
    syntax, depvar(str) covariates(str) fes(str)

	poisson `depvar' `covariates' `fes'
	predict p_`depvar', n
	gen imp_`depvar' = `depvar'
	replace imp_`depvar' = p_`depvar' if missing(`depvar')
end

main
