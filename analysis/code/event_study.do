clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	import delim `instub'data_clean.csv, clear

	create_dep_var

	plot_average, depvar() indepvar()
end

program create_dep_var
	syntax, mw_var(str) time_frame(str)

	bysort zipcode date: gen mw_change = `mw_var' != `mw_var'[_n - 1]
	bysort zipcode date: gen mw_change_date = date if mw_change == 1
	bysort zipcode date: replace mw_change_date = 0 if mw_change == 0


end

main
