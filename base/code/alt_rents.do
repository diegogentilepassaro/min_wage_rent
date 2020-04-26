set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado

program main 
	local raw "../../drive/raw_data/"
	local exports "../output/"
	local temp "../temp"

	build_small_area_fmr, instub(`raw') outstub(`exports')
	

end




program build_small_area_fmr
	syntax, instub(str) outstub(str) 

	forval fmr = 2018(-1)2016 {
		import excel `instub'SFMR/fy`fmr'_safmrs.xlsx, first clear 		
		clean_safmrs, yr(`fmr')
		if `fmr'==2017 {
			local cbsalabel: value label cbsa
		}
		tempfile safmrs_`fmr' 
		save "`safmrs_`fmr''", replace 		
	}	



	forval fmr = 2015(-1)2013 {
		import excel `instub'SFMR/fy`fmr'_safmrs.xls, first clear 
		clean_safmrs, yr(`fmr')
		tempfile safmrs_`fmr' 
		save "`safmrs_`fmr''", replace 		
		di "`fmr'"
	}


	// import excel `instub'SFMR/fy2019_safmrs_rev.xlsx, first clear 
	// clean_safmrs, yr(2019)
	// STOP

	import excel `instub'SFMR/fy2019_safmrs_rev.xlsx, first clear 
	clean_safmrs, yr(2019)

	forval fmr = 2018(-1)2013 {
		append using `safmrs_`fmr'' 
	}

	drop if missing(zipcode)
	sort cbsa zipcode year
	label values cbsa `cbsalabel'


	drop if zipcode<1000 

	bys cbsa zipcode (state_fips): replace state_fips = state_fips[1]  
	bys cbsa zipcode (county_fips): replace county_fips = county_fips[1]  

	duplicates drop

	tostring cbsa, g(tempcbsa)
	replace tempcbsa = "M" + tempcbsa if year <2018
	replace hudcode = tempcbsa if year<2018 

	// egen id_temp = group(zipcode hud_safmr_name cbsaname year)
	local outstub "../output/"

	duplicates tag hudcode zipcode year, g(dup)
	sort hudcode zipcode year
	br if dup>0

	save_data `outstub'safrm.dta, key(cbsa zipcode year)


	// save `outstub'safmr_temp.dta, replace 




end


program clean_safmrs 
		syntax, yr(int)

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

			g year =`yr'
			
			order year state_fips county_fips cbsa zipcode safmr*
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
			g year =`yr'

			order year state_fips county_fips cbsa zipcode safmr*

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

			duplicates drop

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}
			g year =`yr'

			order year state_fips county_fips cbsa zipcode safmr*
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
			g year =`yr'

			drop safmr*pct

			order year cbsa zipcode  safmr* hudcode hudname
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
			g year =`yr'

			order year cbsa zipcode safmr*			

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
			g year =`yr'

			order year state_fips county_fips cbsa zipcode safmr*
		}



end 



main
