set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub  "../temp"
    local outstub "../../../drive/derived_large/demographics_at_baseline"
    local logfile "../output/data_file_manifest.log"

    * Monthly hours completed in a full time job (ft) are obtained from
    * https://www.irs.gov/affordable-care-act/employers/identifying-full-time-employees
    local mthly_hours_ft = 130 
    local months_in_yr   = 12

    import delimited "`instub'/tract.csv", ///
        stringcols(1) clear
    create_min_max_bins

    bysort tract (bin): gen cumsum_n_workers = sum(n_workers_bin)

    gen ft_statutory_yrly_min = (statutory_mw*`mthly_hours_ft')*`months_in_yr'
    gen ft_state_yrly_min     = (state_mw    *`mthly_hours_ft')*`months_in_yr'
    gen ft_fed_yrly_min       = (fed_mw      *`mthly_hours_ft')*`months_in_yr'
    
    compute_mw_shares, ft_yrly_var(ft_statutory_yrly_min) stub(statutory)
    compute_mw_shares, ft_yrly_var(ft_state_yrly_min)     stub(state)
    compute_mw_shares, ft_yrly_var(ft_fed_yrly_min)       stub(fed)
    
    bysort tract: keep if _n == 1
    drop n_workers_bin cumsum_n_workers bin min_bin max_bin
    
    strcompress
    save_data "`outstub'/tract.dta", key(tract)          ///
        log(`logfile') replace
    export delimited "`outstub'/tract.csv", replace
end

program create_min_max_bins

    rename (n_workers_less_10k_inc n_workers_10to15k_inc n_workers_15to25k_inc  ///
    	    n_workers_25to35k_inc  n_workers_35to50k_inc n_workers_50to65k_inc  ///
    	    n_workers_65to75k_inc  n_workers_more_75k_inc                     ) ///
           (n_workers_bin1         n_workers_bin2        n_workers_bin3         ///
           	n_workers_bin4         n_workers_bin5        n_workers_bin6         ///
           	n_workers_bin7         n_workers_bin8                             )

    reshape long n_workers_bin, i(tract) j(bin)

    gen     min_bin = 0     if bin == 1
    replace min_bin = 10000 if bin == 2
    replace min_bin = 15000 if bin == 3
    replace min_bin = 25000 if bin == 4
    replace min_bin = 35000 if bin == 5
    replace min_bin = 50000 if bin == 6
    replace min_bin = 65000 if bin == 7
    replace min_bin = 75000 if bin == 8
    
    gen     max_bin = 9999.99   if bin == 1
    replace max_bin = 14999.99  if bin == 2
    replace max_bin = 24999.99  if bin == 3
    replace max_bin = 34999.99  if bin == 4
    replace max_bin = 49999.99  if bin == 5
    replace max_bin = 64999.99  if bin == 6
    replace max_bin = 74999.99  if bin == 7
    replace max_bin = 999999999 if bin == 8
end

program compute_mw_shares
    syntax, ft_yrly_var(str) stub(str)
        
    preserve
        gen which_bin = (inrange(`ft_yrly_var', min_bin, max_bin))
        keep if which_bin == 1
        gen sh_bin = (`ft_yrly_var' - min_bin)/(max_bin - min_bin)
    
        gen n_mw_workers_`stub'           = floor(cumsum_n_workers - (1-sh_bin)*n_workers_bin)
        gen share_mw_wkrs_`stub'          = n_mw_workers_`stub'/n_workers
        gen share_mw_wkrs_over_pop_`stub' = n_mw_workers_`stub'/population
        
        keep tract n_mw_workers_`stub' share_mw_wkrs_`stub' share_mw_wkrs_over_pop_`stub'
        save "../temp/mw_workers_`stub'.dta", replace
    restore
    
    merge m:1 tract using "../temp/mw_workers_`stub'.dta", nogen
end


main
