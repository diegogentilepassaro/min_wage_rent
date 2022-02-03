set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub  "../temp"
    local outstub "../../../drive/base_large/irs_soi"
    local logfile "../output/data_file_manifest.log"

    foreach y in "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" {
        read_excel_files, instub(`instub') yr(`y')
    }

    foreach y in "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" {
    	append using "../temp/irs_zip_`y'.dta"
    }
    
    drop if num_hhlds_irs == 0.0001
    drop if num_hhlds_irs == 0
    collapse (sum) num_hhlds_irs pop_irs adj_gross_inc      ///
        num_wage_hhlds_irs total_wage num_ret_int total_int           ///
        num_ret_div total_div num_bus_hhlds_irs total_bizinc num_farm_hhlds_irs, ///
      by(zipcode statefips year)
    
    create_variables

    save_data "`outstub'/irs_zip.dta", key(zipcode statefips year) log(`logfile') replace
end

program read_excel_files
    syntax, instub(str) yr(str)

    import delimited "`instub'/20`yr'/`yr'zpallagi.csv", clear ///
        stringcols(1 2 3)

    keep statefips zipcode n1 n2 a00100 n00200 a00200 ///
        n00300 a00300 n00600 a00600 n00900 a00900 schf

    rename (n1            n2      a00100        n00200             a00200) ///
           (num_hhlds_irs pop_irs adj_gross_inc num_wage_hhlds_irs total_wage)

    rename (n00300      a00300    n00600      a00600    n00900            a00900       schf) ///
           (num_ret_int total_int num_ret_div total_div num_bus_hhlds_irs total_bizinc num_farm_hhlds_irs)

    gen year = int(`yr') + 2000

    save "../temp/irs_zip_`yr'.dta", replace
    clear
end

program create_variables

    gen agi_per_hhld = adj_gross_inc/num_hhlds_irs
    gen agi_per_cap  = adj_gross_inc/pop_irs

    gen wage_per_wage_hhld = total_wage/num_wage_hhlds_irs
    gen wage_per_hhld      = total_wage/num_hhlds_irs
    gen wage_per_cap       = total_wage/pop_irs

    gen bussines_rev_per_owner = total_bizinc/num_bus_hhlds_irs

    gen share_wage_hhlds      = num_wage_hhlds_irs/num_hhlds_irs
    gen share_bussiness_hhlds = num_bus_hhlds_irs/num_hhlds_irs
    gen share_farmer_hhlds    = num_farm_hhlds_irs/num_hhlds_irs
end

* Execute
main
