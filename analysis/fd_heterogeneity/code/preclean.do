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
    save_data "`outstub'/public_housing_2017.dta", key(zipcode) replace log(none)

    load_and_clean, instub(`instub') incross(`incross')
    gen high_st_res_mw  = sh_res_underHS_above_stmed*sh_res_under1250_above_stmed
    gen high_st_work_mw = sh_wkrs_underHS_above_stmed*sh_wkrs_under1250_above_stmed

    merge m:1 zipcode using "`outstub'/public_housing_2017.dta",    ///
        nogen keep(1 3)
    gen public_housing = (total_units > 0) if !missing(total_units)
    replace public_housing = 0 if missing(total_units)

    save_data "`outstub'/fullbal_sample_with_vars_for_het.dta",     ///
        key(zipcode year_month) replace log(none)
end


program load_and_clean
    syntax, instub(str) incross(str)

    define_controls
    local controls     "`r(economic_controls)'"

    use zipcode statefips cbsa year_month zipcode_num ln_rents mw_res  ///
        mw_wkp_tot_17 fullbal_sample_SFCC `controls'                   ///
        using "`instub'/zipcode_months.dta" if fullbal_sample_SFCC == 1, clear
    drop fullbal_sample_SFCC
    xtset zipcode_num year_month

    merge m:1 zipcode using "`incross'/zipcode_cross.dta", nogen       ///
        keep(3) keepusing(sh_mw_wkrs_statutory sh_workers_under29_2014 ///
            sh_residents_under29_2014 sh_residents_underHS_2014        ///
            sh_residents_under1250_2014 sh_workers_underHS_2014        ///
            sh_workers_under1250_2014 sh_residents_accomm_food_2014    ///
            sh_workers_accomm_food_2014)
    rename *_2014 *
    rename *residents* *res*
    rename *workers* *wkrs*

    foreach var in sh_mw_wkrs_statutory ///
	               sh_wkrs_accomm_food sh_res_accomm_food    ///
                   sh_wkrs_underHS sh_res_underHS  ///
                   sh_wkrs_under1250 sh_res_under1250 ///
				   sh_wkrs_under29 sh_res_under29 {
        egen `var'_med = median(`var')
        gen `var'_above_med = (`var'   > `var'_med)
        drop `var'_med

        bys statefips: egen `var'_stmed = median(`var')
        gen `var'_above_stmed = (`var'   > `var'_stmed)
        drop `var'_stmed

        bys cbsa: egen `var'_cbmed = median(`var')
        gen `var'_above_cbmed = (`var'   > `var'_cbmed)
        drop `var'_cbmed
    }
end


main
