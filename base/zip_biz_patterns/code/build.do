set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local instub  "../temp"
    local outstub "../../../drive/base_large/zip_biz_patterns"
    local logfile "../output/data_file_manifest.log"
	
	* Zip files
    foreach y in "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" {
        read_total_file, instub(`instub') yr(`y')
    }
	use "../temp/zbp_totals_09.dta", clear
    foreach y in "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" {
        append using "../temp/zbp_totals_`y'.dta"
    }
    save_data "`outstub'/zbp_totals.dta", key(zipcode year) ///
        log(`logfile') replace
    export delimited "`outstub'/zbp_totals.csv", replace
	
	* Zip by industry files
	foreach y in "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" {
        read_detail_file, instub(`instub') yr(`y')
    }
	use "../temp/zbp_detail_09.dta", clear
    foreach y in "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" {
        append using "../temp/zbp_detail_`y'.dta"
    }
    save_data "`outstub'/zbp_by_naics.dta", key(zipcode naics6 year) ///
        log(`logfile') replace
    export delimited "`outstub'/zbp_by_naics.csv", replace
end

program read_total_file
    syntax, instub(str) yr(str)

    import delimited "`instub'/zbp`yr'totals.txt", clear ///
        stringcols(1 2)

    cap keep zip name empflag emp ap est
	cap keep zip name emp ap est
	
    rename (zip            name      emp        ap             est) ///
           (zipcode zipname nbr_employees total_annual_payroll nbr_establishments)

    cap replace nbr_employees = . if !missing(empflag)
	cap replace total_annual_payroll = . if !missing(empflag)
	cap drop empflag
	
    gen year = int(`yr') + 2000
	
	create_variables

    save "../temp/zbp_totals_`yr'.dta", replace
    clear
end

program read_detail_file
    syntax, instub(str) yr(str)

    import delimited "`instub'/zbp`yr'detail.txt", clear ///
        stringcols(1 2)

    cap keep zip naics est n1_4 n5_9 n10_19 n20_49 n50_99 n100_249 n250_499 n500_999 n1000
    cap keep zip naics est n5 n5_9 n10_19 n20_49 n50_99 n100_249 n250_499 n500_999 n1000

    rename (zip     naics  est               ) ///
           (zipcode naics6 nbr_establishments)
		   
    cap rename (n1_4 n5_9 n10_19 n20_49 n50_99 n100_249 n250_499 n500_999 n1000) ///
	    (nbr_establishments1_4 nbr_establishments5_9 nbr_establishments10_19 ///
		nbr_establishments20_49 nbr_establishments50_99 nbr_establishments100_249 ///
		nbr_establishments250_499 nbr_establishments500_999 nbr_establishments1000)
    cap rename (n5 n5_9 n10_19 n20_49 n50_99 n100_249 n250_499 n500_999 n1000) ///
	    (nbr_establishments1_4 nbr_establishments5_9 nbr_establishments10_19 ///
		nbr_establishments20_49 nbr_establishments50_99 nbr_establishments100_249 ///
		nbr_establishments250_499 nbr_establishments500_999 nbr_establishments1000)
	
	foreach size in "1_4" "5_9" "10_19" "20_49" "50_99" "100_249" "250_499" "500_999" "1000" {
	    cap destring nbr_establishments`size', replace force
	}
	
    gen year = int(`yr') + 2000
	
    save "../temp/zbp_detail_`yr'.dta", replace
    clear
end

program create_variables
    gen avg_nbr_emp_per_est = nbr_employees/nbr_establishments
    gen avg_payroll_per_emp  = 1000*total_annual_payroll/nbr_employees
end

* Execute
main
