clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000

program main
    local in_zip        "../../../drive/derived_large/zipcode"
    local in_h_exp_sh   "../../../drive/analysis_large/expenditure_shares/"
	
	use "`in_zip'/zipcode_cross.dta", clear
	corr med_hhld_inc_acs2014 sh_mw_wkrs_statutory
	local rho_inc_mw_sh = r(rho)
	
	merge 1:1 zipcode using "`in_h_exp_sh'/s_by_zip.dta", nogen assert(3)
	corr sh_mw_wkrs_statutory s
	local rho_s_mw_sh = r(rho)
	
    cap file close f
    file open   f using "../output/corr_sh_mw_workers_inc_and_s.txt", write replace
    file write  f "Correlation between sh_mw_workers and med hhld inc: `rho_inc_mw_sh'" _n
    file write  f "Correlation between sh_mw_workers and s: `rho_s_mw_sh'" _n
    file close  f
end

main
