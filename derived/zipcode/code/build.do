set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_geo        "../../../drive/base_large/zipcode_master"
    local in_zillow     "../../../drive/base_large/zillow"
    local in_lodes_zip  "../../../drive/base_large/lodes_zipcodes"
    local in_demo       "../../../drive/derived_large/demographics_at_baseline"
    local in_shares_od  "../../../drive/derived_large/od_shares"
    local outstub       "../../../drive/derived_large/zipcode"
    local logfile       "../output/data_file_manifest.log"

    build_zillow_zipcode_stats, instub(`in_zillow')

    use `in_geo'/zipcode_master.dta, clear

    merge 1:1 zipcode using "../temp/zillow_zipcodes_with_rents.dta"
    drop if _merge == 2 // 6 observations from using
    drop _merge

    merge 1:1 zipcode using "`in_demo'/zipcode.dta", ///
        nogen keep(1 3)

    merge_lodes_shares, instub(`in_lodes_zip')
    merge_lodes_shares, instub(`in_lodes_zip') yy(2017)
    merge_od_shares,    instub(`in_shares_od')

    strcompress
    save_data "`outstub'/zipcode_cross.dta",                                  ///
        key(zipcode) log(`logfile') replace
    export delimited "`outstub'/zipcode_cross.csv", replace
end

program build_zillow_zipcode_stats
    syntax, instub(str)

    use "`instub'/zillow_zipcode_clean.dta"

    keep if !missing(medrentpricepsqft_SFCC)
    collapse (count) n_months_zillow_rents = medrentpricepsqft_SFCC, by(zipcode)
    tostring zipcode, format(%05.0f) replace

    save "../temp/zillow_zipcodes_with_rents.dta", replace
end

program merge_lodes_shares
    syntax, instub(str) [yy(int 2013)]

    preserve
        use "`instub'/jobs.dta" if jobs_by == "residence" & year == `yy', clear
        
        keep zipcode share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_* sh_residents_*_`yy'
        rename share_earn_* sh_residents_*_`yy'
        rename share_naics_* sh_residents_*_`yy'
        rename share_sch_* sh_residents_*_`yy'
        
        save "../temp/residents_shares.dta", replace
    restore
    
    preserve
        use "`instub'/jobs.dta" if jobs_by == "workplace" & year == `yy', clear
        
        keep zipcode share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_* sh_workers_*_`yy'
        rename share_earn_* sh_workers_*_`yy'
        rename share_naics_* sh_workers_*_`yy'
        rename share_sch_* sh_workers_*_`yy'
        
        save "../temp/workers_shares.dta", replace
    restore

    merge 1:1 zipcode using "../temp/residents_shares.dta", nogen keep(1 3)
    merge 1:1 zipcode using "../temp/workers_shares.dta", nogen keep(1 3)
end

program merge_od_shares
    syntax, instub(str)

    foreach yy in 2013 2017 {
        preserve
            clear
            import delimited "`instub'/zipcode_shares.csv", stringcols(1)

            keep if year == `yy'

            keep zipcode sh_*
            rename sh_workers_*      sh_od_workers_*_`yy'
            rename sh_residents_*    sh_od_residents_*_`yy'
            rename sh_work_samegeo_* sh_od_work_samegeo_*_`yy'

            save "../temp/od_shares_`yy'.dta"
        restore
    }
    merge 1:1 zipcode using "../temp/od_shares_2013.dta", nogen keep(1 3)
    merge 1:1 zipcode using "../temp/od_shares_2017.dta", nogen keep(1 3)
end


main
