program define_controls, rclass
	local economic_controls ""
	foreach ctrl_type in emp estcount avgwwage {
		local var_list "ln_`ctrl_type'_bizserv ln_`ctrl_type'_info ln_`ctrl_type'_fin"
		return local `ctrl_type'_ctrls `var_list'
		
		local economic_controls "`economic_controls' `var_list'"
	}
	return local economic_controls "`economic_controls'"

	/*local housing_cont   "ln_u1rep_units ln_u1rep_value"
	return local housing_cont "`housing_cont'"*/
end
