clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 


program main 
	local instub "../../../drive/raw_data/bps"
	local outsub "../output"

	forval y = 10/19 {
		foreach m in 01 02 03 04 05 06 07 08 09 10 11 12 {
			import delim `instub'/co`y'`m'y.txt, clear rowr(4:) varnames(2)
			colnames
			save ../temp/co`y'`m'.dta, replace 
		}
	}
	clear
	forval y = 10/19 {
		foreach m in 01 02 03 04 05 06 07 08 09 10 11 12 {
			append using ../temp/co`y'`m'.dta
		}
	}

	format_clean_vars

	save_data `outsub'/bps_sf_cty_mon.dta, replace key(countyfips year_month)


end 

program colnames 
	rename (date       state     county     code        v5            name) ///
		   (strdate statefips cfips region_code division_code countyname)
	

	rename (bldgs    units    value    v10      v11      v12      v13      v14      v15      v16      v17      v18) ///
		   (u1_bldgs u1_units u1_value u2_bldgs u2_units u2_value u3_bldgs u3_units u3_value u5_bldgs u5_units u5_value)

   	rename (v19 v20 v21 v22 v23 v24 v25 v26 v27 v28 v29 v30) ///
   	       (u1rep_bldgs u1rep_units u1rep_value u2rep_bldgs u2rep_units u2rep_value u3rep_bldgs u3rep_units u3rep_value u5rep_bldgs u5rep_units u5rep_value)

end 

program format_clean_vars 
	
	drop region_code division_code countyname

	g year = substr(strdate, 1, 4)
	g mon  = substr(strdate, 5, 6)
	destring year mon, replace
	g year_month = ym(year, mon)
	format year_month %tm
	order year_month, first
	drop strdate

	g countyfips = string(statefips) + string(cfips, "%03.0f")
	destring countyfips, replace 
	order countyfips, before(cfips)
	drop cfips

	duplicates drop countyfips year_month, force

	xtset countyfips year_month

	g invmon = - mon 
	unab cumvar_list: u* 
	foreach var in `cumvar_list' {
		bys countyfips year (invmon): replace `var' = `var' - `var'[_n+1] if _n<12 
	}

	sort countyfips year_month
	drop year mon invmon

	unab final_varlist: u1*
	keep year_month statefips countyfips `final_varlist'

end 








*EXECUTE
main 