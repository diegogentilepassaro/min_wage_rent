set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local in_derived_large "../../../drive/derived_large"
    local outstub          "../../../drive/derived_large/zipcode_year"
    local logfile          "../output/data_file_manifest.log"

	use zipcode statefips year month zcta ln_mw actual_mw ///
	    exp_ln_mw ln_med_rent_var acs_pop using ///
		"`in_derived_large'/estimation_samples/all_zipcode_months.dta", clear
	bysort zipcode year: keep if _n == 1
	drop month
	rename (ln_mw actual_mw exp_ln_mw ln_med_rent_var) ///
		(jan_ln_mw jan_actual_mw jan_exp_ln_mw jan_ln_med_rent_var)
    merge 1:1 zipcode statefips year ///
	    using  "../../../base/irs_soi/output/irs_zip.dta", nogen keep(1 3)
	
	gen ln_agi_per_cap            = log(agi_per_cap)
	gen ln_wage_per_cap           = log(wage_per_cap)
	gen ln_wage_per_wage_hhld     = log(wage_per_wage_hhld)
	gen ln_bussines_rev_per_owner = log(bussines_rev_per_owner)
	
    save_data "`outstub'/zipcode_year.dta", key(zipcode year) ///
	    log(`logfile') replace
end

main
