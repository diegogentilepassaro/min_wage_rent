set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local logfile      "../output/data_file_manifest.log"
    
    use "`instub'/all_zipcode_months.dta", clear
	xtset zipcode_num year_month
	drop if cbsa10 == "99999"
	gen change_mw = (actual_mw > L.actual_mw)
	
	preserve
	    collapse (max) change_within_cbsa = change_mw, by(cbsa10 year_month)
	    bysort cbsa10 (year_month): gen nbr_cum_changes = sum(change_within_cbsa)
		egen cbsa10_event_id = group(nbr_cum_changes cbsa10)
		keep cbsa10 year_month cbsa10_event_id
		save "../temp/event_ids", replace
	restore
	
	merge m:1 cbsa10 year_month using "../temp/event_ids", 
end


main
