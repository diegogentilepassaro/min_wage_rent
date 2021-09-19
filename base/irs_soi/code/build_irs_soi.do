set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub "../temp"

    foreach y in "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" {
        read_excel_files, instub(`instub') yr(`y')
    }

    foreach y in "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" {
    	append using "../temp/irs_zip_`y'.dta"
    }
    	
    drop if num_ret == 0.0001
    drop if num_ret == 0
    collapse (sum) num_ret num_exemp num_dep adj_gross_inc      ///
        num_ret_wage total_wage num_ret_int total_int           ///
        num_ret_div total_div num_ret_bus tot_bus num_ret_farm, ///
      by(zipcode statefips year)
    
    create_variables

    save_data "../output/irs_zip.dta", key(zipcode statefips year) replace
end

program read_excel_files
    syntax, instub(str) yr(str)

    import delimited "`instub'/20`yr'/`yr'zpallagi.csv", clear ///
        stringcols(1 2 3)

    keep statefips zipcode n1 n2 numdep a00100 n00200 a00200 ///
        n00300 a00300 n00600 a00600 n00900 a00900 schf

    rename (n1      n2        numdep  a00100        n00200       a00200) ///
           (num_ret num_exemp num_dep adj_gross_inc num_ret_wage total_wage)

    rename (n00300      a00300    n00600      a00600    n00900      a00900  schf) ///
           (num_ret_int total_int num_ret_div total_div num_ret_bus tot_bus num_ret_farm)

    gen year = int(`yr') + 2000

    save "../temp/irs_zip_`yr'.dta", replace
    clear
end

program create_variables

    gen agi_per_hhld = adj_gross_inc/num_ret
    gen agi_per_cap  = adj_gross_inc/num_exemp

    gen wage_per_worker = total_wage/num_ret_wage
    gen wage_per_hhld   = total_wage/num_ret
    gen wage_per_cap    = total_wage/num_exemp

    gen bussines_rev_per_owner = tot_bus/num_ret_bus

    gen share_wage_hhlds      = num_ret_wage/num_ret
    gen share_bussiness_hhlds = num_ret_bus/num_ret
    gen share_farmer_hhlds    = num_ret_farm/num_ret
end

* Execute
main
