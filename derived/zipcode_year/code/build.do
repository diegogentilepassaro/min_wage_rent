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

    make_yearly_data

	clean_safmr_data,  instub(`in_safmr')
    clean_irs_data,    instub(`in_irs')
    clean_area_shares, instub(`in_lodes_zip')
    clean_qcew,        instub(`in_qcew')

    use "../temp/mw_rents_data.dta", clear
    merge 1:1 zipcode countyfips cbsa year ///
	    using "../temp/safmr_2012_2016.dta", nogen keep(1 3)
    merge 1:1 zipcode cbsa year ///
	    using "../temp/safmr_2017_2019.dta", nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/irs_data.dta",         nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/workplace_shares.dta", nogen keep(1 3)
    merge 1:1 zipcode    year using "../temp/residence_shares.dta", nogen keep(1 3)
    merge m:1 countyfips year using "../temp/qcew_data.dta",        nogen keep(1 3)

    destring_geographies

    save_data "`outstub'/zipcode_year.dta", key(zipcode year) ///
        log(`logfile') replace
end

program make_yearly_data

    gen ln_rents        = log(medrentprice_SFCC)
    gen ln_price        = log(medlistingpricepsqft_SFCC)
    gen ln_sale_counts  = log(Sale_Counts)
    gen ln_monthly_listings = log(Monthlylistings_NSA_SFCC)

    rename *timevary* *timvar* 
    qui describe mw_wkp*, varlist
    local mw_wkp_vars = r(varlist)

    local vars statutory_mw mw_res ln_rents ln_price ///
	    `mw_wkp_vars' ln_sale_counts ln_monthly_listings

    keep zipcode year countyfips cbsa statefips month `vars'
	
    foreach var of local vars {
        bys zipcode year: egen `var'_avg = mean(`var')
    }

    bysort zipcode year (month): keep if _n == 1
    drop month
    
    save "../temp/mw_rents_data.dta", replace
end

program clean_safmr_data
    syntax, instub(str)
    
    use "`instub'/safmr_2012_2016_by_zipcode_county_cbsa.dta", clear
	qui describe safmr*, varlist
    local safmr_vars = r(varlist)
    foreach var of local safmr_vars {
        gen ln_`var' = log(`var')
	}
    save "../temp/safmr_2012_2016.dta", replace
	
    use "`instub'/safmr_2017_2019_by_zipcode_cbsa.dta", clear
	qui describe safmr*, varlist
    local safmr_vars = r(varlist)
    foreach var of local safmr_vars {
        gen ln_`var' = log(`var')
	}
    save "../temp/safmr_2017_2019.dta", replace
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

    keep zipcode year ln_*

    save "../temp/irs_data.dta", replace
end

program clean_area_shares
    syntax, instub(str)

    use "`instub'/jobs.dta", clear
    preserve
        keep if jobs_by == "residence"
        
        keep zipcode year share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_*   sh_residents_*
        rename share_earn_*  sh_residents_*
        rename share_naics_* sh_residents_*
        rename share_sch_*   sh_residents_*
        
        save "../temp/residence_shares.dta", replace
    restore
    
    preserve
        keep if jobs_by == "workplace"
        
        keep zipcode year share_age_* share_earn_* share_naics_* share_sch_*
        rename share_age_*   sh_workers_*
        rename share_earn_*  sh_workers_*
        rename share_naics_* sh_workers_*
        rename share_sch_*   sh_workers_*
        
        save "../temp/workplace_shares.dta", replace
    restore
end

program clean_qcew
    syntax, instub(str)
    
    use countyfips year estcount* avgwwage* emp*            ///
       using `instub'/ind_emp_wage_countymonth.dta, clear

    foreach var of varlist estcount* avgwwage* emp* {
        gen ln_`var' = log(`var')
        drop `var'
    }

    collapse (mean) ln_*, by(countyfips year)
	rename ln_* ln_*_avg

    save "../temp/qcew_data.dta", replace
end

program destring_geographies

    destring statefips, gen(statefips_num)
    destring cbsa, gen(cbsa_num)
    destring countyfips, gen(county_num)
    destring zipcode, gen(zipcode_num)
end


main
