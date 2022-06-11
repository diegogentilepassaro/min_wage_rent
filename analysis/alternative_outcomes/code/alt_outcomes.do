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

    foreach cat in accomm_food underHS {
        gen tot_res_`cat' = ln(res_jobs_tot * sh_residents_`cat')
        gen tot_wkp_`cat' = ln(wkp_jobs_tot * sh_workers_`cat')
    }

    local depvars tot_wkp_underHS tot_res_underHS tot_wkp_accomm_food tot_res_accomm_food

    foreach depvar of local depvars {

        estimate_twfe_model if cbsa != "99999", yvar(`depvar') xvars(mw_wkp_tot_15_avg mw_res_avg) ///
            controls(`controls') absorb(zipcode_num cbsa_num##year) ///
            cluster(cbsa_num) model_name(`depvar') outfolder("../temp")
    }

    local depvars sh_residents_accomm_food sh_workers_accomm_food sh_residents_underHS sh_workers_underHS

    foreach depvar of local depvars {

        estimate_twfe_model if cbsa != "99999", yvar(`depvar') xvars(mw_wkp_tot_15_avg mw_res_avg) ///
            controls(`controls') absorb(zipcode_num cbsa_num##year) ///
            cluster(cbsa_num) model_name(`depvar') outfolder("../temp")
    }

    use "../temp/estimates_sh_residents_accomm_food.dta", clear
    gen p_equality = .
    foreach ff in sh_workers_accomm_food sh_residents_underHS sh_workers_underHS tot_wkp_underHS ///
        tot_res_underHS tot_wkp_accomm_food tot_res_accomm_food {
        append using ../temp/estimates_`ff'.dta
    }
    save             "`outstub'/estimates_static.dta", replace
    export delimited "`outstub'/estimates_static.csv", replace

end

main
