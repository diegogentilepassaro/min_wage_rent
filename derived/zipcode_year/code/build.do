set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_zip_mth    "../../../drive/derived_large/zipcode_month"
    local in_safmr      "../../../base/safmr/output"
    local in_irs        "../../../drive/base_large/irs_soi"
    local in_lodes_zip  "../../../drive/base_large/lodes_zipcodes"
    local in_qcew       "../../../base/qcew/output"
    local outstub       "../../../drive/derived_large/zipcode_year"
    local logfile       "../output/data_file_manifest.log"

    use zipcode statefips countyfips cbsa year month    ///
        statutory_mw mw_res mw_wkp* medrent* medlisting* Sale_Counts Monthly* ///
        using  "`in_zip_mth'/zipcode_month_panel.dta"

    destring_geographies

    make_yearly_data
    
    clean_safmr_data,  instub(`in_safmr')
    clean_irs_data,    instub(`in_irs')
    clean_area_shares, instub(`in_lodes_zip')    
    clean_qcew,        instub(`in_qcew')
    
    use "../temp/mw_rents_data.dta", clear
    merge 1:1 zipcode    year using "../temp/safmr.dta", nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/irs_data.dta",         nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/workplace_shares.dta", nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/residence_shares.dta", nogen keep(1 3)
    merge m:1 countyfips year using "../temp/qcew_data.dta",        nogen keep(1 3)
    gen ln_wkp_jobs_tot = log(wkp_jobs_tot) 
    gen ln_res_jobs_tot = log(res_jobs_tot)

    save_data "`outstub'/zipcode_year.dta", key(zipcode year) ///
        log(`logfile') replace
end

program destring_geographies

    destring zipcode,    gen(zipcode_num)
    destring statefips,  gen(statefips_num)
    destring cbsa,       gen(cbsa_num)
    destring countyfips, gen(county_num)
end

program make_yearly_data
    gen    day        = 1
    gen    date       = mdy(month, day, year)
    gen    year_month = mofd(date)
    format year_month %tm
    drop   day date

    gen ln_rents        = log(medrentpricepsqft_SFCC)
    gen ln_price        = log(medlistingpricepsqft_SFCC)
    gen ln_sale_counts  = log(Sale_Counts)
    gen ln_monthly_listings = log(Monthlylistings_NSA_SFCC)

    rename *timevary*  *tvar*
    rename *_earn_*    *_e_*
    rename *_age_*     *_a_*
    qui describe mw_wkp*, varlist
    local mw_wkp_vars = r(varlist)

    local vars statutory_mw mw_res ln_rents ln_price ///
        `mw_wkp_vars' ln_sale_counts ln_monthly_listings

    keep zipcode zipcode_num year month year_month countyfips cbsa statefips `vars'
    
    xtset zipcode_num year_month
    
    foreach var of local vars {
        gen d_`var' = D.`var'
    }
    
    xtset, clear
    drop year_month
    foreach var of local vars {
        bys zipcode year: egen `var'_avg   = mean(`var')
        bys zipcode year: egen d_`var'_avg = mean(d_`var')
    }

    bysort zipcode year (month): keep if _n == 7
    drop month
    
    save "../temp/mw_rents_data.dta", replace
end

program clean_safmr_data
    syntax, instub(str)
    
    use "`instub'/safmr_2017_2019_by_zipcode_cbsa.dta", clear
    collapse (mean) safmr*, by(zipcode year)
    qui describe safmr*, varlist
    local safmr_vars = r(varlist)
    foreach var of local safmr_vars {
        gen ln_`var' = log(`var')
    }
    save "../temp/safmr_2017_2019.dta", replace

    use  "`instub'/safmr_2012_2016_by_zipcode_county_cbsa.dta", clear
    collapse (mean) safmr*, by(zipcode year)
    qui describe safmr*, varlist
    local safmr_vars = r(varlist)
    foreach var of local safmr_vars {
        gen ln_`var' = log(`var')
    }
    append using "../temp/safmr_2017_2019.dta"
    save "../temp/safmr.dta", replace
end

program clean_irs_data
    syntax, instub(str)
    
    use "`instub'/irs_zip.dta", clear
    
    gen ln_wagebill     = log(total_wage)
    gen ln_bizinc       = log(total_bizinc)
    gen ln_dividends    = log(total_div)
    gen ln_pop_irs      = log(pop_irs)
    gen ln_n_hhdls      = log(num_hhlds_irs)
    gen ln_n_wage_hhdls = log(num_wage_hhlds_irs)
    
    drop if inlist(zipcode, "0", "00000", "99999") /* I guess these are "other zipcodes", so dropping
                                                      There is one per state, which generates dups */ 

    keep zipcode year ln_* agi_per_hhld wage_per_wage_hhld       ///
        wage_per_hhld bussines_rev_per_owner

    save "../temp/irs_data.dta", replace
end

program clean_area_shares
    syntax, instub(str)

    use "`instub'/jobs.dta", clear
    
    preserve
        keep if jobs_by == "residence"
        
        keep zipcode year jobs_tot jobs_age_under29                     ///
            jobs_earn_under1250 jobs_naics_accomm_food jobs_sch_underHS ///
            share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_*   sh_residents_*
        rename share_earn_*  sh_residents_*
        rename share_naics_* sh_residents_*
        rename share_sch_*   sh_residents_*
        
        rename (jobs_tot      jobs_age_under29     jobs_earn_under1250)     ///
               (res_jobs_tot  res_jobs_age_under29 res_jobs_earn_under1250)
        rename (jobs_naics_accomm_food  jobs_sch_underHS)                   ///
               (res_jobs_naics_ac_food  res_jobs_sch_underHS)
        
        save "../temp/residence_shares.dta", replace
    restore
    
    preserve
        keep if jobs_by == "workplace"
        
        keep zipcode year jobs_tot jobs_age_under29                     ///
            jobs_earn_under1250 jobs_naics_accomm_food jobs_sch_underHS ///
            share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_*   sh_workers_*
        rename share_earn_*  sh_workers_*
        rename share_naics_* sh_workers_*
        rename share_sch_*   sh_workers_*
        
        rename (jobs_tot      jobs_age_under29     jobs_earn_under1250)     ///
               (wkp_jobs_tot  wkp_jobs_age_under29 wkp_jobs_earn_under1250)
        rename (jobs_naics_accomm_food  jobs_sch_underHS)                   ///
               (wkp_jobs_naics_ac_food  wkp_jobs_sch_underHS)
        
        save "../temp/workplace_shares.dta", replace
    restore
end

program clean_qcew
    syntax, instub(str)
    
    use countyfips year month estcount* avgwwage* emp*            ///
       using `instub'/ind_emp_wage_countymonth.dta, clear

    gen    day        = 1
    gen    date       = mdy(month, day, year)
    gen    year_month = mofd(date)
    format year_month %tm
    drop   day date

    destring countyfips, gen(county_num)
    xtset county_num year_month

    foreach var of varlist estcount* avgwwage* emp* {
        gen ln_`var'   = log(`var')
        gen d_ln_`var' = D.ln_`var'
    }

    xtset, clear
    drop year_month
    foreach var of varlist estcount* avgwwage* emp* {
        bys countyfips year: egen ln_`var'_avg   = mean(ln_`var')
        bys countyfips year: egen d_ln_`var'_avg = mean(d_ln_`var')
        drop `var'
    }

    bysort countyfips year (month): keep if _n == 7
    drop month

    save "../temp/qcew_data.dta", replace
end


main
