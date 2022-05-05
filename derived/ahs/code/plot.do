clear all

program main 

	local instub "../output/"

	import delimited "`instub'sh_renters.csv", clear

	graph bar pr_tenant, over(hh_income_decile) ytitle("Share of renters") ///
		b1title("Household income decile")

	graph export "`instub'/sh_renters.png", as(png) replace

	import delimited "`instub'sh_condo.csv", clear

	graph bar sh_condo, over(hh_income_decile) ytitle("Share of people in condos & cooperatives") ///
		b1title("Household income decile")

	graph export "`instub'/sh_condo.png", as(png) replace

	import delimited "`instub'sh_unit_types.csv", clear

	graph bar sh_unit_type, over(n_units_cat) over(hh_income_decile) ytitle("Share of unit type") ///
		b1title("Household income decile") asyvars stack

	graph export "`instub'/sh_unit_types.png", as(png) replace

	import delimited "`instub'sh_hh_head.csv", clear

	graph bar sh_hh_head_max, over(person_salary_decile) ytitle("Probability of being household head") ///
		b1title("Person income decile")

	graph export "`instub'/sh_hh_head.png", as(png) replace
end

main
