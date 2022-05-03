clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local in_est      "../../../drive/derived_large/estimation_samples"
    local in_zip_yr   "../../../drive/derived_large/zipcode_year"
    local in_cty_yr   "../../../drive/derived_large/county_year"

    local outstub "../output"

    define_controls
    local controls "`r(economic_controls)'"
    local cluster = "statefips"
	
    local mw_wkp_var "mw_wkp_tot_17"
	
	** STATIC
	local absorb = "year_month"
    estimates_geo_month, in_est(`in_est') geo(zipcode) geo_name(zipcode)   ///
	    mw_wkp_var(`mw_wkp_var') controls(`controls')                      ///
		absorb(`absorb') cluster(`cluster')
		
    estimates_geo_month, in_est(`in_est') geo(county) geo_name(countyfips) ///
	    mw_wkp_var(`mw_wkp_var') controls(`controls')                      ///
		absorb(`absorb') cluster(`cluster')	
		
    local absorb     "year"
    local mw_wkp_var "d_mw_wkp_tot_17_avg"

    define_controls
    local d_controls "`r(d_economic_controls)'"

	estimates_geo_year, instub(`in_zip_yr') in_est(`in_est')                 ///
	    geo(zipcode) geo_name(zipcode)                                       ///
	    mw_wkp_var(`mw_wkp_var') controls(`d_controls')                      ///
		absorb(`absorb') cluster(`cluster')
		
	clear
	foreach stub in "" "yr_" {
        local geos county zipcode
        if "`stub'"=="yr_" local geos zipcode
         foreach geo of local geos {
	         foreach ff in `geo'_`stub'static_mw_res `geo'_`stub'static_mw_wkp ///
		        `geo'_`stub'static_both `geo'_`stub'mw_wkp_on_res_mw {
                append using ../temp/estimates_`ff'.dta
            }
	    }	
	}
    save             `outstub'/estimates_static.dta, replace
    export delimited `outstub'/estimates_static.csv, replace
	
    ** DYNAMIC
	local absorb     "year_month"
    local mw_wkp_var "mw_wkp_tot_17"

    use "`in_est'/county_months.dta" if fullbal_sample_SFCC, clear
    xtset county_num `absorb'

    estimate_dist_lag_model, depvar(ln_rents)                       ///
        dyn_var(`mw_wkp_var') w(6) stat_var(mw_res)                 ///
        controls(`controls') absorb(`absorb') cluster(`cluster')    ///
        model_name(county_both_mw_wkp_dynamic) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents)                       ///
        dyn_var(mw_res) w(6) stat_var(`mw_wkp_var')                 ///
        controls(`controls') absorb(`absorb') cluster(`cluster')    ///
        model_name(county_both_mw_res_dynamic) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents)                       ///
        dyn_var(`mw_wkp_var') w(6) stat_var(`mw_wkp_var')           ///
        controls(`controls') absorb(`absorb') cluster(`cluster')    ///
        model_name(county_mw_wkp_only_dynamic) outfolder("../temp")
        
    estimate_dist_lag_model, depvar(ln_rents)                        ///
        dyn_var(mw_res) w(6) stat_var(mw_res)                        ///
        controls(`controls') absorb(`absorb') cluster(`cluster')     ///
        model_name(county_mw_res_only_dynamic) outfolder("../temp")
        
    estimate_dist_lag_model_two_dyn, depvar(ln_rents)                ///
        dyn_var1(`mw_wkp_var') w(6) dyn_var2(mw_res)                 ///
        controls(`controls') absorb(`absorb') cluster(`cluster')     ///
        model_name(county_both_dynamic) outfolder("../temp")
        
    use ../temp/estimates_county_both_mw_wkp_dynamic.dta, clear
    foreach ff in county_both_mw_res_dynamic county_mw_wkp_only_dynamic ///
        county_mw_res_only_dynamic county_both_dynamic {
        append using ../temp/estimates_`ff'.dta
    }
    save             `outstub'/estimates_dynamic.dta, replace
    export delimited `outstub'/estimates_dynamic.csv, replace
end

program estimates_geo_month
    syntax, in_est(str) geo(str) geo_name(str) mw_wkp_var(str) ///
	    controls(str) absorb(str) cluster(str)

    use "`in_est'/`geo'_months.dta" if fullbal_sample_SFCC == 1, clear
    xtset `geo'_num year_month

    estimate_dist_lag_model if !missing(D.ln_rents), depvar(`mw_wkp_var') ///
        dyn_var(mw_res) w(0) stat_var(mw_res)                      ///
        controls(`controls') absorb(`absorb') cluster(`cluster')   ///
        model_name(`geo'_mw_wkp_on_res_mw)

    estimate_dist_lag_model, depvar(ln_rents)                      ///
        dyn_var(mw_res) w(0) stat_var(mw_res)                      ///
        controls(`controls') absorb(`absorb') cluster(`cluster')   ///
        model_name(`geo'_static_mw_res)

    estimate_dist_lag_model, depvar(ln_rents)                      ///
        dyn_var(`mw_wkp_var') w(0) stat_var(`mw_wkp_var')          ///
        controls(`controls') absorb(`absorb') cluster(`cluster')   ///
        model_name(`geo'_static_mw_wkp)

    estimate_dist_lag_model, depvar(ln_rents)                      ///
        dyn_var(`mw_wkp_var') w(0) stat_var(mw_res)                ///
        controls(`controls') absorb(`absorb') cluster(`cluster')   ///
        model_name(`geo'_static_both) test_equality
end

program estimates_geo_year
    syntax, instub(str) in_est(str) geo(str) geo_name(str) ///
	    mw_wkp_var(str) controls(str) absorb(str) cluster(str)

    use "`instub'/`geo'_year.dta", clear
	get_sample_flags, instub(`in_est') geo(`geo') ///
	    geo_name(`geo_name') time(year)
    xtset `geo'_num year

    estimate_stacked_model if fullbal_sample_SFCC == 1 & !missing(d_ln_rents_avg), ///
	    depvar(`mw_wkp_var')                                               ///
        mw_var1(d_mw_res_avg) mw_var2(d_mw_res_avg)                        ///
        controls(`controls') absorb(`absorb') cluster(`cluster')           ///
        model_name(`geo'_yr_mw_wkp_on_res_mw)

    estimate_stacked_model if fullbal_sample_SFCC == 1, depvar(d_ln_rents_avg) ///
        mw_var1(d_mw_res_avg) mw_var2(d_mw_res_avg)                        ///
        controls(`controls') absorb(`absorb') cluster(`cluster')           ///
        model_name(`geo'_yr_static_mw_res)

    estimate_stacked_model if fullbal_sample_SFCC == 1, depvar(d_ln_rents_avg) ///
        mw_var1(`mw_wkp_var') mw_var2(`mw_wkp_var')                        ///
        controls(`controls') absorb(`absorb') cluster(`cluster')           ///
        model_name(`geo'_yr_static_mw_wkp)

    estimate_stacked_model if fullbal_sample_SFCC == 1, depvar(d_ln_rents_avg) ///
        mw_var1(`mw_wkp_var') mw_var2(d_mw_res_avg)                        ///
        controls(`controls') absorb(`absorb') cluster(`cluster')           ///
        model_name(`geo'_yr_static_both)
end

program get_sample_flags
    syntax, instub(str) geo(str) geo_name(str) time(str)
	
	preserve
	    use `geo_name' year_month `time' fullbal_sample_SFCC ///
		    using "`instub'/`geo'_months.dta", clear
		bysort `geo_name' `time' (year_month): keep if _n == 7
		drop year_month
		save "../temp/sample_flags.dta", replace
	restore
	
	merge 1:1 `geo_name' `time' using "../temp/sample_flags.dta", ///
	    nogen keep(1 3)
end

main
