clear all
version 15
set more off

program main
    local in_estimates  "../output"

    import delimited `in_estimates'/estimates_het.csv

    keep if model == "het_mw_shares" & at == 0

    qui sum b if var == "mw_res_std_sh_mw_wkrs_statutory"  
    local tilde_gamma_zero = r(mean)
    qui sum se if var == "mw_res_std_sh_mw_wkrs_statutory"
    local tilde_gamma_zero_se = r(mean)

    qui sum b if var == "mw_wkp_std_sh_mw_wkrs_statutory"  
    local tilde_beta_zero = r(mean)
    qui sum se if var == "mw_wkp_std_sh_mw_wkrs_statutory"
    local tilde_beta_zero_se = r(mean)

    qui sum b if var == "sum_res"
    local tilde_gamma_zero_plus_one = r(mean)
    qui sum se if var == "sum_res"
    local tilde_gamma_zero_plus_one_se = r(mean)

    qui sum b if var == "sum_wkp"
    local tilde_beta_zero_plus_one = r(mean)
    qui sum se if var == "sum_wkp"
    local tilde_beta_zero_plus_one_se = r(mean)

    cap file close f
    file open   f using "../output/autofill_heterogeneity.tex", write replace
    file write  f "\newcommand{\TildeGammaZero}{\textnormal{"               %4.3f  (`tilde_gamma_zero')             "}}" _n
    file write  f "\newcommand{\TildeBetaZero}{\textnormal{"                %4.3f  (`tilde_beta_zero')              "}}" _n
    file write  f "\newcommand{\TildeGammaZeroSE}{\textnormal{"             %4.3f  (`tilde_gamma_zero_se')          "}}" _n
    file write  f "\newcommand{\TildeBetaZeroSE}{\textnormal{"              %4.3f  (`tilde_beta_zero_se')           "}}" _n
    file write  f "\newcommand{\TildeGammaZeroPlusGammaOne}{\textnormal{"   %4.3f  (`tilde_gamma_zero_plus_one')    "}}" _n
    file write  f "\newcommand{\TildeGammaZeroPlusGammaOneSE}{\textnormal{" %4.3f  (`tilde_beta_zero_plus_one')     "}}" _n
    file write  f "\newcommand{\TildeBetaZeroPlusGammaOne}{\textnormal{"    %4.3f  (`tilde_gamma_zero_plus_one_se') "}}" _n
    file write  f "\newcommand{\TildeBetaZeroPlusGammaOneSE}{\textnormal{"  %4.3f  (`tilde_beta_zero_plus_one_se')  "}}" _n
    file close  f
end

main
