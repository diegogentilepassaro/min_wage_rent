set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local logfile      "../output/data_file_manifest.log"
    
    use "`instub'/all_zipcode_months.dta", clear
	xtset zipcode_num year_month
	
	gen change_mw = (actual_mw > L.actual_mw)
	bysort cbsa10 year_month: gen treated = (change_mw == 1)
end


main
