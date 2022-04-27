clear all
set more off

program main
    load_data
    create_vars

    xtset zipcode_num year
    save ../output/panel.dta, replace

    estimate_SAFMR
    esttab * using "../output/test.txt", se
end


program load_data

    use  ../../base/safmr/output/safmr_2017_2019_by_zipcode_cbsa.dta

    collapse (mean) safmr*, by(zipcode year)

    save ../output/safmr_2017_2019.dta, replace


    use  ../../base/safmr/output/safmr_2012_2016_by_zipcode_county_cbsa.dta, clear

    collapse (mean) safmr*, by(zipcode year)

    append using ../output/safmr_2017_2019.dta

    save ../output/safmr.dta, replace


    use zipcode year zipcode_num countyfips statefips cbsa ///
        mw_wkp_tot_* mw_res /// 
        using ../../drive/derived_large/zipcode_year/zipcode_year.dta

    merge 1:1 zipcode year using ../output/safmr.dta, keep(3) nogen 
end

program create_vars
    destring cbsa, gen(cbsa_num)

    forval i = 0(1)4 {
        gen ln_rents_`i'br = log(safmr`i'br)
    }

    replace mw_wkp_tot_tvar_avg = mw_wkp_tot_18_avg if year == 2019
end

program estimate_SAFMR

    forval i = 0(1)4 {
        reghdfe ln_rents_`i'br mw_wkp_tot_16_avg mw_res, ///
            absorb(zipcode cbsa_num##year) cluster(cbsa_num) nocons
        est store safrm`i'br
    }
end


main
