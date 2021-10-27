clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado

program main
    local instub "../../../drive/derived_large/"

    use "`instub'/zipcode_year/zipcode_year.dta", clear
    xtset zipcode_num year

    add_baseline_zipcodes, instub(`instub')
	
    define_controls
    local controls "`r(economic_controls)'"
    local cluster "statefips"
	local absorb "zipcode year#cbsa10_num"

	reghdfe ln_wagebill ln_mw_avg exp_ln_mw_tot_17_avg `controls' if baseline_sample, ///
        absorb(`absorb', savefe) vce(cluster `cluster') nocons residuals(residuals)
	predict p_ln_wagebill if baseline_sample, xbd
	
	keep zipcode year ln_wagebill p_ln_wagebill residuals
	save_data "../output/twfe_wages_predictions.dta", ///
	    key(zipcode year) replace
end

program add_baseline_zipcodes
    syntax, instub(str)

    preserve
        use `instub'/estimation_samples/baseline_zipcode_months.dta

        keep if !missing(ln_rents)

        keep zipcode year
        bys  zipcode year: keep if _n == 1

        gen baseline_sample = 1

        tempfile zipcode_years_baseline
        save    `zipcode_years_baseline'
    restore

    merge 1:1 zipcode year using `zipcode_years_baseline', assert(1 3) keep(1 3) nogen

    replace baseline_sample = 0 if baseline_sample != 1
end


main
