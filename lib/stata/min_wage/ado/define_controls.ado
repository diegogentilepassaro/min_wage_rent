program define_controls, rclass
	local economic_controls   ""
	local d_economic_controls ""
	foreach ctrl_type in emp estcount avgwwage {
		local var_list "ln_`ctrl_type'_bizserv ln_`ctrl_type'_info ln_`ctrl_type'_fin"
		return local `ctrl_type'_ctrls `var_list'
		
		local d_var_list "d_ln_`ctrl_type'_bizserv d_ln_`ctrl_type'_info d_ln_`ctrl_type'_fin"
		return local d_`ctrl_type'_ctrls `d_var_list'

		local economic_controls   "`economic_controls' `var_list'"
		local d_economic_controls "`d_economic_controls' `d_var_list'"
	}
	return local economic_controls   "`economic_controls'"
	return local d_economic_controls "`d_economic_controls'"

	/*local housing_cont   "ln_u1rep_units ln_u1rep_value"
	return local housing_cont "`housing_cont'"*/
end
