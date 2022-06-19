remove(list=ls())
library(data.table)
library(fixest)
library(ggplot2)


dt_month      <- fread("../drive/analysis_large/non_parametric/data_any_change_in_month.csv ")
dt_cbsa_month <- fread("../drive/analysis_large/non_parametric/data_any_change_in_cbsa_month.csv ")

for (var in names(dt_cbsa_month)[grepl("decile", names(dt_cbsa_month))]) {
  dt_cbsa_month[, c(var) := as.factor(get(var))]
}

# CBSA_MONTH

dt_cbsa_month <- dt_cbsa_month[!is.na(d_ln_rents)
                              & !is.na(d_mw_wkp)
                              & !is.na(d_mw_res)]

## Workplace MW

dt_cbsa_month[, d_mw_wkp_resid_mw_res_dec := resid(
  feols(d_mw_wkp ~ - 1 | mw_res_deciles, dt_cbsa_month)
)]
dt_cbsa_month[, d_ln_rents_resid_mw_res_dec := resid(
  feols(d_ln_rents ~ - 1 | mw_res_deciles, dt_cbsa_month)
)]

for (stub in c("", "_resid_mw_res_dec")) {
  
  ggplot(dt_cbsa_month[d_mw_wkp > 0], 
         aes_string(x = paste0("d_mw_wkp", stub), 
                    y = paste0("d_ln_rents", stub))) +
    geom_point(alpha = 0.15) +
    geom_smooth(formula = "y ~ x", method = "lm") + 
    stat_summary_bin(fun = "mean", 
                     breaks = quantile(dt_cbsa_month[[paste0("d_mw_wkp", stub)]], 
                                       probs = 0:10/10), 
                     color = "red") +
    coord_cartesian(ylim = c(-0.05, 0.05))
    theme_bw()
  
  ggsave(paste0("plots/mw_wkp_cbsa_month", stub, ".png"),
         height = 5, width = 7)
}

## Workplace MW

dt_cbsa_month[, d_mw_res_resid_mw_wkp_dec := resid(
  feols(d_mw_res ~ - 1 | mw_wkp_deciles, dt_cbsa_month)
)]
dt_cbsa_month[, d_ln_rents_resid_mw_wkp_dec := resid(
  feols(d_ln_rents ~ - 1 | mw_wkp_deciles, dt_cbsa_month)
)]

for (stub in c("", "_resid_mw_wkp_dec")) {
  
  ggplot(dt_cbsa_month, 
         aes_string(x = paste0("d_mw_res", stub), 
                    y = paste0("d_ln_rents", stub))) +
    geom_point(alpha = 0.15) +
    geom_smooth(formula = "y ~ x", method = "lm") + 
    stat_summary_bin(fun = "mean", 
                     breaks = quantile(dt_cbsa_month[[paste0("d_mw_res", stub)]], 
                                       probs = 0:10/10), 
                     color = "red") +
    coord_cartesian(ylim = c(-0.05, 0.05))
  theme_bw()
  
  ggsave(paste0("plots/mw_res_cbsa_month", stub, ".png"),
         height = 5, width = 7)
}


