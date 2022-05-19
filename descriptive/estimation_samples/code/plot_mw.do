clear all
set more off

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local outstub "../output"

    use zipcode zipcode_num year_month statutory_mw ///
        using "`instub'/zipcode_months.dta", clear
    xtset zipcode_num year_month
    gen pct_ch_MW = 100*(statutory_mw/L.statutory_mw - 1)
    drop if missing(pct_ch_MW)
    
    plot_mw_dist, outstub(`outstub')
end

program plot_mw_dist
    syntax, outstub(str) [width(int 2221) height(int 1615)]

    keep if pct_ch_MW > 0
    twoway (hist pct_ch_MW, color(navy%80) lcolor(white) lw(vthin)),       ///
        xtitle("Minimum wage increase (%)") ytitle("Relative frequency")   ///
        xlabel(, labsize(small)) ylabel(, labsize(small))                  ///
        graphregion(color(white)) bgcolor(white)
    
    graph export `outstub'/pct_ch_mw_dist.png, replace width(`width') height(`height')
    graph export `outstub'/pct_ch_mw_dist.eps, replace

    twoway (hist year_month, color(navy%80) lcolor(white) lw(vthin)),       ///
        xtitle("Monthly date") ytitle("Relative frequency")                 ///
        xlabel(`=mofd(td(01jun2010))'(6)`=mofd(td(01dec2019))',             ///
               labsize(small) angle(45))                                    ///
        graphregion(color(white)) bgcolor(white)
    
    graph export `outstub'/pct_ch_mw_date_dist.png, replace width(`width') height(`height')
    graph export `outstub'/pct_ch_mw_date_dist.eps, replace 
end


main
