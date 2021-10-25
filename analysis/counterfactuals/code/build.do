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
	local in_est      "../../fd_baseline/output"
	local in_income   "../../twfe_wages/output"
	
	use "`in_income'/estimates_all.dta", clear
	keep if model == "cbsa_time_baseline"
    sum b
	local epsilon = r(mean)
	
	use "`in_est'/estimates_static.dta", clear
	keep if model == "static_both"
    sum b if var == "ln_mw"
	local gamma = r(mean)
    sum b if var == "exp_ln_mw_17"
	local beta = r(mean)
	
	use zipcode year month counterfactual exp_ln_mw_tot using ///
	    "`in_cf_mw'/zipcode_experienced_mw_cfs.dta", clear
    keep if (year == 2020 & month == 1)
	rename exp_ln_mw_tot exp_ln_mw_tot_18_cf
	gen fed_mw_cf = 7.25*1.1 if counterfactual == "fed_10pc"
	replace fed_mw_cf = 15 if counterfactual == "fed_15usd"
	replace fed_mw_cf = 9 if counterfactual == "fed_9usd"
	save "../temp/counterfactual.dta", replace

	use zipcode zcta statefips state_abb year month ///
	    actual_mw ln_mw exp_ln_mw_18 ///
	    using "`in_sample'/all_zipcode_months.dta", clear
    keep if (year == 2019 & month == 12)
	save "../temp/factual.dta", replace
	
	use "../temp/counterfactual.dta", clear
	merge m:1 zipcode using "../temp/factual.dta", nogen keep(3)
	
	gen actual_mw_cf = actual_mw
	replace actual_mw_cf = fed_mw_cf if (fed_mw_cf >= actual_mw)
	gen ln_mw_cf = log(actual_mw_cf)
	gen d_ln_mw_cf = ln_mw_cf - ln_mw
	gen d_exp_ln_mw_tot_18_cf = exp_ln_mw_tot_18_cf - exp_ln_mw_18
	gen d_ln_rents = `gamma'*d_ln_mw_cf + `beta'*d_exp_ln_mw_tot_18_cf
	
	merge m:1 zipcode using "`in_preds'/predictions.dta", ///
	    nogen keep(1 3)
	keep if rural == 0
	keep if zipcode_type == "Zip Code Area"
	
	gen d_rents = (exp(d_ln_rents)-1)*rent_psqft
	gen total_rented_space = sqft_from_rents*renter_occupied
	gen d_rental_expenditure = total_rented_space*d_rents
	
    gen d_ln_wagebill = `epsilon'*d_exp_ln_mw_tot_18_cf
	gen d_wagebill = (exp(d_ln_wagebill)-1)*total_wage
	
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
