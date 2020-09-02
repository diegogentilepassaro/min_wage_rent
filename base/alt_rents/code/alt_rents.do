set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main 
	local raw "../../../drive/raw_data/"
	local exports "../output/"
	local temp "../temp"

	build_small_area_fmr, instub(`raw') outstub(`exports')
	

end




program build_small_area_fmr
	syntax, instub(str) outstub(str) 

	forval fmr = 2018(-1)2016 {
		import excel `instub'SFMR/fy`fmr'_safmrs.xlsx, first clear 	
		clean_safmrs, yr(`fmr') instub(`instub')
		tempfile safmrs_`fmr' 
		save "`safmrs_`fmr''", replace 
		di "`fmr'"
		
	}	


	forval fmr = 2015(-1)2012 {
		import excel `instub'SFMR/fy`fmr'_safmrs.xls, first clear 
		clean_safmrs, yr(`fmr') instub(`instub')
		tempfile safmrs_`fmr' 
		save "`safmrs_`fmr''", replace 		
		di "`fmr'"
	}


	import excel `instub'SFMR/fy2019_safmrs_rev.xlsx, first clear 
	clean_safmrs, yr(2019) instub(`instub')

	forval fmr = 2018(-1)2012 {
		append using `safmrs_`fmr'' 
		di "Appending year `fmr'"
	}

	drop if missing(zipcode)
	sort zipcode year

	drop if zipcode<1000 

	duplicates drop

	save_data `outstub'safrm.dta, key(zipcode year) replace

end


program clean_safmrs 
		syntax, yr(int) instub(str)

		if `yr'==2012 {
			tolower State StateName County CountyName CBSA CBSAName ZIP
			rename (state statename county countyname zip) (state_fips state county_fips county zipcode)

			bys state_fips county_fips (county): replace county = county[_N]  
			replace county = "Broomfield" if state_fips=="08" & county_fips=="014"

			bys state_fips cbsa (cbsaname): replace cbsaname = cbsaname[_N]  

			replace county_fips = state_fips + county_fips 			
			replace county = subinstr(county, " County", "", .)
			destring county_fips, replace 
			labmask county_fips, values(county)
			drop county


			destring state_fips, replace 
			drop if state_fips==72
			replace state_fips=1  if state == "Alabama"
			replace state_fips=10 if state == "Delaware"
			replace state_fips=25 if state == "Massachusetts"
			replace state_fips=54 if state == "West Virginia"
			labmask state_fips, values(state)
			drop state


			labmask cbsa, values(cbsaname)
			drop cbsaname	

			gen byte notnumeric = real(zipcode)==.
			drop if notnum==1 
			drop notnum 
			destring zipcode, replace

			duplicates drop	

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}

			collapse_zipcodes, instub(`instub') yr(`yr')

			g year =`yr'
			
			order year zipcode safmr*



		}


		if `yr'== 2013 {
			tolower State StateName County CountyName CBSA CBSAName ZIP
			rename (state statename county countyname zip) (state_fips state county_fips county zipcode)

			bys state_fips county_fips (county): replace county = county[_N]  
			replace county = "Broomfield" if state_fips=="08" & county_fips=="014"

			bys state_fips cbsa (cbsaname): replace cbsaname = cbsaname[_N]  

			replace county_fips = state_fips + county_fips 			
			replace county = subinstr(county, " County", "", .)
			destring county_fips, replace 
			labmask county_fips, values(county)
			drop county


			destring state_fips, replace 
			labmask state_fips, values(state)
			drop if state_fips==72
			drop state



			labmask cbsa, values(cbsaname)
			drop cbsaname
			
			destring zipcode, replace

			duplicates drop	

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}

			duplicates drop zipcode county_fips, force

			collapse_zipcodes, instub(`instub') yr(`yr')
			
			g year =`yr'
			
			order year zipcode safmr*
		}

		if `yr'==2014 {
			tolower State StateName County CountyName CBSA CBSAName ZIP
			rename (state statename county countyname zip) (state_fips state county_fips county zipcode)

			bys state_fips county_fips (county): replace county = county[_N]  
			replace county = "Broomfield" if state_fips=="08" & county_fips=="014"

			bys state_fips cbsa (cbsaname): replace cbsaname = cbsaname[_N]  

			replace county_fips = state_fips + county_fips 			
			replace county = subinstr(county, " County", "", .)
			destring county_fips, replace 
			labmask county_fips, values(county)
			drop county


			destring state_fips, replace 
			labmask state_fips, values(state)
			drop if state_fips==72
			drop state



			labmask cbsa, values(cbsaname)
			drop cbsaname
			
			destring zipcode, replace

			duplicates drop	

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}

			collapse_zipcodes, instub(`instub') yr(`yr')

			g year =`yr'

			order year zipcode safmr*

		}

		if `yr'==2015 {
			rename (state statename county cntyname cbsamet cbnsmcnm) (state_fips state county_fips county cbsa cbsaname)

			bys state_fips county_fips (county): replace county = county[_N]  
			replace county = "Broomfield" if state_fips=="08" & county_fips=="014"

			bys state_fips cbsa (cbsaname): replace cbsaname = cbsaname[_N]  


			replace county_fips = state_fips + county_fips 			
			replace county = subinstr(county, " County", "", .)
			destring county_fips, replace 
			labmask county_fips, values(county)
			drop county

			destring state_fips, replace 
			labmask state_fips, values(state)
			drop if state_fips==72
			drop state


			destring cbsa, replace 
			labmask cbsa, values(cbsaname)
			drop cbsaname

			destring zipcode, replace
			drop if missing(zipcode)

			duplicates drop

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}

			collapse_zipcodes, instub(`instub') yr(`yr')

			g year =`yr'

			order year zipcode safmr*
		}

		if `yr'==2019 | `yr'==2018 {
			tolower *
			rename (hudmetrofairmarketrentarea) (hudname)
			
			rename (*paymentstandard *paymentstandar) (*pct *pct) 

			g hudcode = substr(hudareacode, -6, 6)

			g cbsa = substr(hudareacode, 1, 10)
			replace cbsa = subinstr(cbsa, "METRO", "", .)
			destring cbsa, replace
			
			drop hudareacode

			destring zipcode, replace
			drop if missing(zipcode)
			
			drop hudname hudcode
			duplicates drop

			collapse_zipcodes, instub(`instub') yr(`yr')
			
			g year =`yr'

			drop safmr*pct

			order year zipcode safmr*

		}


		if `yr'== 2017 {
						
			rename (zip_code metro_code metro_name) (zipcode cbsa cbsaname) 

			destring cbsa, replace 
			labmask cbsa, values(cbsaname)
			drop cbsaname 

			destring zipcode, replace

			duplicates drop

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}

			collapse_zipcodes, instub(`instub') yr(`yr') 

			g year =`yr'

			order year zipcode safmr*			

		}

		if `yr'==2016 {
			rename(zip_code metro_code metro_name fips_state_code statename  fips_county_code county_name) (zipcode cbsa cbsaname state_fips state county_fips countyname)

			bys state_fips county_fips (countyname): replace countyname = countyname[_N]  
			replace countyname = "Broomfield" if state_fips=="08" & county_fips=="014"

			bys state_fips cbsa (cbsaname): replace cbsaname = cbsaname[_N]  

			replace county_fips = state_fips + county_fips 			
			replace countyname = subinstr(countyname, " County", "", .)
			destring county_fips, replace 
			labmask county_fips, values(countyname)
			drop countyname

			destring state_fips, replace 
			labmask state_fips, values(state)
			drop if state_fips==72
			drop state



			destring cbsa, replace 
			labmask cbsa, values(cbsaname)
			drop cbsaname


			destring zipcode, replace

			duplicates drop

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}

			collapse_zipcodes, instub(`instub') yr(`yr')
			
			g year =`yr'

			order year zipcode safmr*
		}



end 


program collapse_zipcodes 
	syntax, yr(int) instub(str)
	
	if `yr' <2017 {
		preserve 
		import excel ../../../raw/crosswalk/ZIP_COUNTY_12`yr'.xlsx, clear first
		cap tolower *
		rename (zip county) (zipcode county_fips) 
		destring zipcode, replace 
		destring county_fips, replace
		keep zipcode county_fips res_ratio 
		isid zipcode county_fips
		tempfile countyxwalk_`yr'
		save "`countyxwalk_`yr''", replace
		restore  

		merge 1:1 zipcode county_fips using `countyxwalk_`yr'', nogen assert(1 2 3) keep(1 3)
		keep if res_ratio>.5 | missing(res_ratio)
		duplicates tag cbsa zipcode, g(dup)
		drop if dup>=1 & missing(res_ratio)

		
		isid cbsa zipcode 

		drop res_ratio dup
		keep zipcode cbsa safmr*		
	}


	preserve
	import excel ../../../raw/crosswalk/ZIP_CBSA_12`yr'.xlsx, clear first
	cap tolower *
	rename zip zipcode 
	destring zipcode cbsa, replace
	keep zipcode cbsa res_ratio 
	tempfile xwalk_`yr'
	save "`xwalk_`yr''", replace
	restore 

	merge 1:1 zipcode cbsa using `xwalk_`yr'', nogen assert(1 2 3) keep(1 3) 

	bys zipcode (cbsa): egen totwgt = sum(res_ratio)
	bys zipcode (cbsa): g missing_wgt = 1 - totwgt
	bys zipcode (cbsa): egen temp_mis = count(res_ratio) if missing(res_ratio)
	bys zipcode (cbsa): egen n_mis = sum(res_ratio==.)
	g new_wgt = res_ratio
	bys zipcode (cbsa): replace new_wgt = missing_wgt / n_mis if missing(res_ratio)

	drop res_ratio totwgt missing_wgt n_mis

	collapse (mean) safmr* [w = new_wgt], by(zipcode)
end




main
