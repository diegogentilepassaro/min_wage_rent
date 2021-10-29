clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
	local in_sample   "../../../drive/derived_large/estimation_samples"
	local in_preds    "../../../derived/zipcode_rent_sqft_income_preds/output"
	local in_irs      "../../../drive/base_large/irs_soi"
	local in_cf_mw    "../../../drive/derived_large/min_wage"
	local in_est      "../../fd_baseline_predictions/output"
	local in_income   "../../twfe_wages_predictions/output"
	
	use "`in_income'/twfe_wages_predictions.dta", clear
	keep if (year == 2018 | year == 2020)
	replace year = 2019 if year == 2018
    replace ln_wagebill = p_ln_wagebill if year == 2020
	gen d_ln_wagebill = ln_wagebill[_n] - ln_wagebill[_n - 1]
	keep if year == 2020
	keep zipcode d_ln_wagebill residuals
    save "../temp/income_pred.dta", replace
	
	use "`in_est'/fd_baseline_predictions.dta", clear
	keep if (year == 2019 & month == 12 | year == 2020 & month == 1)
    replace ln_rents = ln_rents[_n -1] if year == 2020
	keep if year == 2020
	keep zipcode d_ln_wagebill residual
	save "../temp/rents_pred.dta", replace
	
	use "../temp/counterfactual.dta", clear
	merge m:1 zipcode using "../temp/factual.dta", nogen keep(3)
	merge m:1 zipcode using "../temp/rents_pred.dta", nogen keep(1 3)
	merge m:1 zipcode using "../temp/income_pred.dta", nogen keep(1 3)
		
	gen actual_mw_cf = actual_mw
	replace actual_mw_cf = fed_mw_cf if (fed_mw_cf >= actual_mw)
	gen ln_mw_cf = log(actual_mw_cf)
	gen d_ln_mw_cf = ln_mw_cf - ln_mw
	gen d_exp_ln_mw_tot_18_cf = exp_ln_mw_tot_18_cf - exp_ln_mw_18
	
	merge m:1 zipcode using "`in_preds'/predictions.dta", ///
	    nogen keep(1 3)
	keep if rural == 0
	keep if zipcode_type == "Zip Code Area"
	
	gen ln_rents_post = p_d_ln_rents + ln_rents
	gen d_rents = exp(ln_rents_post) - exp(ln_rents)
	
	gen d_wagebill = `epsilon_mw'*d_ln_mw_cf + `epsilon_exp_mw'*d_exp_ln_mw_tot_18_cf

	
	
	sabelooooooooo
	
	gen total_rented_space = p_sqft_from_rents*renter_occupied
	gen d_rental_expenditure = total_rented_space*d_rents
	
	gen share_renter_hhlds = renter_occupied/total_households
	
    gen d_ln_wagebill = `epsilon_mw'*d_ln_mw_cf + `epsilon_exp_mw'*d_exp_ln_mw_tot_18_cf
	gen d_wagebill = (exp(d_ln_wagebill)-1)*p_total_wage
	
	gen rho_per_capita = (d_rents*p_sqft_from_rents*share_renter_hhlds) ///
	    /(d_wagebill/renter_occupied)
	
	gen rho = d_rental_expenditure/d_wagebill
	gen rho_alt = d_ln_rents/d_ln_wagebill
	
	gen d_rents_imp = (exp(d_ln_rents)-1)*imp_rent_psqft
	gen total_rented_space_imp = imp_sqft_from_rents*renter_occupied
	gen d_rental_expenditure_imp = total_rented_space_imp*d_rents_imp
	
	gen d_wagebill_imp = (exp(d_ln_wagebill)-1)*imp_total_wage
	
	gen rho_imp = d_rental_expenditure_imp/d_wagebill_imp

	save_data "../output/cfs.dta", key(zipcode counterfactual) replace
end

main
