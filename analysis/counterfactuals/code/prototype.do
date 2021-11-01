
egen max_d_ln_mw = max(d_ln_mw) if rural == 0
gen fully_affected = 1 if rural == 0 & d_ln_mw == max_d_ln_mw
gen no_direct_treatment = 1 if rural == 0 & d_ln_mw == 0
gen more_indirect_than_direct = 1 if rural == 0 & d_exp_ln_mw_17 > d_ln_mw
gen house_exp_share_min = 0.25
gen house_exp_share_max = 0.4

** Median urban zipcode
sum d_ln_mw if rural == 0, d
gen tag_median = 1 if d_ln_mw == r(p50)

** Median directly treated urban zipcode
sum d_ln_mw if rural == 0 & d_ln_mw > 0, d
gen tag_dt_median = 1 if d_ln_mw == r(p50)

local exp_ln_mw_on_ln_wagebill = 0.1588706
local exp_ln_mw_on_ln_rents = 0.064464323
local ln_mw_on_ln_rents = -0.030246906

gen perc_incr_rent = exp(`exp_ln_mw_on_ln_rents'*d_exp_ln_mw_17 + `ln_mw_on_ln_rents'*d_ln_mw)-1
gen perc_incr_income = exp(`exp_ln_mw_on_ln_wagebill'*d_exp_ln_mw_17) - 1
gen ratio = perc_incr_rent/perc_incr_income
