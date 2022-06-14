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

    local depvars wkp_jobs_sch_underHS res_jobs_sch_underHS wkp_jobs_naics_ac_food res_jobs_naics_ac_food
	
	foreach depvar of local depvars {
	    gen ln_`depvar' = log(`depvar')
	}
	
	local depvars ln_wkp_jobs_sch_underHS ln_res_jobs_sch_underHS ln_wkp_jobs_naics_ac_food ///
	    ln_res_jobs_naics_ac_food ln_wkp_jobs_tot ln_res_jobs_tot

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
    foreach ff in sh_workers_accomm_food sh_residents_underHS sh_workers_underHS   ///
        ln_wkp_jobs_sch_underHS ln_res_jobs_sch_underHS ln_wkp_jobs_naics_ac_food  ///
	    ln_res_jobs_naics_ac_food ln_wkp_jobs_tot ln_res_jobs_tot {
        append using ../temp/estimates_`ff'.dta
    }
    save             "`outstub'/estimates_static.dta", replace
    export delimited "`outstub'/estimates_static.csv", replace

end

main
