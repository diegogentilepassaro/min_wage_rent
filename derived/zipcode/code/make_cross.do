set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_frame      "../../../drive/derived_large/zipcode"
    local in_base_large "../../../drive/base_large"
    local in_der_large  "../../../drive/derived_large"
    local outstub       "../../../drive/derived_large/zipcode"
    local logfile       "../output/data_file_manifest.log"

    build_zillow_zipcode_stats, instub(`in_base_large')

    use `in_frame'/zipcode_frame.dta

    merge 1:1 zipcode using "../temp/zillow_zipcodes_with_rents.dta",         ///
        nogen assert(1 3)

    *merge 1:1 zipcode using "`in_base_large'/demographics/zip_demo_2010.dta", ///
    *    nogen keep(1 3)
    ** SHOULD WE DROP THE OLD base/demographics?

    *merge_lodes_shares, instub(`in_base_large')
    *merge_lodes_shares, instub(`in_base_large') yy(2017)
    *merge_od_shares,    instub(`in_der_large')

    strcompress
    save_data "`outstub'/zipcode_cross.dta",                                  ///
        key(zipcode) log(`logfile') replace
    export delimited "`outstub'/zipcode_cross.csv", replace
end

program build_zillow_zipcode_stats
    syntax, instub(str)

    use "`instub'/zillow/zillow_zipcode_clean.dta"

    keep if !missing(medrentpricepsqft_SFCC)
    collapse (count) n_months_zillow_rents = medrentpricepsqft_SFCC, by(zipcode)
    tostring zipcode, format(%05.0f) replace

    save "../temp/zillow_zipcodes_with_rents.dta", replace
end

program merge_lodes_shares
    syntax, instub(str) [yy(int 2014)]

    preserve
        use "`instub'/lodes_zipcodes/jobs.dta" if jobs_by == "residence" & year == `yy', clear
        
        keep zipcode share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_* sh_residents_*_`yy'
        rename share_earn_* sh_residents_*_`yy'
        rename share_naics_* sh_residents_*_`yy'
        rename share_sch_* sh_residents_*_`yy'
        
        save "../temp/residents_shares.dta", replace
    restore
    
    preserve
        use "`instub'/lodes_zipcodes/jobs.dta" if jobs_by == "workplace" & year == `yy', clear
        
        keep zipcode share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_* sh_workers_*_`yy'
        rename share_earn_* sh_workers_*_`yy'
        rename share_naics_* sh_workers_*_`yy'
        rename share_sch_* sh_workers_*_`yy'
        
        save "../temp/workers_shares.dta", replace
    restore

    merge 1:1 zipcode using "../temp/residents_shares.dta", nogen
    merge 1:1 zipcode using "../temp/workers_shares.dta", nogen
end

program merge_od_shares
    syntax, instub(str)

    foreach yy in 2014 2017 {
        preserve
            clear
            import delimited "`instub'/shares/zipcode_shares.csv", stringcols(1)

            keep if year == `yy'

            keep zipcode share_*
            rename share_workers_*      sh_workers_od_*_`yy'
            rename share_residents_*    sh_residents_od_*_`yy'
            rename share_work_samegeo_* sh_work_samegeo_od_*_`yy'

            save "../temp/od_shares_`yy'.dta"
        restore
    }
    merge 1:1 zipcode using "../temp/od_shares_2014.dta", nogen
    merge 1:1 zipcode using "../temp/od_shares_2017.dta", nogen
end


main
