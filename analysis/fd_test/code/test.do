clear all
set more off

program main
    local instub  "../../../drive/derived_large/estimation_samples"
    local outstub "../output"

    #delimit ;
    local keep_vars 
       "zipcode_num year_month fullbal_sample_SFCC 
        county_num cbsa_num statefips_num 
        ln_rents mw_wkp_tot_17 mw_res ln_emp* ln_estc* ln_avg* ";
    #delimit cr
    
    use `keep_vars' using `instub'/zipcode_months.dta, clear
    keep if fullbal_sample_SFCC == 1
    drop fullbal_sample_SFCC
    
    gen state_model = 0
    tempfile baseline_data
    save    `baseline_data', replace
    
    replace state_model = 1
    append using `baseline_data'
    
    gen zip_model = state_model*1e7 + zipcode_num
    
    xtset zip_model year_month
    
    gen state_num = statefips_num
    replace state_num = 10000 if state_model == 0
    
    gen d_mw_wkp = D.mw_wkp_tot_17
    gen d_mw_res = D.mw_res
    
    reghdfe D.ln_rents ///
      c.d_mw_wkp##i.state_model c.d_mw_res##state_model ///
      c.D.(ln_emp*)##state_model c.D.(ln_avg*)##state_model c.D.(ln_est*)##state_model, ///
      absorb(state_num##year_month) nocons ///
      cluster(statefips_num##state_model)
    
    // beta^base : effect in baseline model
    // beta^st : effect in model with state-by-time FE
    // 
    // d_mw_wkp               estimates beta^base
    // d_mw_wkp#1.state_model estimates beta^st - beta^base
    // We want to test equality of coefficients, or `beta^st - beta^base`, so the below is enough!
    lincomest d_mw_wkp#1.state_model
    
    mat test_wkp_coef = e(b)
    mat test_wkp_var = e(V)
    mat test_wkp_se = test_wkp_var[1,1]^.5
    
    local test_wkp_t    = test_wkp_coef[1,1]/test_wkp_se[1,1]
    local test_wkp_pval = 2*normal(`test_wkp_t')
    
    reghdfe D.ln_rents ///
      c.d_mw_wkp##i.state_model c.d_mw_res##state_model ///
      c.D.(ln_emp*)##state_model c.D.(ln_avg*)##state_model c.D.(ln_est*)##state_model, ///
      absorb(state_num##year_month) nocons ///
      cluster(statefips_num##state_model)
    
    // Now we test for residence MW, i.e.,
    // `gamma^st - gamma^base`
    lincomest d_mw_res#1.state_model
    
    mat test_res_coef = e(b)
    mat test_res_var = e(V)
    mat test_res_se = test_res_var[1,1]^.5
    
    local test_res_t    = test_res_coef[1,1]/test_res_se[1,1]
    local test_res_pval = 2*(1-normal(`test_res_t'))
    
    // Strictly speaking the lincomest is not necessary. Leaving it to be clear on the intention!
    
    
    file open f using "`outstub'/test_stateFE.txt", write replace
    file write f "<tab:test_stateFE>" _n

    file write f    (test_wkp_coef[1,1]) _tab (test_wkp_se[1,1]) ///
               _tab (`test_wkp_t')  _tab  (`test_wkp_pval') _n
    file write f    (test_res_coef[1,1]) _tab (test_res_se[1,1]) ///
               _tab (`test_res_t')  _tab  (`test_res_pval') _n
    
    file close f
end


main
