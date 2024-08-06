set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado

program main
    local instub  "temp"
    local outstub "../../drive/base_large/irs_soi"
    local logfile "output/data_file_manifest.log"

    foreach y in "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" {
        read_excel_files, instub(`instub') yr(`y')
    }

    foreach y in "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" {
        append using "`instub'/irs_zip_`y'.dta"
    }
    
    collapse (sum) num_hhlds_irs pop_irs adj_gross_inc      ///
        num_wage_hhlds_irs total_wage num_ret_int total_int           ///
        num_ret_div total_div num_bus_hhlds_irs total_bizinc num_farm_hhlds_irs, ///
      by(zipcode statefips year agi_stub)
    
    local reshapevars "zipcode statefips year agi_stub"
    ds `reshapevars', not
    local widevars `r(varlist)'
    
    reshape wide "`widevars'", i(zipcode statefips year) j(agi_stub)

    create_variables

    save_data "`outstub'/irs_by_bracket_zip.dta", key(zipcode statefips year) ///
        log(`logfile') replace
    export delimited "`outstub'/irs_by_bracket_zip.csv", replace
end

program read_excel_files
    syntax, instub(str) yr(str)

    import delimited "`instub'/20`yr'/`yr'zpallagi.csv", clear ///
        stringcols(1 2 3)

    keep statefips zipcode agi_stub n1 n2 a00100 n00200 a00200 ///
        n00300 a00300 n00600 a00600 n00900 a00900 schf

    rename (n1            n2      a00100        n00200             a00200) ///
           (num_hhlds_irs pop_irs adj_gross_inc num_wage_hhlds_irs total_wage)

    rename (n00300      a00300    n00600      a00600    n00900            a00900       schf) ///
           (num_ret_int total_int num_ret_div total_div num_bus_hhlds_irs total_bizinc num_farm_hhlds_irs)

    gen year = int(`yr') + 2000

    save "`instub'/irs_zip_`yr'.dta", replace
    clear
end

program create_variables

    forval i = 1(1)6 {
        gen agi_per_hhld`i' = adj_gross_inc`i'/num_hhlds_irs`i'*1000
        gen agi_per_cap`i'  = adj_gross_inc`i'/pop_irs`i'*1000

        gen wage_per_wage_hhld`i' = total_wage`i'/num_wage_hhlds_irs`i'*1000
        gen wage_per_hhld`i'      = total_wage`i'/num_hhlds_irs`i'*1000
        gen wage_per_cap`i'       = total_wage`i'/pop_irs`i'*1000

        gen bussines_rev_per_owner`i' = total_bizinc`i'/num_bus_hhlds_irs`i'*1000

        gen share_wage_hhlds`i'      = num_wage_hhlds_irs`i'/num_hhlds_irs`i'
        gen share_bussiness_hhlds`i' = num_bus_hhlds_irs`i'/num_hhlds_irs`i'
        gen share_farmer_hhlds`i'    = num_farm_hhlds_irs`i'/num_hhlds_irs`i'

    }
end

* Execute
main
