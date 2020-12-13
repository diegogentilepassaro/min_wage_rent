clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main

	local instub_unbal "../../../drive/derived_large/output"
	local outfile      "../output/sumstats_unbalanced.log"

	use "`instub_unbal'/unbal_rent_panel.dta", clear
	gen ln_med_rent_psqft_sfcc = log(medrentpricepsqft_sfcc )
	
	count_mw_and_write_file, outfile(`outfile')

	local instub_baseline "../../first_differences/temp"
	local outfile         "../output/sumstats_baseline.log"

	use "`instub_baseline'/fd_rent_panel.dta", clear
	merge 1:1 zipcode year_month ///
		using "`instub_unbal'/unbal_rent_panel.dta", ///
		keep(3) nogen

	count_mw_and_write_file, outfile(`outfile')
end

program count_mw_and_write_file
	syntax, outfile(str) 

	file open myfile using `outfile', write replace

	tab mw_event if mw_event == 1
	file write myfile "Number of zipcode-level MW events: `r(N)'" _n

	tab mw_event if mw_event == 1 & !missing(D.ln_med_rent_psqft_sfcc)
	file write myfile "Number of zipcode-level MW events with no missing psqft SFCC rents: `r(N)'" _n

	preserve
		collapse (max) state_event, by(statefips year_month)

		tab state_event if state_event == 1
			
		file write myfile "Number of MW events at the state level: `r(N)'" _n
	restore

	foreach event_type in county local {
		preserve
			collapse (max) `event_type'_event, by(countyfips year_month)

			tab `event_type'_event if `event_type'_event == 1
			
			file write myfile "Number of MW events at the `event_type' level: `r(N)'" _n
		restore
	}

	file close myfile
end

main
