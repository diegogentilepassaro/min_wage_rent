clear all
set more off

program main
    load_data
    *estimate_SAFMR
    save ../output/panel.dta
end


program load_data

    use  ../../base/safmr/output/safmr_2017_2019_by_zipcode_cbsa.dta

    collapse (mean) safmr*, by(zipcode year)

    save ../output/safmr_2017_2019.dta


    use  ../../base/safmr/output/safmr_2012_2016_by_zipcode_county_cbsa.dta, clear

    collapse (mean) safmr*, by(zipcode year)

    append using ../output/safmr_2017_2019.dta

    save ../output/safmr.dta


    use zipcode year zipcode_num countyfips statefips cbsa ///
        mw_wkp_tot_* mw_res /// 
        using ../../drive/derived_large/zipcode_year/zipcode_year.dta

    merge 1:1 zipcode year using ../output/safmr.dta, keep(3) nogen 
end

main
