clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_mw_panels   "../../../drive/derived_large/min_wage_panels"
    local in_zip_master  "../../../drive/base_large/zipcode_master"
    local outstub        "../output"

    use "`in_mw_panels'/zip_statutory_mw.dta", clear
    merge m:1 zipcode using "`in_zip_master'/zipcode_master.dta", nogen ///
        assert(3) keepusing(place_code countyfips cbsa statefips)
    drop if year == 2020
    destring(statefips), gen(statefips_num)
    gen year_month = ym(year, month)
    format year_month %tm
    drop year month

    flag_states_with_mw
    flag_county_or_local_with_mw

    make_autofill_values

    plot_mw_levels, outstub(`outstub')
end

program flag_states_with_mw
    preserve
        collapse (mean) fed_mw state_mw, by(statefips statefips_num year_month)
        keep if !missing(state_mw)
        bysort statefips: egen max_state_mw = max(state_mw)
        keep if (round(max_state_mw, 0.00001) > round(fed_mw, 0.00001))
        save_data "../temp/states_with_mw_and_their_levels_over_time.dta", ///
            replace key(statefips year_month) log(none)
    restore
end

program flag_county_or_local_with_mw
    preserve
        collapse (mean) fed_mw state_mw county_mw, ///
            by(countyfips statefips year_month)
        keep if !missing(county_mw)
        egen max_state_fed = rowmax(state_mw fed_mw)
        keep if (round(county_mw, 0.00001) > round(max_state_fed, 0.00001))
        keep countyfips year_month county_mw
        save_data "../temp/counties_with_mw_and_their_levels_over_time.dta", ///
            replace key(countyfips year_month) log(none)		
    restore 

    preserve
        collapse (mean) fed_mw state_mw county_mw local_mw, ///
            by(place_code countyfips statefips year_month)
        egen max_county_state_fed = rowmax(county_mw state_mw fed_mw)
        keep if !missing(local_mw)
        keep if (round(local_mw, 0.00001) > round(max_county_state_fed, 0.00001))
        duplicates drop place_code year_month, force /* Some places are in more than one county*/
        unique place_code
        keep place_code year_month local_mw
        save_data "../temp/places_with_mw_and_their_levels_over_time.dta", ///
            replace key(place_code year_month) log(none)	
    restore
end

program plot_mw_levels
    syntax, outstub(str) [width(int 2221) height(int 1615)]

    use "../temp/states_with_mw_and_their_levels_over_time.dta", clear
    
    bysort statefips: egen min_year_month = min(year_month)
    gen state_mw_at_min_year_month = state_mw if year_month == min_year_month
    
    xtset statefips_num year_month
    unique statefips
    
    local n_states = r(unique)
    local plotopts ""
    forval i = 1(1)`n_states'{
        local plotopts "`plotopts' plot`i'(lcol(gray))"
    }

    xtline state_mw, overlay                                                 ///
        xtitle("Monthly date") ytitle("Minimum wage level ($)")              ///
        xlabel(`=mofd(td(01jun2010))'(6)`=mofd(td(01dec2019))', labsize(small) angle(45)) ///
        ylabel(7(2)17, labsize(small))                                       ///
        graphregion(color(white)) bgcolor(white) legend(off)                 ///
        addplot(scatter state_mw_at_min_year_month min_year_month,           ///
        msymbol(diamond) mcolor(gray)) `plotopts'
    
    graph export `outstub'/state_mw_levels.png, replace width(`width') height(`height')
    graph export `outstub'/state_mw_levels.eps, replace

    use "../temp/counties_with_mw_and_their_levels_over_time.dta", clear
    append using "../temp/places_with_mw_and_their_levels_over_time.dta"
    gen     jur_code = countyfips
    replace jur_code = place_code if missing(jur_code)
    destring(jur_code), gen(jur_code_num)
    
    gen jur_mw = county_mw
    replace jur_mw = local_mw if missing(jur_mw)

    xtset jur_code_num year_month
    unique jur_code
	
    local n_jur = r(unique)
    local plotopts ""
    forval i = 1(1)`n_jur'{
        local plotopts "`plotopts' plot`i'(lcol(gray))"
    }

    bysort jur_code: egen min_year_month = min(year_month)
    gen jur_mw_at_min_year_month = jur_mw if year_month == min_year_month
    
    xtline jur_mw, overlay                                                   ///
        xtitle("Monthly date") ytitle("Minimum wage level ($)")              ///
        xlabel(`=mofd(td(01jun2010))'(6)`=mofd(td(01dec2019))', labsize(small) angle(45)) ///
        ylabel(7(2)17, labsize(small))                                       ///
        graphregion(color(white)) bgcolor(white) legend(off)                 ///
        addplot(scatter jur_mw_at_min_year_month min_year_month,             ///
        msymbol(diamond) mcolor(gray)) `plotopts'
    
    graph export `outstub'/local_mw_levels.png, replace width(`width') height(`height')
    graph export `outstub'/local_mw_levels.eps, replace
end

program make_autofill_values 

    preserve
        use "../temp/states_with_mw_and_their_levels_over_time.dta", clear
        unique statefips
        local nbr_state_with_mw = r(unique)

        use "../temp/counties_with_mw_and_their_levels_over_time.dta", clear
        unique countyfips
        local nbr_county_with_mw = r(unique)

        use "../temp/places_with_mw_and_their_levels_over_time.dta", clear
        unique place_code
        local nbr_places_with_mw = r(unique)

        local nbr_local_with_mw = `nbr_county_with_mw' + `nbr_places_with_mw'

        cap file close f
        file open   f using "../output/autofill.tex", write replace
        file write  f "\newcommand{\stateBindingMW}{\textnormal{"  %2.0f  (`nbr_state_with_mw')  "}}" _n
        file write  f "\newcommand{\countyBindingMW}{\textnormal{" %2.0f  (`nbr_county_with_mw') "}}" _n
        file write  f "\newcommand{\placeBindingMW}{\textnormal{"  %2.0f  (`nbr_places_with_mw') "}}" _n
        file write  f "\newcommand{\localBindingMW}{\textnormal{"  %2.0f  (`nbr_local_with_mw')  "}}" _n
        file close  f
    restore
end

main
