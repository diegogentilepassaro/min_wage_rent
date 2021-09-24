clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/estimation_samples"
	local outstub "../output"
	
	define_controls
	local controls "`r(economic_controls)'"
	local cluster "statefips"
	
	
	** STATIC
	use "`instub'/baseline_zipcode_months.dta", clear
	xtset zipcode_num year_month

end


main
