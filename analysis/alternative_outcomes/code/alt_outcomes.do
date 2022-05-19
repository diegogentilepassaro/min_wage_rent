clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main

	local instub "../../../drive/derived_large/zipcode_year"
	local outstub "../output"

	use "`instub'/zipcode_year.dta"
	
    define_controls
    local controls "`r(economic_controls)'"
	
    destring cbsa, generate(cbsa_num)

    xtset zipcode_num year

    local depvars sh_residents_accomm_food sh_workers_accomm_food sh_residents_underHS sh_workers_underHS
 
	foreach depvar of local depvars {
	
	estimate_twfe_model if cbsa != "99999", yvar(`depvar') xvars(mw_wkp_tot_15_avg mw_res_avg) ///
	    controls(`controls') absorb(zipcode_num cbsa_num##year) ///
	    cluster(cbsa_num) model_name(`depvar') outfolder("../temp")
	}
	
    use "../temp/estimates_sh_residents_accomm_food.dta", clear
    gen p_equality = .
    foreach ff in sh_workers_accomm_food sh_residents_underHS sh_workers_underHS {
        append using ../temp/estimates_`ff'.dta
    }
    save             "`outstub'/estimates_static.dta", replace
    export delimited "`outstub'/estimates_static.csv", replace
	
end

main
