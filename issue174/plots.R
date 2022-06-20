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
  
  dt[, mw_wkp_resid_mw_res_dec := resid(
    feols(mw_wkp ~ -1 | zipcode + mw_res_100groups, dt)
  )]
  dt[, ln_rents_resid_mw_res_dec := resid(
    feols(ln_rents ~ -1 | zipcode + mw_res_100groups, dt)
  )]
  
  for (stub in c("", "_resid_mw_res_dec")) {
    
    bins = 30
    
    ggplot(dt, 
           aes_string(x = paste0("mw_wkp", stub), 
                      y = paste0("ln_rents", stub))) +
      geom_point(alpha = 0.1, color = "grey30") +
      stat_summary_bin(fun = "mean", 
                       breaks = quantile(dt[[paste0("mw_wkp", stub)]], 
                                         probs = 0:bins/bins), 
                       color = "red2",
                       size  = 0.4, alpha = 0.6) +
      theme_bw() -> plt
    
    if (grepl("resid", stub)) {
      plt <- plt + coord_cartesian(ylim = c(-0.2,  0.2), 
                                   xlim = c(-0.15, 0.15)) +
        labs(x = "Workplace MW (residualized)", y = "Log rents (residualized)")
    } else {
      plt <- plt + labs(x = "Workplace MW", y = "Log rents")
    }
    
    ggsave(paste0("plots/", tipo, "_mw_wkp", stub, ".png"),
           height = 5, width = 7)
  }
  
  ## Residence MW
  
  dt[, mw_res_resid_mw_wkp_dec := resid(
    feols(mw_res ~ -1 | zipcode + mw_wkp_100groups, dt)
  )]
  dt[, ln_rents_resid_mw_wkp_dec := resid(
    feols(ln_rents ~ -1 | zipcode + mw_wkp_100groups, dt)
  )]
  
  for (stub in c("", "_resid_mw_wkp_dec")) {
    
    bins = 30
    if (stub == "") dt[, mw_res := mw_res - .001 + .001*runif(.N)]
    
    ggplot(dt, 
           aes_string(x = paste0("mw_res", stub), 
                      y = paste0("ln_rents", stub))) +
      geom_point(alpha = 0.1, color = "grey30") +
      stat_summary_bin(fun = "mean", 
                       breaks = quantile(dt[[paste0("mw_res", stub)]], 
                                         probs = 0:bins/bins), 
                       color = "red2",
                       size  = 0.4, alpha = 0.6) +
      theme_bw() -> plt
    
    if (grepl("resid", stub)) {
      plt <- plt + coord_cartesian(ylim = c(-0.2,  0.2), 
                                   xlim = c(-0.15, 0.15)) +
        labs(x = "Residence MW (residualized)", y = "Log rents (residualized)")
    } else {
      plt <- plt + labs(x = "Residence MW", y = "Log rents")
    }
    
    ggsave(paste0("plots/", tipo, "_mw_res", stub, ".png"),
           height = 5, width = 7)
  }
}

