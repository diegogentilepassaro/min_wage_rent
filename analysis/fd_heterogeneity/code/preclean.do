clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub  "../../../drive/derived_large/estimation_samples"
    local incross "../../../drive/derived_large/zipcode"
    local in_hud "../../../drive/base_large/hud_housing_assistance"
    local outstub "../temp"

    use "`in_hud'/zipcode.dta", clear
    keep if program_label == "Public Housing"
    keep if year == 2017
    keep zipcode total_units
    save_data "../temp/public_housing_2017.dta", key(zipcode) replace log(none)

    load_and_clean, instub(`instub') incross(`incross')

    save_data "`outstub'/fullbal_sample_with_vars_for_het.dta",     ///
        key(zipcode year_month) replace log(none)
end


program load_and_clean
    syntax, instub(str) incross(str)

    use zipcode fullbal_sample_SFCC  ///
        using "`instub'/zipcode_months.dta", clear
	
	keep if fullbal_sample_SFCC == 1
	duplicates drop
	
	tempfile baseline_sample
	save    `baseline_sample'
	
    use zipcode sh_mw_wkrs_statutory med_hhld_inc_acs2014 n_hhlds_cens2010 ///
		using "`incross'/zipcode_cross.dta", clear
	
	merge 1:1 zipcode using `baseline_sample',                 ///
		assert(1 3) keep(3) nogen
	merge 1:1 zipcode using "../temp/public_housing_2017.dta", ///
		assert(1 2 3) keep(1 3) nogen

    replace total_units       = 0 if missing(total_units)
    gen     sh_public_housing = total_units/n_hhlds_cens2010
	
    foreach var in sh_mw_wkrs_statutory med_hhld_inc_acs2014 sh_public_housing {
        egen avg_`var' = mean(`var')
        egen sd_`var'  = sd(`var')
				
        gen std_`var' = (`var' - avg_`var')/sd_`var'
    }
	
	tempfile std_vars
	save    `std_vars'
	
    define_controls
    local controls     "`r(economic_controls)'"

    use zipcode statefips cbsa year_month zipcode_num ln_rents mw_res  ///
        mw_wkp_tot_17 fullbal_sample_SFCC `controls'                   ///
        using "`instub'/zipcode_months.dta", clear
    xtset zipcode_num year_month
		
    merge m:1 zipcode using `std_vars', nogen assert(1 3) keep(3)
end


main
