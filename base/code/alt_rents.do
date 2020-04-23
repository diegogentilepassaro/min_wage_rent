set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado

program main 
	local raw "../../drive/raw_data/"
	local exports "../output"
	local temp "../temp"

	build_small_area_fmr, instub(`raw') outstub(`exports')
	

end




program build_small_area_fmr
	syntax, instub(str) outstub(str) 

	forval fmr = 2018(-1)2016 {
		import excel `instub'SFMR/fy`fmr'_safmrs.xlsx, first clear 
		
		clean_safmrs, yr(`fmr')
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
	


	import excel `instub'SFMR/fy2019_safmrs_rev.xlsx, first clear 
	clean_safmrs, yr(2019)

	forval fmr = 2018(-1)2013 {
		append using `safmrs_`fmr'' 
	}

	drop if missing(zipcode)
	sort zipcode hud_safmr_name cbsaname year 
	egen id_temp = group(zipcode hud_safmr_name cbsaname year)

	save `outstub'safmr_temp.dta, replace 




end


program clean_safmrs 
		syntax, yr(int)

		if `yr'== 2013 {
			tolower State StateName County CountyName CBSA CBSAName ZIP
			rename (state statename county countyname zip) (state_fips state county_fips county zipcode)
			destring state_fips, replace 
			labmask state_fips, values(state)
			drop if state_fips==72
			drop state
			replace county = subinstr(county, " County", "", .)
			destring county_fips, replace 



			destring cbsa, replace 

			destring zipcode, replace

			duplicates drop	

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}

			g year =`yr'
		}

		if `yr'==2014 {
			tolower State StateName County CountyName CBSA CBSAName ZIP
			rename (state statename county countyname zip) (state_fips state county_fips county zipcode)
			destring state_fips, replace 
			labmask state_fips, values(state)
			drop if state_fips==72
			drop state

			replace county = subinstr(county, " County", "", .)
			destring county_fips, replace 


			destring cbsa, replace 

			destring zipcode, replace

			duplicates drop

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}
			g year =`yr'

		}

		if `yr'==2015 {
			rename (state statename county cntyname cbsamet cbnsmcnm) (state_fips state county_fips county cbsa cbsaname)
			
			destring state_fips, replace 
			labmask state_fips, values(state)
			drop if state_fips==72
			drop state

			replace county = subinstr(county, " County", "", .)
			destring county_fips, replace 


			destring cbsa, replace 

			destring zipcode, replace

			duplicates drop

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}
			g year =`yr'

		}

		if `yr'==2019 | `yr'==2018 {
			tolower *
			rename (hudmetrofairmarketrentarea) (hud_safmr_name)
			
			rename (*paymentstandard *paymentstandar) (*pct *pct) 

			destring zipcode, replace
			g year =`yr'

		}


		if `yr'== 2017 {
						
			rename (zip_code metro_code metro_name) (zipcode cbsa cbsaname) 

			destring cbsa, replace 

			destring zipcode, replace

			duplicates drop

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}
			g year =`yr'

		}

		if `yr'==2016 {
			rename(zip_code metro_code metro_name fips_state_code statename  fips_county_code county_name) (zipcode cbsa cbsaname state_fips state county_fips countyname)

			destring county_fips, replace 

			destring state_fips, replace 
			labmask state_fips, values(state)
			drop if state_fips==72
			drop state



			destring cbsa, replace 

			destring zipcode, replace

			duplicates drop

			rename area_rent_* safmrs*
			forval x = 0(1)4 {
				rename safmrsbr`x' safmr`x'br
			}
			g year =`yr'

		}



end 



main
