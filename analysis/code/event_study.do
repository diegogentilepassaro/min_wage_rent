clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	use `instub'data_clean.csv, clear

	plot_average, depvar() indepvar()
end

main
