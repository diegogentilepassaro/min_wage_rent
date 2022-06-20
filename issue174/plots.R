remove(list=ls())
library(data.table)
library(fixest)
library(ggplot2)

instub = "../drive/analysis_large/non_parametric"

for (tipo in c("cbsa_month", "month")) {
  
  dt <- fread(sprintf("%s/data_any_change_in_%s.csv", instub, tipo))
  
  for (var in names(dt)[grepl("decile|50group", names(dt))]) {
    dt[, c(var) := as.factor(get(var))]
  }
  
  dt <- dt[!is.na(d_ln_rents)
           & !is.na(d_mw_wkp)
           & !is.na(d_mw_res)]
  
  ## Workplace MW
  
  dt[, d_mw_wkp_resid_mw_res_dec := resid(
    feols(d_mw_wkp ~ -1 | mw_res_100groups, dt)
  )]
  dt[, d_ln_rents_resid_mw_res_dec := resid(
    feols(d_ln_rents ~ -1 | mw_res_100groups, dt)
  )]
  
  for (stub in c("", "_resid_mw_res_dec")) {
    
    ggplot(dt[d_mw_wkp > 0], 
           aes_string(x = paste0("d_mw_wkp", stub), 
                      y = paste0("d_ln_rents", stub))) +
      geom_point(alpha = 0.15) +
      geom_smooth(formula = "y ~ x", method = "lm") + 
      stat_summary_bin(fun = "mean", 
                       breaks = quantile(dt[[paste0("d_mw_wkp", stub)]], 
                                         probs = 0:10/10), 
                       color = "red") +
      coord_cartesian(ylim = c(-0.05, 0.05)) +
      theme_bw()
    
    ggsave(paste0("plots/", tipo, "_mw_wkp", stub, ".png"),
           height = 5, width = 7)
  }
  
  ## Workplace MW
  
  dt[, d_mw_res_resid_mw_wkp_dec := resid(
    feols(d_mw_res ~ -1 | mw_wkp_100groups, dt)
  )]
  dt[, d_ln_rents_resid_mw_wkp_dec := resid(
    feols(d_ln_rents ~ -1 | mw_wkp_100groups, dt)
  )]
  
  for (stub in c("", "_resid_mw_wkp_dec")) {
    
    ggplot(dt, 
           aes_string(x = paste0("d_mw_res", stub), 
                      y = paste0("d_ln_rents", stub))) +
      geom_point(alpha = 0.15) +
      geom_smooth(formula = "y ~ x", method = "lm") + 
      stat_summary_bin(fun = "mean", 
                       breaks = quantile(dt[[paste0("d_mw_res", stub)]], 
                                         probs = 0:10/10), 
                       color = "red") +
      coord_cartesian(ylim = c(-0.05, 0.05)) +
      theme_bw()
    
    ggsave(paste0("plots/", tipo, "_mw_res", stub, ".png"),
           height = 5, width = 7)
  }
}
