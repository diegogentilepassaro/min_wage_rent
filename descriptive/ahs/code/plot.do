clear all
set more off

program main 

    make_plot, xvar(hh_income_decile) yvar(pr_tenant) y_title("Share of renters") ///
        x_title("Residualized household income decile") color(navy%80) name(sh_renters)

    make_plot, xvar(hh_income_decile) yvar(sh_condo) y_title("Share of people in condos & cooperatives") ///
        x_title("Residualized household income decile") color(navy%80) name(sh_condo)

    make_plot, xvar(hh_income_decile) yvar(avg_rent) y_title("Residualized average rent ($)") ///
        x_title("Residualized household income decile") color(navy%80) name(avg_rent)

    make_plot, xvar(hh_income_decile) yvar(avg_sqft) y_title("Residualized average square footage") ///
        x_title("Residualized household income decile") color(navy%80) name(avg_sqft)

    make_plot, xvar(hh_income_decile) yvar(avg_rent_psqft) y_title("Residualized average rent per square foot ($)") ///
        x_title("Residualized household income decile") color(navy%80) name(avg_rent_psqft)

    make_plot, xvar(person_salary_decile) yvar(sh_hh_head_max) ///
        y_title("Residualized probability of being household head") ///
        x_title("Residualized individual income decile") color(navy%80) name(sh_hh_head)

    make_stacked_plot, xvar1(n_units_cat) xvar2(hh_income_decile) yvar(sh_unit_type)   ///
        y_title("Share of unit type") x_title("Residualized household income decile")   ///
        name(sh_unit_types)

end

program make_plot
    syntax, xvar(str) yvar(str) y_title(str) ///
        x_title(str) color(str) name(str) [width(int 2221) height(int 1615)]

        import delimited "../output/`name'.csv", clear

        graph bar `yvar', over(`xvar') ytitle(`y_title') ///
        b1title(`x_title') graphregion(color(white)) bgcolor(white) bar(1, fcolor(`color'))

        graph export "../output/`name'.png", replace width(`width') height(`height')
        graph export "../output/`name'.eps", replace

end

program make_stacked_plot
    syntax, xvar1(str) xvar2(str) yvar(str) y_title(str) ///
        x_title(str) name(str) [width(int 2221) height(int 1615)]

        import delimited "../output/`name'.csv", clear

        graph bar `yvar', over(`xvar1') over(`xvar2') ytitle(`y_title') ///
        b1title(`x_title') graphregion(color(white)) bgcolor(white) ///
        asyvars stack

        graph export "../output/`name'.png", replace width(`width') height(`height')
        graph export "../output/`name'.eps", replace

end

main
