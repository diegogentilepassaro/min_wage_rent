set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main 
    local raw     "../../../drive/raw_data"
    local outstub "../output"
    local temp    "../temp"

    forval yr = 2012(1)2016 {
        prepare_12_16, raw(`raw') temp(`temp') yr(`yr')
    }

    use `temp'/safmrs_2012.dta, clear
    forval yr = 2013(1)2016 {
        append using `temp'/safmrs_`yr'.dta
    }

    save_data `outstub'/safmr_2012_2016_by_zipcode_county_cbsa.dta, ///
        key(countyfips cbsa zipcode year) replace
    save_data `outstub'/safmr_2012_2016_by_zipcode_county_cbsa.csv, ///
        key(countyfips cbsa zipcode year) log(none) outsheet replace
    
    forval yr = 2017(1)2019 {
        prepare_17_19, raw(`raw') temp(`temp') yr(`yr')
    }
    
    use `temp'/safmrs_2017.dta, clear
    forval yr = 2018(1)2019 {
        append using `temp'/safmrs_`yr'.dta
    }

    save_data `outstub'/safmr_2017_2019_by_zipcode_cbsa.dta, ///
        key(cbsa zipcode year) replace
    save_data `outstub'/safmr_2017_2019_by_zipcode_cbsa.csv, ///
        key(cbsa zipcode year) log(none) outsheet replace
end

program prepare_12_16
    syntax, raw(str) temp(str) yr(int)

    cap import excel `raw'/SFMR/fy`yr'_safmrs.xls, first clear case(lower)
    cap import excel `raw'/SFMR/fy`yr'_safmrs.xlsx, first clear case(lower)
    cap import excel `raw'/SFMR/fy`yr'_safmrs_rev.xlsx, first clear case(lower)

    cap rename zip zipcode
    cap rename zip_code zipcode
    
    cap rename state statefips
	cap rename fips_state_code statefips
	cap rename fips_county_code county
    cap gen countyfips = statefips + county

    cap tostring cbsa, replace
    cap rename cbsamet cbsa
    cap rename metro_code cbsa
    cap rename area_rent_br* safmr*br
    
    gen year = `yr'
    
    drop if missing(zipcode)
    drop if missing(cbsa)
    drop if missing(countyfips)
    
    collapse (mean) safmr0br safmr1br safmr2br safmr3br safmr4br, ///
        by(countyfips cbsa zipcode year)
    
    keep countyfips cbsa zipcode year safmr0br ///
        safmr1br safmr2br safmr3br safmr4br
    save_data `temp'/safmrs_`yr'.dta, key(countyfips cbsa zipcode year) ///
        log(none) replace
end

program prepare_17_19
    syntax, raw(str) temp(str) yr(int)

    cap import excel `raw'/SFMR/fy`yr'_safmrs.xlsx, first clear case(lower)
    cap import excel `raw'/SFMR/fy`yr'_safmrs_rev.xlsx, first clear case(lower)
    
    cap rename zip zipcode
    cap rename zip_code zipcode
        
    cap rename metro_code cbsa
    cap gen cbsa10 = substr(hudareacode, 1, 10)
    cap gen cbsa = subinstr(cbsa10, "METRO", "", .)
	cap drop cbsa10

    cap rename area_rent_br* safmr*br
    
    gen year = `yr'
    
    drop if missing(zipcode)
    drop if missing(cbsa)
        
    collapse (mean) safmr0br safmr1br safmr2br safmr3br safmr4br, ///
        by(cbsa zipcode year)

    keep cbsa zipcode year safmr0br ///
        safmr1br safmr2br safmr3br safmr4br
    save_data `temp'/safmrs_`yr'.dta, key(cbsa zipcode year) ///
        log(none) replace
end

* Execute
main
