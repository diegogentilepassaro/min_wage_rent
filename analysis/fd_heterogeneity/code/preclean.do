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

    merge m:1 zipcode using "`outstub'/public_housing_2017.dta",    ///
        nogen keep(1 3)
    gen public_housing = (total_units > 0) if !missing(total_units)
    replace public_housing = 0 if missing(total_units)
	gen sh_public_housing = total_units/n_hhlds_cens2010
    replace sh_public_housing = 0 if missing(total_units)
	qui sum sh_public_housing
	local avg_sh_public_housing = r(mean)
	local sd_sh_public_housing = r(sd)
	gen std_sh_public_housing = (sh_public_housing - `avg_sh_public_housing')/`sd_sh_public_housing'
		
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
        keep(3) keepusing(sh_mw_wkrs_statutory med_hhld_inc_acs2014 n_hhlds_cens2010)

    foreach var in sh_mw_wkrs_statutory med_hhld_inc_acs2014 {
	    qui sum `var'
        local avg_`var' = r(mean)
        local sd_`var' = r(sd)
        gen std_`var' = (`var' - `avg_`var'')/`sd_`var''
    }
end


main
