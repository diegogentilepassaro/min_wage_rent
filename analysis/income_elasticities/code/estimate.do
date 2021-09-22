set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local in_derived_large "../../../drive/derived_large"
    local outstub          "../../../drive/derived_large/zipcode_year"
    local logfile          "../output/data_file_manifest.log"

	use "`in_derived_large'/zipcode_year/zipcode_year.dta", clear
	
	destring zipcode, gen(zipcode_num)
	destring statefips, gen(statefips_num)
	destring countyfips, gen(countyfips_num)

	xtset zipcode_num year
	
	define_controls
	local controls "`r(economic_controls)'"
	local cluster "statefips"
	
    reghdfe D.ln_agi_per_cap D.exp_ln_mw D.ln_mw D.(`controls'), ///
	    absorb(year#statefips_num) cluster(`cluster')
    reghdfe D.ln_wage_per_cap D.exp_ln_mw D.ln_mw D.(`controls'), ///
	    absorb(year#statefips_num) cluster(`cluster')
    reghdfe D.ln_wage_per_wage_hhld D.exp_ln_mw D.ln_mw D.(`controls'), ///
	    absorb(year#statefips_num) cluster(`cluster')
    reghdfe D.ln_bussines_rev_per_owner D.exp_ln_mw D. ln_mw D.(`controls'), ///
	    absorb(year#statefips_num) cluster(`cluster')
end

main
