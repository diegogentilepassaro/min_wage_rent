set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    foreach y in "09" "10" "11" "12" "13" ///
	    "14" "15" "16" "17" "18" {
		    read_excel_files, yr(`y')
		}
	use "../temp/irs_zip_09.dta", clear
    foreach y in "10" "11" "12" "13" ///
	    "14" "15" "16" "17" "18" {
		    append using "../temp/irs_zip_`y'.dta"
		}
	save_data "../output/irs_zip.dta", key(zipcode year) clear
end

program read_excel_files
	syntax, yr(str)

	import delimited "../temp/20`yr'/`yr'zpallagi.csv", clear ///
	    stringcols(1 2 3)
	keep statefips zipcode n1 n2 numdep a00100 n00200 a00200 ///
	    n00300 a00300 n00600 a00600 n00900 a00900 schf
    rename (n1 n2 numdep a00100 n00200 a00200 ///
	    n00300 a00300 n00600 a00600 n00900 a00900 schf) ///
		(num_ret num_exemp num_dep agi num_ret_wage total_wage ///
		num_ret_int total_int num_ret_div total_div num_ret_bus tot_bus num_ret_farm)
	gen year = int(`yr') + 2000
	save "../temp/irs_zip_`yr'.dta", replace
end

* Execute
main
