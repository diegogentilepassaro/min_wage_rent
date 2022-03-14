clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local in_est "../../../drive/derived_large/estimation_samples"
    local in_zip_yr "../../../drive/derived_large/zipcode_year"
    local outstub "../output"

    define_controls
    local controls "`r(economic_controls)'"
	local avg_controls "ln_emp_bizserv_avg ln_emp_const_avg ln_emp_eduhe_avg"
	local avg_controls "`avg_controls' ln_emp_fedgov_avg ln_emp_fin_avg"
	local avg_controls "`avg_controls' ln_emp_info_avg ln_emp_leis_avg ln_emp_locgov_avg"
	local avg_controls "`avg_controls' ln_emp_manu_avg ln_emp_natres_avg"
	local avg_controls "`avg_controls' ln_emp_stgov_avg ln_emp_transp_avg"
    local cluster = "statefips"
    local absorb  = "year"

    local mw_wkp_var "mw_wkp_tot_17"
	
    use "`in_zip_yr'/zipcode_year.dta", clear
	get_sample_flags, instub(`in_est')
    xtset zipcode_num year
	
	gen ln_wkp_jobs_tot = log(wkp_jobs_tot) 
	gen ln_res_jobs_tot = log(res_jobs_tot)

	eststo clear
	eststo: run_model if baseline_sample == 1, depvar(ln_rents_avg) ///
	    mw_res(mw_res_avg) mw_wkp(mw_wkp_tot_17_avg) ///
	    controls(`avg_controls') absorb(`absorb') cluster(`cluster')
	
	eststo: run_model if baseline_sample == 1, depvar(ln_rents) ///
	    mw_res(mw_res) mw_wkp(mw_wkp_tot_17) ///
	    controls(`controls') absorb(`absorb') cluster(`cluster')
		
	eststo: run_model if baseline_sample == 1, depvar(ln_safmr2br) ///
	    mw_res(mw_res_avg) mw_wkp(mw_wkp_tot_17_avg) ///
	    controls(`avg_controls') absorb(`absorb') cluster(`cluster')
	
	eststo: run_model if baseline_sample == 1, depvar(ln_safmr2br) ///
	    mw_res(mw_res) mw_wkp(mw_wkp_tot_17) ///
	    controls(`controls') absorb(`absorb') cluster(`cluster')
	esttab * using "../output/rents.txt", replace ///
		se keep(D.mw_res_avg D.mw_wkp_tot_17_avg D.mw_res D.mw_wkp_tot_17) ///
		star(* 0.10 ** 0.05 *** 0.01)
		
	eststo clear
	eststo: run_model if baseline_sample == 1, depvar(ln_res_jobs_tot) ///
	    mw_res(mw_res_avg) mw_wkp(mw_wkp_tot_17_avg) ///
	    controls(`avg_controls') absorb(`absorb') cluster(`cluster')
	
	eststo: run_model if baseline_sample == 1, depvar(ln_res_jobs_tot) ///
	    mw_res(mw_res) mw_wkp(mw_wkp_tot_17) ///
	    controls(`controls') absorb(`absorb') cluster(`cluster')
		
	eststo: run_model if baseline_sample == 1, depvar(ln_wkp_jobs_tot) ///
	    mw_res(mw_res_avg) mw_wkp(mw_wkp_tot_17_avg) ///
	    controls(`avg_controls') absorb(`absorb') cluster(`cluster')
	
	eststo: run_model if baseline_sample == 1, depvar(ln_wkp_jobs_tot) ///
	    mw_res(mw_res) mw_wkp(mw_wkp_tot_17) ///
	    controls(`controls') absorb(`absorb') cluster(`cluster')
	esttab * using "../output/workers.txt", replace ///
		se keep(D.mw_res_avg D.mw_wkp_tot_17_avg D.mw_res D.mw_wkp_tot_17) ///
		star(* 0.10 ** 0.05 *** 0.01)
end

program get_sample_flags
    syntax, instub(str)
	
	preserve
	    use zipcode year_month year baseline_sample fullbal_sample ///
		    using "`instub'/zipcode_months.dta", clear
		bysort zipcode year (year_month): keep if _n == 7
		drop year_month
		save "../temp/sample_flags.dta", replace
	restore
	
	merge 1:1 zipcode year using "../temp/sample_flags.dta", nogen keep(1 3)
end

program run_model
    syntax [if], depvar(str) mw_res(str) mw_wkp(str) ///
	    controls(str) absorb(str) cluster(str)
	
	reghdfe D.`depvar' D.`mw_res' D.`mw_wkp' D.(`controls') `if', ///
	    absorb(`absorb') cluster(`cluster')
end

main
