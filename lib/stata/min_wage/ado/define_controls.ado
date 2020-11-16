program define_controls, rclass
	foreach ctrl_type in emp estcount avgwwage {
		local var_list "ln_`ctrl_type'_bizserv ln_`ctrl_type'_info ln_`ctrl_type'_manu"
		return local `ctrl_type'_ctrls `var_list'
	}

	local housing_cont   "ln_u1rep_units ln_u1rep_value"
	return local housing_cont "`housing_cont'"
end
