clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local in_baseline "../../../drive/derived_large/estimation_samples"
	local in_zip_year "../../../drive/derived_large/zipcode_year"

	local outstub "../output"
	
	define_controls
	local controls "`r(economic_controls)'"
	local cluster "statefips"
	
	** STATIC
	load_and_clean, in_baseline(`in_baseline') ///
	    in_zip_year(`in_zip_year')

	xtset zipcode_num year_month
	eststo clear
	foreach var in under29 under1250 underHS {
	eststo: reghdfe D.ln_med_rent_var d_ln_mw d_ln_mw_int_wrkpl_`var' ///
	    d_exp_ln_mw_17 d_exp_ln_mw_17_int_res_`var', nocons ///
		absorb(year_month) cluster(statefips)	
	}
    esttab *, se r2
end


program load_and_clean
    syntax, in_baseline(str) in_zip_year(str)

	use "`in_baseline'/baseline_zipcode_months.dta", clear
	merge m:1 zipcode year using "`in_zip_year'/zipcode_year.dta", ///
	    nogen keep(3) keepusing (res_* wrkpl_*)
	
	xtset zipcode_num year_month
	
	gen d_ln_mw        = D.ln_mw
	gen d_exp_ln_mw_17 = D.exp_ln_mw_17
	
	foreach var in under29 under1250 underHS {
	    bys statefips: egen sh_res_`var'_med  = median(res_`var')
	    bys statefips: egen sh_wrkpl_`var'_med = median(wrkpl_`var')	
	    
		gen sh_res_`var'_above_med_st    = (res_`var' > sh_res_`var'_med)
	    gen sh_wrkpl_`var'_above_med_st  = (wrkpl_`var'   > sh_wrkpl_`var'_med)
	    drop *_med
		
	    gen d_ln_mw_int_wrkpl_`var'      = d_ln_mw*sh_wrkpl_`var'_above_med_st
	    gen d_exp_ln_mw_17_int_res_`var' = d_ln_mw*sh_res_`var'_above_med_st
	}
end


main
