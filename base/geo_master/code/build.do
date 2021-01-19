set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    import excel "../../../raw/crosswalk/zip_to_zcta_2019.xlsx", ///
	    sheet("ZiptoZCTA_crosswalk") firstrow allstring clear
	rename (ZIP_CODE ZCTA PO_NAME) (usps_zip zcta usps_zip_name)
	drop if usps_zip == "96898" & zcta == "No ZCTA"
	keep usps_zip zcta usps_zip_name
	save_data "../temp/usps_master.dta", ///
	    key(usps_zip) replace
	
	clear
    import delimited "../../../raw/crosswalk/geocorr2018.csv", ///
        varnames(1) stringcols(1 2 3 4 5)
	drop metdiv10 mdivname10 afact
	rename (zcta5 placefp) (zcta place)
	merge m:m zcta using "../temp/usps_master.dta", nogen keep(3)

	order zcta usps_zip county place state cbsa10 hus10
	save_data "../output/zcta_county_place_usps_master_xwalk.dta", ///
	    key(zcta usps_zip county place) replace
end


*EXECUTE
main 
