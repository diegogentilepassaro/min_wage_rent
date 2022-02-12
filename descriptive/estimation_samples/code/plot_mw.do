clear all
set more off

program main
	local instub "../../../drive/derived_large/estimation_samples"
	local outstub "../output"

    use zipcode zipcode_num year_month actual_mw ///
		using "`instub'/all_zipcode_months.dta", clear
	xtset
	gen pct_ch_MW = 100*(actual_mw/L.actual_mw - 1)
	drop if missing(pct_ch_MW)
	
	plot_mw_dist, outstub(`outstub')
end

program plot_mw_dist
	syntax, outstub(str)

	twoway (hist pct_ch_MW if pct_ch_MW>0, color(navy%80) lcolor(white) lw(vthin)), ///
			xtitle("Minimum wage changes (%)") ytitle("Relative frequency") ///
			xlabel(, labsize(small)) ylabel(, labsize(small)) ///
			graphregion(color(white)) bgcolor(white)
	graph export `outstub'/pct_ch_mw_dist.png, replace 
	graph export `outstub'/pct_ch_mw_dist.eps, replace

	keep if pct_ch_MW>0
	twoway (hist year_month, color(navy%80) lcolor(white) lw(vthin)), ///
			xtitle("Monthly date") ytitle("Relative frequency") ///
			xlabel(#20, labsize(small) angle(45)) ///
			graphregion(color(white)) bgcolor(white)
	graph export `outstub'/pct_ch_mw_date_dist.png, replace 
	graph export `outstub'/pct_ch_mw_date_dist.eps, replace 
end


main
